import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hugeicons/hugeicons.dart';

import '../../providers/chat_provider.dart';
import '../../providers/voice_input_provider.dart';
import '../../providers/model_provider.dart';
import '../../providers/group_chat_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/suggestion_chip.dart';

import '../widgets/message_bubble.dart';
import '../widgets/chat_info_panel.dart';
import '../widgets/attachment_bottom_sheet.dart';
import '../widgets/chat_sidebar.dart';
import '../widgets/group_chat_dialogs.dart';
import '../widgets/group_chat_modal.dart';
import '../../../../core/components/custom_modal.dart';
import '../widgets/group_options_menu.dart';
import '../widgets/expandable_input_box.dart';
import '../widgets/fetch_indicator.dart';
import '../widgets/shimmer_loading.dart';

import '../widgets/research_progress_capsule.dart'; // [NEW]
import '../widgets/research_activity_panel.dart';   // [NEW]
import 'temporary_chat_info_screen.dart';
import 'share_link_screen.dart';

/// Chat screen - Main chat interface with ChatGPT-style design
class ChatScreen extends ConsumerStatefulWidget {
  final String? chatId;
  
  const ChatScreen({super.key, this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showInfoPanel = false;
  bool _isAtBottom = true;
  bool _showScrollButton = false; // ChatGPT-style scroll button visibility
  Timer? _scrollButtonDebounce; // Debounce timer for hiding button
  bool _isDrawerOpen = false;
  String? _selectedSuggestionCategory = 'All';
  
  // Edit State
  String? _editingMessageId;
  String? _editingContent;
  
  @override
  void initState() {
    super.initState();
    // Verify auth token and user
    WidgetsBinding.instance.addPostFrameCallback((_) {
       // Optimize: Load sessions and messages in parallel
       final sessionFuture = ref.read(chatProvider.notifier).loadSessions();
       final messageFuture = widget.chatId != null 
           ? ref.read(chatProvider.notifier).loadMessages(widget.chatId!)
           : Future.value();
           
       Future.wait([sessionFuture, messageFuture]);
    });
    
    _scrollController.addListener(_onScroll);
    _messageController.addListener(() {
      // Clear suggestion category when input is emptied
      if (_messageController.text.isEmpty && _selectedSuggestionCategory != null) {
        _selectedSuggestionCategory = null;
      }
      setState(() {});
    });
  }

  bool _isVoiceConverted = false;
  String _textBeforeVoice = ''; // For appending voice text

  void _onScroll() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final maxScroll = position.maxScrollExtent;
      
      // If content is not scrollable (fits on screen), consider us at bottom
      if (maxScroll <= 0) {
        if (!_isAtBottom) setState(() => _isAtBottom = true);
        if (_showScrollButton) setState(() => _showScrollButton = false);
        _scrollButtonDebounce?.cancel();
        return;
      }
      
      // Check if we are near bottom (within 100px)
      final isAtBottom = position.pixels >= maxScroll - 100;
      
      if (isAtBottom != _isAtBottom) {
        setState(() => _isAtBottom = isAtBottom);
      }
      
      // Cancel previous debounce timer
      _scrollButtonDebounce?.cancel();
      
      if (!isAtBottom) {
        // Not at bottom - show button while scrolling
        if (!_showScrollButton) {
          setState(() => _showScrollButton = true);
        }
        // Hide after 1s of no scrolling (ChatGPT style)
        _scrollButtonDebounce = Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() => _showScrollButton = false);
          }
        });
      } else {
        // At bottom - hide immediately
        if (_showScrollButton) {
          setState(() => _showScrollButton = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _scrollButtonDebounce?.cancel();
    super.dispose();
  }

  void _sendMessage([String? text]) {
    final content = text ?? _messageController.text.trim();
    if (content.isEmpty) return;
    
    setState(() => _isVoiceConverted = false);
    ref.read(chatProvider.notifier).sendMessage(content);
    _messageController.clear();
    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleVoiceTap() async {
    // print('[UI] _handleVoiceTap triggered');
    final voiceNotifier = ref.read(voiceInputProvider.notifier);
    final currentState = ref.read(voiceInputProvider).state;
    // print('[UI] Current Voice State: $currentState');
    
    if (currentState == VoiceInputState.idle) {
      setState(() {
        _isVoiceConverted = false;
        _textBeforeVoice = _messageController.text; // Capture existing text
      });
      // print('[UI] Starting recording... appending to: $_textBeforeVoice');
      
      // DO NOT CLEAR controller for append mode
      // _messageController.clear();
      
      await voiceNotifier.startRecording();
    } else if (currentState == VoiceInputState.listening) {
      // Manual stop -> Handle text appending
      _handleVoiceStopAndSend();
    } else {
       // print('[UI] Unhandled state tap: $currentState');
    }
  }

  void _handleVoiceStopAndSend() async {
    final voiceNotifier = ref.read(voiceInputProvider.notifier);
    final currentVoiceState = ref.read(voiceInputProvider);
    
    // Stop recording if active
    if (currentVoiceState.state == VoiceInputState.listening ||
        currentVoiceState.state == VoiceInputState.thinking ||
        currentVoiceState.state == VoiceInputState.finalizing) {
      
      // stopRecording() sends commit and waits for final text
      final finalText = await voiceNotifier.stopRecording();
      
      // Insert the final transcribed text into the input field
      if (finalText != null && finalText.isNotEmpty) {
        // FIXED: Append to existing text rather than replacing
        final prefix = _textBeforeVoice;
        final separator = (prefix.isNotEmpty && !prefix.endsWith(' ') && finalText.isNotEmpty) ? ' ' : '';
        final combinedText = '$prefix$separator$finalText';
        
        _messageController.text = combinedText;
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: _messageController.text.length),
        );
        
        // Auto-send like ChatGPT (DISABLED to allow Redo/Review)
        // _sendMessage(); 
        
        setState(() {
          _isVoiceConverted = true; // Set to true to show Redo button
        });
      }
      // If no text detected, the UI will show "No speech detected" inside the floating card
    }
  }

  void _showAttachmentOptions() {
    showAttachmentSheet(
      context,
      onCamera: () {
        // TODO: Implement camera capture
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera coming soon'), behavior: SnackBarBehavior.floating),
        );
      },
      onPhotos: () {
        // TODO: Implement photo picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo picker coming soon'), behavior: SnackBarBehavior.floating),
        );
      },
      onFiles: () {
        // TODO: Implement file picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File picker coming soon'), behavior: SnackBarBehavior.floating),
        );
      },
      onCreateImage: () {
        _messageController.text = 'Create an image of ';
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: _messageController.text.length),
        );
        _focusNode.requestFocus();
      },
      onDeepResearch: () {
        ref.read(chatProvider.notifier).setResearchMode('deep_research');
        _messageController.text = '';
        _focusNode.requestFocus();
        // Snackbar removed - research mode shown via pill indicator
      },
      onShoppingResearch: () {
        ref.read(chatProvider.notifier).setResearchMode('shopping');
        _messageController.text = '';
        _focusNode.requestFocus();
      },
      onWebSearch: () {
        ref.read(chatProvider.notifier).setResearchMode('web_search');
        _messageController.text = '';
        _focusNode.requestFocus();
      },
    );
  }

  Future<void> _handleStartGroupChat() async {
    final user = ref.read(currentUserProvider);
    final userName = user?.username ?? 'User';
    final userInitials = userName.isNotEmpty 
        ? userName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'U';
    
    GroupChatModal.show(
      context,
      userName: userName,
      userInitials: userInitials,
      onStartGroupChat: () async {
        final chatState = ref.read(chatProvider);
        final title = chatState.currentSessionId != null 
            ? 'Group Chat' 
            : 'New Group Chat';
        
        final group = await ref.read(groupChatProvider.notifier).startGroupChat(
          title: title,
          ownerId: user?.id ?? 'anonymous',
        );
        
        // Show the group link dialog
        if (mounted && group.link != null) {
          showGroupLinkDialog(context, group.link!);
        }
      },
    );
  }

  void _handleShare() {
    final messages = ref.read(currentMessagesProvider);
    if (messages.isEmpty) return;
    
    final chatState = ref.read(chatProvider);
    final sessions = ref.read(chatSessionsProvider);
    final currentSession = sessions.where((s) => s.id == chatState.currentSessionId).firstOrNull;
    final chatTitle = currentSession?.title ?? 'Chat';
    
    // Navigate to full share link screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ShareLinkScreen(
          chatId: chatState.currentSessionId,
          chatTitle: chatTitle,
          messages: messages,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for chat errors (e.g. 404 Not Found)
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (next.error == 'Chat not found' && widget.chatId != null) {
        // Redirect to new chat if current ID is invalid
        context.go('/chat');
      }
    });

    final messages = ref.watch(currentMessagesProvider);
    final isStreaming = ref.watch(isStreamingProvider);
    final voiceState = ref.watch(voiceInputProvider).state;
    final selectedModel = ref.watch(selectedModelProvider);
    final currentGroup = ref.watch(currentGroupProvider);
    final chatState = ref.watch(chatProvider);
    final isLoadingHistory = chatState.isLoading && messages.isEmpty;
    
    ref.listen(currentMessagesProvider, (previous, next) {
      if (_isAtBottom && next.length > (previous?.length ?? 0)) {
        _scrollToBottom();
      }
    });
    
    ref.listen(voiceInputProvider, (previous, current) {
      // 1. Handle Partial & Final Text Updates - Use accumulatedText for proper append
      if (current.accumulatedText.isNotEmpty) {
        // Use accumulated text from voice provider (includes all previous sessions)
        final combinedText = current.accumulatedText;
        
        if (_messageController.text != combinedText) {
          _messageController.text = combinedText;
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageController.text.length),
          );
        }
      }

      // 2. Handle Auto-Submit (Final State) - DISABLED per Master Prompt
      // "User must explicitly press Send."
      // We only update the text field (handled above) and reset state if needed.
      
      // Case A: Manual Stop (Transitions to transcribing)
      if (current.state == VoiceInputState.transcribing && 
          previous?.state != VoiceInputState.transcribing) {
           // Do nothing, wait for final text in _handleVoiceStopAndSend or listener updates
      }
      
      // Case B: Auto-Close (Server detected silence -> IDLE)
      if (current.state == VoiceInputState.idle && 
          (previous?.state == VoiceInputState.listening || 
           previous?.state == VoiceInputState.thinking || 
           previous?.state == VoiceInputState.transcribing ||
           previous?.state == VoiceInputState.finalizing)) {
            // Ensure final text is captured using accumulated text
            if (current.accumulatedText.isNotEmpty) {
               if (_messageController.text != current.accumulatedText) {
                 _messageController.text = current.accumulatedText;
               }
            }
      }
    });

    // Listen for chat errors (e.g. Quota exceeded)
    ref.listen(chatProvider, (previous, next) {
      // Ignore 'Chat not found' as it's handled by other listener (redirect)
      if (next.error != null && 
          next.error != previous?.error && 
          next.error != 'Chat not found') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!.contains('429') 
                ? 'Usage limit reached. Please wait a minute.' 
                : next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? AppColors.backgroundDark 
          : AppColors.backgroundLight,
      onDrawerChanged: (isOpen) => setState(() => _isDrawerOpen = isOpen),
      drawer: const ChatSidebar(),
      endDrawer: _showInfoPanel ? null : _buildInfoDrawer(context, selectedModel),
      body: SafeArea(
        child: Stack(
          children: [
            // Gray overlay when drawer is open
            if (_isDrawerOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                child: Stack(
                    children: [
                      // Layer 1: Content (Messages) - Fills screen, scrolls behind navbar/input
                      Positioned.fill(
                        child: isLoadingHistory
                            // ChatGPT-style shimmer skeleton for chat loading
                            ? Padding(
                                padding: const EdgeInsets.only(top: 100, bottom: 120),
                                child: _buildChatLoadingSkeleton(),
                              )
                            : messages.isEmpty 
                            ? Padding(
                                padding: const EdgeInsets.only(top: 80, bottom: 100), // Avoid navbar/input
                                child: _buildEmptyState(context),
                              )
                            : _buildMessageList(
                                context, 
                                messages,
                                contentPadding: const EdgeInsets.only(top: 100, bottom: 120), // Top: Navbar + Indicator space, Bottom: Input
                              ),
                      ),
                      
                      // Layer 1.5: Activity Indicators & Banners (Fixed Position below Navbar)
                      if (currentGroup != null && messages.isNotEmpty)
                        Positioned(
                          top: 70, // Below navbar
                          left: 0, 
                          right: 0,
                          child: _buildGroupInviteBanner(currentGroup),
                        ),
                        
                       // Suggestion Hints (Overlay near bottom input)
                       // Hide when voice recording is active
                       if (_selectedSuggestionCategory != null && 
                           messages.isEmpty && 
                           voiceState == VoiceInputState.idle)
                         Positioned(
                           bottom: 90,
                           left: 16,
                           right: 16,
                           child: SuggestionHints(
                              selectedCategory: _selectedSuggestionCategory,
                              onHintTap: (hint) {
                                final prefix = SuggestionData.getPromptPrefix(_selectedSuggestionCategory!);
                                _messageController.text = '$prefix $hint';
                                _messageController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _messageController.text.length),
                                );
                              },
                            ),
                          ),

                      // Top Fog (Gradient Fade) - Matches background to fade scrolling content
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 160, // Increased height for smoother transition
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Theme.of(context).brightness == Brightness.dark 
                                      ? AppColors.backgroundDark 
                                      : AppColors.backgroundLight,
                                  (Theme.of(context).brightness == Brightness.dark 
                                      ? AppColors.backgroundDark 
                                      : AppColors.backgroundLight).withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Layer 2: Glass Navbar (Fixed Top) - Matching input box style
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildCustomAppBar(context, selectedModel, currentGroup),
                                    
                                    // Fetch Indicator embedded in Navbar area or just below?
                                    // ChatGPT puts it floating. We'll stick it here for now or overlay it.
                                    // Actually, we should check if it's cleaner to separate.
                                  ],
                                ),
                      ),
                      // Layer 2.5: Fetch Indicator (Floating below navbar)
                      Positioned(
                        top: 60, 
                        left: 0, 
                        right: 0,
                        child: Consumer(
                          builder: (context, ref, _) {
                            final chatState = ref.watch(chatProvider);
                            return FetchIndicator(
                              isThinking: chatState.isThinking,
                              isSearching: chatState.isSearching,
                              isScraping: chatState.isScraping,
                              scrapingSources: chatState.scrapingSources,
                            );
                          },
                        ),
                      ),

                      // Bottom Fog (Gradient Fade) - Fades content before it hits input box
                      Positioned(
                        bottom: 0, // Anchored to bottom, behind input box
                        left: 0,
                        right: 0,
                        height: 140, 
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Theme.of(context).brightness == Brightness.dark 
                                      ? AppColors.backgroundDark 
                                      : AppColors.backgroundLight,
                                  (Theme.of(context).brightness == Brightness.dark 
                                      ? AppColors.backgroundDark 
                                      : AppColors.backgroundLight).withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Layer 2.9: Scroll to Bottom Button (ChatGPT style)
                      if (_showScrollButton)
                        Positioned(
                          bottom: 90, // Above input box
                          right: 0,
                          left: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: _scrollToBottom,
                              child: AnimatedOpacity(
                                opacity: _showScrollButton ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF2F2F2F)
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.black.withValues(alpha: 0.1),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 24,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : Colors.black.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Layer 3: Floating Input Area (Fixed Bottom)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _editingMessageId != null
                            ? _buildEditPanel(context)
                            : _buildInputArea(context, isStreaming, voiceState),
                      ),
                    ],
                  ),
                ),
                
                // Side panel (desktop)
                if (_showInfoPanel && MediaQuery.of(context).size.width > 800)
                  ChatInfoPanel(
                    chatTitle: widget.chatId != null ? 'Chat' : 'New Chat',
                    modelName: selectedModel,
                    memoryEnabled: true,
                    onClearChat: () {
                      ref.read(chatProvider.notifier).clearCurrentSession();
                      setState(() => _showInfoPanel = false);
                    },
                    onNewChat: () {
                      ref.read(chatProvider.notifier).clearCurrentSession();
                      context.go('/chat');
                      setState(() => _showInfoPanel = false);
                    },
                    onClose: () => setState(() => _showInfoPanel = false),
                    onTitleChanged: (title) {},
                    onMemoryToggled: (enabled) {},
                  ).animate().slideX(begin: 1, end: 0, duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            
            // Voice recording overlay removed (using inline input box instead)
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInviteBanner(GroupChat group) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            'Your personal Aris memory is never used in group chats.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => showGroupLinkDialog(context, group.link ?? ''),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              side: const BorderSide(color: AppColors.inputBorder),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Invite with link'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, String selectedModel, GroupChat? currentGroup) {
    final messages = ref.watch(currentMessagesProvider);
    final isEmptyChat = messages.isEmpty;
    final isGroupChat = currentGroup != null;
    final chatState = ref.watch(chatProvider);
    
    // Get chat title for active state
    String chatTitle = 'Aris';
    if (!isEmptyChat && chatState.currentSessionId != null) {
      final sessions = ref.watch(chatSessionsProvider);
      final currentSession = sessions.where((s) => s.id == chatState.currentSessionId).firstOrNull;
      chatTitle = currentSession?.title ?? 'Chat';
    } else if (isGroupChat) {
      chatTitle = currentGroup.title;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Left: Menu icon (sidebar toggle)
          Builder(
            builder: (ctx) => _buildNavbarIconButton(
              icon: HugeIcons.strokeRoundedMenuTwoLine,
              onTap: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Center: Model/Title selector pill
          GestureDetector(
            onTap: () {
              if (isGroupChat) {
                _showGroupTitleMenu(currentGroup);
              } else if (!isEmptyChat) {
                // Active chat - show model selector
                _showModelSelectorDialog(context);
              } else {
                _showModelSelectorDialog(context);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  // Match vertical height to approx 44px
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF1A1A1A).withValues(alpha: 0.95) 
                        : const Color(0xFFFFFFFF).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withValues(alpha: 0.08) 
                          : Colors.black.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                  child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.35),
                    child: Text(
                      isGroupChat ? chatTitle : 'Aris',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isGroupChat) ...[
                    const SizedBox(width: 4),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowDown01,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ],
                ],
              ),
            ),
          ),
            ),
          ),
          
          const Spacer(),
          
          // Right: Action group in rounded pill
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: isEmptyChat
                ? _buildEmptyChatActions()
                : _buildActiveChatActions(chatTitle),
          ),
        ],
      ),
    );
  }
  
  /// Build navbar icon button with consistent styling
  Widget _buildNavbarIconButton({
    required dynamic icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            // Match right side pill height (36 + 4+4 = 44)
            height: 44, 
            width: 44,
            padding: const EdgeInsets.all(4), 
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF1A1A1A).withValues(alpha: 0.95) 
                  : const Color(0xFFFFFFFF).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24), // Match right side radius
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withValues(alpha: 0.08) 
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Center(
          child: HugeIcon(
            icon: icon,
            size: 20,
            color: iconColor ?? AppColors.textPrimary,
          ),
        ),
      ),
      ),
      ),
    );
  }
  
  /// STATE A: Empty chat action icons (Group invite + Temp chat)
  Widget _buildEmptyChatActions() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          key: const ValueKey('empty_actions'),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF1A1A1A).withValues(alpha: 0.95) 
                : const Color(0xFFFFFFFF).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withValues(alpha: 0.08) 
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Group invite icon
          _buildPillIconButton(
            icon: HugeIcons.strokeRoundedUserAdd02,
            onTap: _handleStartGroupChat,
          ),
          const SizedBox(width: 4),
          // Temp chat icon - shows info screen first
          _buildPillIconButton(
            icon: HugeIcons.strokeRoundedClock01,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TemporaryChatInfoScreen(
                    onContinue: () {
                      ref.read(chatProvider.notifier).clearCurrentSession();
                      ref.read(groupChatProvider.notifier).setCurrentGroup(null);
                      // TODO: Set temporary chat mode flag
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _focusNode.requestFocus();
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      ),
      ),
    );
  }
  
  /// STATE B: Active chat action icons (Group invite + New chat + More options)
  Widget _buildActiveChatActions(String chatTitle) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          key: const ValueKey('active_actions'),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF1A1A1A).withValues(alpha: 0.95) 
                : const Color(0xFFFFFFFF).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withValues(alpha: 0.08) 
                  : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Group invite icon
          _buildPillIconButton(
            icon: HugeIcons.strokeRoundedUserAdd02,
            onTap: _handleStartGroupChat,
          ),
          const SizedBox(width: 4),
          // New chat icon
          _buildPillIconButton(
            icon: HugeIcons.strokeRoundedPencilEdit02,
            onTap: () {
              ref.read(chatProvider.notifier).clearCurrentSession();
              ref.read(groupChatProvider.notifier).setCurrentGroup(null);
              context.go('/chat');
              // Auto-focus input after new chat
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _focusNode.requestFocus();
              });
            },
          ),
          const SizedBox(width: 4),
          // More options icon
          _buildPillIconButton(
            icon: HugeIcons.strokeRoundedMoreVertical,
            onTap: () => _showChatOptionsBottomSheet(chatTitle),
          ),
        ],
      ),
      ),
      ),
    );
  }
  
  /// Icon button inside the rounded pill group
  Widget _buildPillIconButton({
    required dynamic icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: HugeIcon(
            icon: icon,
            size: 20,
            color: iconColor ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _showChatOptionsBottomSheet(String chatTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                   Expanded(
                    child: Text(
                      'Chat options',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.dividerDark, height: 1),
            ListTile(
              leading: HugeIcon(icon: HugeIcons.strokeRoundedShare01, color: AppColors.textPrimary, size: 24),
              title: const Text('Share', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _handleShare();
              },
            ),
            ListTile(
              leading: HugeIcon(icon: HugeIcons.strokeRoundedEdit02, color: AppColors.textPrimary, size: 24),
              title: const Text('Rename', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _handleMenuAction('rename');
              },
            ),
            Consumer(
              builder: (context, ref, _) {
                
                return Column(
                  children: [
                     const Divider(color: AppColors.dividerDark, height: 1),
                    
                    // Clear Chat
                    ListTile(
                      leading: HugeIcon(
                        icon: HugeIcons.strokeRoundedClean,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                      title: const Text('Clear chat', style: TextStyle(color: AppColors.textPrimary)),
                      onTap: () {
                        Navigator.pop(context);
                         CustomModal.show(
                          context,
                          title: 'Clear this chat?',
                          content: 'This will remove all messages in this conversation.',
                          confirmLabel: 'Clear',
                          isDestructive: true,
                          onConfirm: () {
                             ref.read(chatProvider.notifier).clearCurrentSession();
                          },
                        );
                      },
                    ),

                    // Delete Chat
                    ListTile(
                      leading: HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        color: AppColors.danger,
                        size: 24,
                      ),
                      title: const Text('Delete chat', style: TextStyle(color: AppColors.danger)),
                      onTap: () {
                        Navigator.pop(context);
                        CustomModal.show(
                          context,
                          title: 'Delete this chat?',
                          content: 'This cannot be undone.',
                          confirmLabel: 'Delete',
                          isDestructive: true,
                          onConfirm: () {
                             final chatId = ref.read(chatProvider).currentSessionId;
                             if (chatId != null) {
                               ref.read(chatProvider.notifier).deleteSession(chatId);
                               context.go('/chat');
                             }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined, color: AppColors.textPrimary),
              title: const Text('Customize Aris', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings/personalization');
              },
            ),
            const Divider(color: AppColors.dividerDark, height: 1),
            ListTile(
              leading: HugeIcon(icon: HugeIcons.strokeRoundedDelete02, color: AppColors.error, size: 24),
              title: const Text('Delete chat', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }
  

  
  /// Handle menu action
  Future<void> _handleMenuAction(String action) async {
    final chatState = ref.read(chatProvider);
    final sessionId = chatState.currentSessionId;
    
    switch (action) {
      case 'share':
        _handleShare();
        break;
      case 'rename':
        if (sessionId != null) {
          final sessions = ref.read(chatSessionsProvider);
          final currentSession = sessions.where((s) => s.id == sessionId).firstOrNull;
          final currentTitle = currentSession?.title ?? 'Chat';
          final newTitle = await showRenameGroupDialog(context, currentTitle);
          if (newTitle != null && newTitle.isNotEmpty) {
            ref.read(chatProvider.notifier).renameSession(sessionId, newTitle);
          }
        }
        break;
    }
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation() {
    CustomModal.show(
      context,
      title: 'Delete chat?',
      content: 'This will permanently delete this conversation.',
      confirmLabel: 'Delete',
      isDestructive: true,
      onConfirm: () {
        final sessionId = ref.read(chatProvider).currentSessionId;
        if (sessionId != null) {
          ref.read(chatProvider.notifier).deleteSession(sessionId);
          context.go('/chat');
        }
      },
    );
  }



  void _showGroupTitleMenu(GroupChat group) {
    if (!mounted) return;
    
    // Find the position of the title/pill to anchor the menu
    // We can assume the top center area or use a fixed position if we can't get the specific widget context easily here
    // ChatGPT usually anchors to the top bar title
    // For simplicity, we'll anchor to the top-center-leftish area relative to screen
    final mediaQuery = MediaQuery.of(context);
    final anchorOffset = Offset(mediaQuery.size.width / 2, mediaQuery.padding.top + 50);

    final user = ref.read(currentUserProvider);
    final isOwner = group.ownerId == (user?.id ?? '');

    GroupOptionsMenu.show(
      context,
      position: anchorOffset,
      groupTitle: group.title,
      onViewMembers: () {
        // TODO: Show members dialog
      },
      onAddMembers: () {
        // TODO: Show add members dialog
      },
      onManageLink: () {
        showGroupLinkDialog(context, group.link ?? '');
      },
      onRename: () async {
        final newTitle = await showRenameGroupDialog(context, group.title);
        if (newTitle != null && newTitle.isNotEmpty) {
          ref.read(groupChatProvider.notifier).renameGroup(group.id, newTitle);
        }
      },
      onCustomize: () {
        // Navigate to customization
      },
      onMute: () {
        // Toggle mute
      },
      onReport: () {
        // Report dialog removed
      },
      onLeave: () {
        // Confirm leave
      },
      onDelete: isOwner ? () {
        ref.read(groupChatProvider.notifier).deleteGroup(group.id);
      } : null,
    );
  }

  void _showModelSelectorDialog(BuildContext context) {
    final models = ref.read(availableModelsProvider);
    final currentModel = ref.read(selectedModelProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Model',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (models.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No models available',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else
            ...models.map((model) => ListTile(
              leading: Icon(
                Icons.auto_awesome,
                color: model.name == currentModel 
                    ? AppColors.primary 
                    : AppColors.textMuted,
              ),
              title: Text(
                model.name,
                style: TextStyle(
                  color: model.name == currentModel 
                      ? AppColors.primary 
                      : AppColors.textDark,
                  fontWeight: model.name == currentModel 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                ),
              ),
              trailing: model.name == currentModel 
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                ref.read(modelProvider.notifier).selectModel(model.name);
                Navigator.pop(context);
              },
            )),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildInfoDrawer(BuildContext context, String modelName) {
    return Drawer(
      backgroundColor: AppColors.surfaceDark,
      width: 280,
      child: ChatInfoPanel(
        chatTitle: widget.chatId != null ? 'Chat' : 'New Chat',
        modelName: modelName,
        memoryEnabled: true,
        onClearChat: () {
          ref.read(chatProvider.notifier).clearCurrentSession();
          Navigator.pop(context);
        },
        onNewChat: () {
          ref.read(chatProvider.notifier).clearCurrentSession();
          Navigator.pop(context);
          context.go('/chat');
        },
        onClose: () => Navigator.pop(context),
        onTitleChanged: (title) {},
        onMemoryToggled: (enabled) {},
      ),
    );
  }

  /// ChatGPT-style shimmer skeleton for chat history loading
  Widget _buildChatLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // User message shimmer (right-aligned, smaller)
          Align(
            alignment: Alignment.centerRight,
            child: ShimmerLoading(
              width: 200,
              height: 44,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          // Assistant message shimmer (left-aligned, larger)
          ShimmerLoading(
            width: double.infinity,
            height: 100,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 24),
          // Another user message
          Align(
            alignment: Alignment.centerRight,
            child: ShimmerLoading(
              width: 160,
              height: 44,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          // Another assistant message
          ShimmerLoading(
            width: double.infinity,
            height: 80,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            
            Text(
              'What can I help with?',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            if (ref.watch(chatProvider).researchMode != null) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Trending nearby',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Latest Tech News',
                  'Stock Market Today',
                  'New Movie Releases',
                  'Premier League Results',
                  'Crypto Prices',
                  'Climate Change Updates',
                  'Global Economic Trends',
                  'SpaceX Launch Schedule'
                ].map((topic) => ActionChip(
                  label: Text(topic),
                  onPressed: () {
                    _messageController.text = topic;
                    _sendMessage();
                  },
                  backgroundColor: AppColors.surfaceLight,
                  labelStyle: const TextStyle(color: AppColors.textDark),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                )).toList(),
              ),
            ] else
              ExpandedSuggestionChips(
                onSuggestionTap: (suggestion) {
                  // Populate input box with suggestion prefix instead of sending
                  _messageController.text = '$suggestion ';
                  _messageController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _messageController.text.length),
                  );
                  _focusNode.requestFocus();
                },
                onCategorySelected: (category) {
                  setState(() => _selectedSuggestionCategory = category);
                },
              ),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildMessageList(BuildContext context, List<ChatMessage> messages, {EdgeInsets? contentPadding}) {
    return Stack(
      children: [
        // Messages ListView
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: ListView.builder(
              controller: _scrollController,
              padding: contentPadding ?? const EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length + (ref.watch(chatProvider).researchProgress != null && !ref.watch(chatProvider).researchProgress!.isComplete ? 1 : 0),
              itemBuilder: (context, index) {
                // If index is last and we have research progress
                final chatState = ref.watch(chatProvider);
                if (index == messages.length && chatState.researchProgress != null && !chatState.researchProgress!.isComplete) {
                   return Padding(
                     padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                     child: Align(
                       alignment: Alignment.centerLeft, // Or center, but usually left or below user
                       child: ResearchProgressCapsule(
                           progress: chatState.researchProgress!,
                           onTap: () {
                             showModalBottomSheet(
                               context: context,
                               isScrollControlled: true,
                               backgroundColor: Colors.transparent,
                               builder: (ctx) => ResearchActivityPanel(
                                 logs: chatState.researchProgress!.logs,
                                 onClose: () => Navigator.pop(ctx),
                               ),
                             );
                           },
                         ),
                     ),
                   );
                }

                final message = messages[index];
                return MessageBubble(
                  message: message,
                  onCopy: () {
                    // Default copy just the message content
                    Clipboard.setData(ClipboardData(text: message.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Copied to clipboard'),
                        backgroundColor: AppColors.surface,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onEdit: () => _startEditing(message),
                  onRegenerate: message.role != 'user' ? () {
                    // Call regenerate on provider
                    ref.read(chatProvider.notifier).regenerateMessage(message.id);
                  } : null,
                  onShare: () {
                    if (message.role == 'user') {
                      _handleShare(); // Share full chat link if user message? or just text? 
                      // Actually for single message share we might just want to share text
                      // But the prompt says "share for in the first message correctly copy that block"
                      // Let's implement specific text share for this bubble
                      Share.share(message.content);
                    } else {
                      // AI Message - find preceding user message
                      String shareContent = message.content;
                      if (index > 0) {
                        final prevMessage = messages[index - 1];
                        if (prevMessage.role == 'user') {
                          shareContent = 'User: ${prevMessage.content}\n\nAris: ${message.content}';
                        }
                      }
                      Share.share(shareContent);
                    }
                  },
                  onLike: () {},
                  onDislike: () {},
                );
              },
            ),
          ),
        ),
      ),
        
        // Scroll to bottom button - only show if not at bottom AND scrollable
        if (!_isAtBottom && _scrollController.hasClients && _scrollController.position.maxScrollExtent > 0)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _scrollToBottom,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowDown02,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  


  Future<void> _handleVoiceCancel() async {
    await ref.read(voiceInputProvider.notifier).cancelRecording();
  }

  Widget _buildInputArea(BuildContext context, bool isStreaming, VoiceInputState voiceState) {
    // Voice mode should stay active during ALL processing states
    final isListening = voiceState == VoiceInputState.listening ||
                        voiceState == VoiceInputState.thinking ||
                        voiceState == VoiceInputState.finalizing ||
                        voiceState == VoiceInputState.transcribing ||
                        voiceState == VoiceInputState.noSpeech;
    
    final chatState = ref.watch(chatProvider);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quota exceeded message (ChatGPT-style above input)
        if (chatState.quotaExceeded && chatState.quotaMessage != null)
          GestureDetector(
            onTap: () => ref.read(chatProvider.notifier).clearQuotaMessage(),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.quotaMessage!,
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.close, size: 14, color: AppColors.warning),
                ],
              ),
            ),
          ),
        
        // Input box
        ExpandableInputBox(
          controller: _messageController,
          focusNode: _focusNode,
          hintText: 'Ask Aris',
          isStreaming: isStreaming,
          isVoiceListening: isListening,
          isVoiceConvertedText: _isVoiceConverted,
          attachedImages: const [], // TODO: Add image attachment state
          researchMode: chatState.researchMode,
          onSend: _sendMessage,
          onAttachmentTap: _showAttachmentOptions,
          onVoiceTap: _handleVoiceTap,
          onVoiceStopAndSend: _handleVoiceStopAndSend,
          onVoiceCancel: _handleVoiceCancel,
          onVoiceRestart: () => ref.read(voiceInputProvider.notifier).restartRecording(),
          onCancelStream: () => ref.read(chatProvider.notifier).cancelStream(),
          onClearResearchMode: () {
            // Cancel ongoing search and clear research mode
            ref.read(chatProvider.notifier).cancelSearch();
            ref.read(chatProvider.notifier).clearResearchMode();
          },
          onRemoveImage: (file) {
            // TODO: Implement image removal
          },
        ),
      ],
    );
  }
  void _startEditing(ChatMessage message) {
    setState(() {
      _editingMessageId = message.id;
      _editingContent = message.content;
      _messageController.text = message.content;
    });
    // Find parent to reset "Restart from here" logic? 
    // Actually the backend handles it.
  }

  void _cancelEditing() {
    setState(() {
      _editingMessageId = null;
      _editingContent = null;
      _messageController.clear();
    });
    _focusNode.unfocus();
  }

  void _saveEdit() {
    if (_editingMessageId == null) return;
    
    final newContent = _messageController.text.trim();
    if (newContent.isEmpty) return;
    
    if (newContent == _editingContent) {
      _cancelEditing();
      return;
    }
    
    ref.read(chatProvider.notifier).editMessage(_editingMessageId!, newContent);
    _cancelEditing();
  }

  Widget _buildEditPanel(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sticky Warning Snackbar (ChatGPT style)
        Container(
          width: double.infinity,
          color: isDark ? const Color(0xFF2E2E2E) : Colors.grey[100],
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Editing this message will restart the conversation from here.',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        // Edit Panel
        Container(
          color: theme.scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Editing message',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _cancelEditing,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Text Area
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface : Colors.grey[50], 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  maxLines: 5,
                  minLines: 1,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  autofocus: true,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Actions
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _saveEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Save & Submit'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}



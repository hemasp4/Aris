import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
import '../widgets/voice_input_button.dart';
import '../widgets/voice_waveform_widget.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_info_panel.dart';
import '../widgets/attachment_bottom_sheet.dart';
import '../widgets/chat_sidebar.dart';
import '../widgets/group_chat_dialogs.dart';
import '../widgets/group_chat_modal.dart';
import '../widgets/profile_edit_modal.dart';
import '../widgets/group_options_menu.dart';
import '../widgets/expandable_input_box.dart';
import '../widgets/fetch_indicator.dart';
import '../widgets/headline_cards.dart';
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
  bool _isDrawerOpen = false;
  String? _selectedSuggestionCategory;

  @override
  void initState() {
    super.initState();
    if (widget.chatId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatProvider.notifier).loadMessages(widget.chatId!);
      });
    }
    
    _scrollController.addListener(_onScroll);
    _messageController.addListener(() => setState(() {}));
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final maxScroll = position.maxScrollExtent;
      
      // If content is not scrollable (fits on screen), consider us at bottom
      if (maxScroll <= 0) {
        if (!_isAtBottom) setState(() => _isAtBottom = true);
        return;
      }
      
      // Check if we are near bottom (within 100px)
      final isAtBottom = position.pixels >= maxScroll - 100;
      if (isAtBottom != _isAtBottom) {
        setState(() => _isAtBottom = isAtBottom);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage([String? text]) {
    final content = text ?? _messageController.text.trim();
    if (content.isEmpty) return;
    
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
    final voiceNotifier = ref.read(voiceInputProvider.notifier);
    final currentState = ref.read(voiceInputProvider).state;
    
    if (currentState == VoiceInputState.idle) {
      await voiceNotifier.startRecording();
    } else if (currentState == VoiceInputState.listening) {
      final audioPath = await voiceNotifier.stopRecording();
      if (audioPath != null) {
        await Future.delayed(const Duration(seconds: 1));
        voiceNotifier.setTranscription('Voice message');
      }
    }
  }

  void _showAttachmentOptions() {
    showAttachmentSheet(
      context,
      onCamera: () {},
      onPhotos: () {},
      onFiles: () {},
      onCreateImage: () => _sendMessage('Create an image of'),
      onDeepResearch: () => _sendMessage('Deep research on'),
      onWebSearch: () => _sendMessage('Search the web for'),
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
      onEditProfile: () {
        ProfileEditModal.show(
          context,
          initialName: userName,
          initialUsername: user?.email?.split('@').first ?? '',
          initials: userInitials,
        );
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
    final messages = ref.watch(currentMessagesProvider);
    final isStreaming = ref.watch(isStreamingProvider);
    final voiceState = ref.watch(voiceInputProvider).state;
    final selectedModel = ref.watch(selectedModelProvider);
    final currentGroup = ref.watch(currentGroupProvider);
    
    ref.listen(currentMessagesProvider, (previous, next) {
      if (_isAtBottom && next.length > (previous?.length ?? 0)) {
        _scrollToBottom();
      }
    });
    
    ref.listen(voiceInputProvider, (previous, current) {
      if (current.transcribedText != null && 
          current.transcribedText != previous?.transcribedText) {
        _messageController.text = current.transcribedText!;
        ref.read(voiceInputProvider.notifier).reset();
      }
    });

    // Listen for chat errors (e.g. Quota exceeded)
    ref.listen(chatProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
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
      backgroundColor: AppColors.backgroundDark,
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
                  child: Column(
                    children: [
                      // Custom App Bar
                      _buildCustomAppBar(context, selectedModel, currentGroup),
                      
                      // Group chat invite banner (if in group)
                      if (currentGroup != null && messages.isNotEmpty)
                        _buildGroupInviteBanner(currentGroup),
                      
                      // Messages or empty state
                      Expanded(
                        child: Column(
                          children: [
                            // ChatGPT-style fetch indicator (thinking, searching, scraping)
                            Consumer(
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
                            // Message list or empty state
                            Expanded(
                              child: messages.isEmpty
                                  ? _buildEmptyState(context)
                                  : _buildMessageList(context, messages),
                            ),
                          ],
                        ),
                      ),
                      
                      // Random suggestion hints (shown when category is selected)
                      if (_selectedSuggestionCategory != null && messages.isEmpty)
                        SuggestionHints(
                          selectedCategory: _selectedSuggestionCategory,
                          onHintTap: (hint) {
                            final prefix = SuggestionData.getPromptPrefix(_selectedSuggestionCategory!);
                            _messageController.text = '$prefix $hint';
                            _messageController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _messageController.text.length),
                            );
                          },
                        ),
                      
                      // Input area
                      _buildInputArea(context, isStreaming, voiceState),
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
            
            // Voice recording overlay
            if (voiceState != VoiceInputState.idle)
              VoiceRecordingOverlay(
                onCancel: () => ref.read(voiceInputProvider.notifier).cancelRecording(),
                onStop: () async {
                  final audioPath = await ref.read(voiceInputProvider.notifier).stopRecording();
                  if (audioPath != null) {
                    await Future.delayed(const Duration(seconds: 1));
                    ref.read(voiceInputProvider.notifier).setTranscription('Voice message');
                  }
                },
              ),
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
    String chatTitle = 'Aris AI';
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.35),
                    child: Text(
                      isEmptyChat ? 'Aris AI' : chatTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isEmptyChat) ...[
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
      child: Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(8), // Added padding for better tap area
        decoration: BoxDecoration(
          color: AppColors.surface,
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
  
  /// STATE A: Empty chat action icons (Group invite + Temp chat)
  Widget _buildEmptyChatActions() {
    return Container(
      key: const ValueKey('empty_actions'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
    );
  }
  
  /// STATE B: Active chat action icons (Group invite + New chat + More options)
  Widget _buildActiveChatActions(String chatTitle) {
    return Container(
      key: const ValueKey('active_actions'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
            onTap: () => _showMoreOptionsMenu(chatTitle),
          ),
        ],
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
  
  /// Show more options popup menu (positioned at top-right corner)
  void _showMoreOptionsMenu(String chatTitle) {
    final chatState = ref.read(chatProvider);
    final sessions = ref.read(chatSessionsProvider);
    final currentSession = sessions.where((s) => s.id == chatState.currentSessionId).firstOrNull;
    final isPinned = currentSession?.isPinned ?? false;
    final isArchived = currentSession?.isArchived ?? false;
    
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200,
        kToolbarHeight + MediaQuery.of(context).padding.top,
        16,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surface,
      items: [
        // Chat title header
        PopupMenuItem<String>(
          enabled: false,
          height: 40,
          child: Text(
            chatTitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        // Share
        PopupMenuItem<String>(
          value: 'share',
          child: _buildMenuOption(
            icon: HugeIcons.strokeRoundedShare01,
            label: 'Share',
          ),
        ),
        // Rename
        PopupMenuItem<String>(
          value: 'rename',
          child: _buildMenuOption(
            icon: HugeIcons.strokeRoundedEdit02,
            label: 'Rename',
          ),
        ),
        // Archive/Unarchive
        PopupMenuItem<String>(
          value: 'archive',
          child: _buildMenuOption(
            icon: isArchived 
                ? HugeIcons.strokeRoundedArchive02 
                : HugeIcons.strokeRoundedArchive,
            label: isArchived ? 'Unarchive' : 'Archive',
          ),
        ),
        // Pin/Unpin
        PopupMenuItem<String>(
          value: 'pin',
          child: _buildMenuOption(
            icon: isPinned 
                ? HugeIcons.strokeRoundedPinOff 
                : HugeIcons.strokeRoundedPin,
            label: isPinned ? 'Unpin chat' : 'Pin chat',
          ),
        ),
        const PopupMenuDivider(height: 1),
        // Delete (destructive)
        PopupMenuItem<String>(
          value: 'delete',
          child: _buildMenuOption(
            icon: HugeIcons.strokeRoundedDelete02,
            label: 'Delete',
            isDestructive: true,
          ),
        ),
        // Report
        PopupMenuItem<String>(
          value: 'report',
          child: _buildMenuOption(
            icon: HugeIcons.strokeRoundedFlag02,
            label: 'Report',
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      _handleMenuAction(value);
    });
  }
  
  /// Build menu option row
  Widget _buildMenuOption({
    required dynamic icon,
    required String label,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return Row(
      children: [
        HugeIcon(
          icon: icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
          ),
        ),
      ],
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
      case 'archive':
        if (sessionId != null) {
          ref.read(chatProvider.notifier).toggleArchiveSession(sessionId);
        }
        break;
      case 'pin':
        if (sessionId != null) {
          ref.read(chatProvider.notifier).togglePinSession(sessionId);
        }
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }
  
  /// Show delete confirmation dialog
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete chat?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final sessionId = ref.read(chatProvider).currentSessionId;
              if (sessionId != null) {
                ref.read(chatProvider.notifier).deleteSession(sessionId);
                context.go('/chat');
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Show report dialog
  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Report this chat?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select a reason for reporting:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildReportOption(ctx, 'Inappropriate content'),
            _buildReportOption(ctx, 'Spam or misleading'),
            _buildReportOption(ctx, 'Harmful or unsafe'),
            _buildReportOption(ctx, 'Other'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReportOption(BuildContext ctx, String reason) {
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report submitted: $reason'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        width: double.infinity,
        child: Text(
          reason,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  /// Show menu for regular chats
  Future<void> _showChatTitleMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            
            // Title with dropdown icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chat Options',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_up, color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
            
            const Divider(color: AppColors.dividerDark),
            
            // Menu items
            ListTile(
              leading: Icon(Icons.edit_outlined, color: AppColors.textDark, size: 22),
              title: Text('Rename chat', style: TextStyle(color: AppColors.textDark, fontSize: 15)),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: Icon(Icons.share_outlined, color: AppColors.textDark, size: 22),
              title: Text('Share', style: TextStyle(color: AppColors.textDark, fontSize: 15)),
              onTap: () => Navigator.pop(context, 'share'),
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined, color: AppColors.textDark, size: 22),
              title: Text('Customize Aris', style: TextStyle(color: AppColors.textDark, fontSize: 15)),
              onTap: () => Navigator.pop(context, 'customize'),
            ),
            ListTile(
              leading: Icon(Icons.flag_outlined, color: AppColors.error, size: 22),
              title: Text('Report', style: TextStyle(color: AppColors.error, fontSize: 15)),
              onTap: () => Navigator.pop(context, 'report'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error, size: 22),
              title: Text('Delete chat', style: TextStyle(color: AppColors.error, fontSize: 15)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    
    if (action == null || !mounted) return;
    
    switch (action) {
      case 'rename':
        final newTitle = await showRenameGroupDialog(context, 'Chat');
        if (newTitle != null && newTitle.isNotEmpty && widget.chatId != null) {
          // TODO: Implement rename chat
        }
        break;
      case 'share':
        _handleShare();
        break;
      case 'customize':
        // Navigate to customization
        break;
      case 'report':
        // Report chat
        break;
      case 'delete':
        if (widget.chatId != null) {
          ref.read(chatProvider.notifier).deleteSession(widget.chatId!);
          context.go('/chat');
        }
        break;
    }
  }

  Future<void> _showGroupTitleMenu(GroupChat group) async {
    final user = ref.read(currentUserProvider);
    final action = await showChatTitleMenu(
      context,
      ref,
      groupId: group.id,
      title: group.title,
      isOwner: group.ownerId == (user?.id ?? ''),
    );
    
    if (action == null || !mounted) return;
    
    switch (action) {
      case 'people':
        // Show people in group
        break;
      case 'link':
        showGroupLinkDialog(context, group.link ?? '');
        break;
      case 'rename':
        final newTitle = await showRenameGroupDialog(context, group.title);
        if (newTitle != null && newTitle.isNotEmpty) {
          ref.read(groupChatProvider.notifier).renameGroup(group.id, newTitle);
        }
        break;
      case 'customize':
        // Navigate to customization
        break;
      case 'report':
        // Report group
        break;
      case 'delete':
        ref.read(groupChatProvider.notifier).deleteGroup(group.id);
        break;
    }
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

  Widget _buildMessageList(BuildContext context, List<ChatMessage> messages) {
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
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
                  onRegenerate: message.role != 'user' ? () {
                    // TODO: Implement regenerate response
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
  
  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isUser = message.role == 'user';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.userBubbleDark : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                      ),
                    )
                  else
                    MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        code: TextStyle(
                          backgroundColor: AppColors.surfaceDarkElevated,
                          fontFamily: 'monospace',
                          color: AppColors.textDark,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.surfaceDarkElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  if (message.isStreaming) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.avatarOrange,
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildInputArea(BuildContext context, bool isStreaming, VoiceInputState voiceState) {
    final isListening = voiceState == VoiceInputState.listening;
    
    return ExpandableInputBox(
      controller: _messageController,
      focusNode: _focusNode,
      hintText: 'Message Aris...',
      isStreaming: isStreaming,
      isVoiceListening: isListening,
      attachedImages: const [], // TODO: Add image attachment state
      onSend: _sendMessage,
      onAttachmentTap: _showAttachmentOptions,
      onVoiceTap: _handleVoiceTap,
      onCancelStream: () => ref.read(chatProvider.notifier).cancelStream(),
      onRemoveImage: (file) {
        // TODO: Implement image removal
      },
    );
  }
}

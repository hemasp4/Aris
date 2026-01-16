import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/chat_provider.dart';

/// Shared chat model for read-only preview
class SharedChat {
  final String id;
  final String title;
  final String ownerName;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  SharedChat({
    required this.id,
    required this.title,
    required this.ownerName,
    required this.createdAt,
    required this.messages,
  });
}

/// SharedChatScreen - Read-only preview of a shared chat
/// Matches ChatGPT's shared template UI
class SharedChatScreen extends ConsumerStatefulWidget {
  final String shareId;

  const SharedChatScreen({super.key, required this.shareId});

  @override
  ConsumerState<SharedChatScreen> createState() => _SharedChatScreenState();
}

class _SharedChatScreenState extends ConsumerState<SharedChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  bool _isLoading = true;
  SharedChat? _sharedChat;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSharedChat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isNotAtBottom = _scrollController.position.pixels <
          _scrollController.position.maxScrollExtent - 100;
      if (isNotAtBottom != _showScrollToBottom) {
        setState(() => _showScrollToBottom = isNotAtBottom);
      }
    }
  }

  Future<void> _loadSharedChat() async {
    try {
      // TODO: Replace with actual API call
      // final response = await ref.read(chatProvider.notifier).loadSharedChat(widget.shareId);
      
      // Mock data for demonstration
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _sharedChat = SharedChat(
          id: widget.shareId,
          title: 'Shared Conversation',
          ownerName: 'Anonymous',
          createdAt: DateTime.now(),
          messages: [
            ChatMessage(
              id: '1',
              role: 'user',
              content: 'This is a shared conversation preview.',
              timestamp: DateTime.now(),
            ),
            ChatMessage(
              id: '2',
              role: 'assistant',
              content: 'Hello! This is a sample response from the AI assistant. When you tap "Continue conversation", this chat will be imported into your account and you can continue the conversation.',
              timestamp: DateTime.now(),
            ),
          ],
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load shared chat';
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _continueConversation() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // TODO: Replace with actual API call to import chat
      // final newChatId = await ref.read(chatProvider.notifier).continueSharedChat(widget.shareId);
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        context.go('/chat'); // Navigate to new chat
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation imported! You can now continue chatting.'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showMoreMenu() {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 180,
        kToolbarHeight + MediaQuery.of(context).padding.top,
        16,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surface,
      items: [
        PopupMenuItem<String>(
          value: 'learn',
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedInformationCircle,
                size: 20,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 12),
              const Text(
                'Learn more about shared links',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedFlag02,
                size: 20,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 12),
              const Text(
                'Report',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'learn') {
        _showLearnMoreDialog();
      } else if (value == 'report') {
        _showReportDialog();
      }
    });
  }

  void _showLearnMoreDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'About Shared Links',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Shared links allow others to view a conversation and continue it in their own account. '
          'The original conversation remains unchanged.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Report this shared chat?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select a reason:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _buildReportOption(ctx, 'Inappropriate content'),
            _buildReportOption(ctx, 'Spam or misleading'),
            _buildReportOption(ctx, 'Harmful information'),
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
        child: Text(reason, style: const TextStyle(color: AppColors.textPrimary)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get text scaler for accessibility
    final textScaler = MediaQuery.of(context).textScaler;
    final iconSize = 22.0 * textScaler.scale(1.0).clamp(1.0, 1.3);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            _buildAppBar(iconSize),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                      : _buildContent(),
            ),
            
            // Continue button
            if (!_isLoading && _error == null)
              _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(double iconSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/chat'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft02,
                  size: iconSize,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          
          // Title
          Expanded(
            child: Text(
              _sharedChat?.title ?? 'Shared Chat',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // More menu
          GestureDetector(
            onTap: _showMoreMenu,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedMoreVertical,
                  size: iconSize,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        // Messages list
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _sharedChat!.messages.length,
          itemBuilder: (context, index) {
            final message = _sharedChat!.messages[index];
            return _buildMessageBubble(message);
          },
        ),
        
        // Scroll to bottom button
        if (_showScrollToBottom)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _scrollToBottom,
                child: Container(
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
                      icon: HugeIcons.strokeRoundedArrowDown01,
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

  Widget _buildMessageBubble(ChatMessage message) {
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
              child: isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        h1: const TextStyle(color: AppColors.textPrimary, fontSize: 24),
                        h2: const TextStyle(color: AppColors.textPrimary, fontSize: 20),
                        h3: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
                        code: TextStyle(
                          backgroundColor: AppColors.surfaceDarkElevated,
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.surfaceDarkElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
    );
  }

  Widget _buildContinueButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(
          top: BorderSide(
            color: AppColors.textMuted.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _continueConversation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Continue conversation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

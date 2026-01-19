import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../../auth/providers/auth_provider.dart';

/// Share Link Screen - Full screen share page matching ChatGPT design
/// Shows chat preview with options to edit title and share name
class ShareLinkScreen extends ConsumerStatefulWidget {
  final String? chatId;
  final String chatTitle;
  final List<ChatMessage> messages;

  const ShareLinkScreen({
    super.key,
    required this.chatId,
    required this.chatTitle,
    required this.messages,
  });

  @override
  ConsumerState<ShareLinkScreen> createState() => _ShareLinkScreenState();
}

class _ShareLinkScreenState extends ConsumerState<ShareLinkScreen> {
  bool _shareYourName = false;
  late String _chatTitle;
  bool _isLoading = true; // Start with loading state
  bool _isSharing = false;
  String? _generatedLink;

  bool _chatPreviewReady = false;

  @override
  void initState() {
    super.initState();
    _chatTitle = widget.chatTitle;
    _loadChatForSharing();
  }

  /// Simulate loading chat data for sharing
  Future<void> _loadChatForSharing() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _generatedLink = 'https://aris.ai/shared/${widget.chatId ?? 'new'}';
        _isLoading = false;
        _chatPreviewReady = true;
      });
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? AppColors.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'About Sharing',
          style: TextStyle(color: _textColor),
        ),
        content: Text(
          'When you share a chat:\n\n'
          '• Anyone with the link can view the conversation\n'
          '• Messages after sharing won\'t be included\n'
          '• Images and files won\'t be accessible\n'
          '• You can disable the link anytime from settings',
          style: TextStyle(color: _textSecondaryColor),
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

  void _showOptionsMenu() {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 180,
        MediaQuery.of(context).size.height * 0.65,
        20,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _isDarkMode ? AppColors.surface : Colors.white,
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          value: 'share_name',
          child: _buildMenuItemContent(
            icon: HugeIcons.strokeRoundedUser,
            label: 'Share your name',
            isSelected: _shareYourName,
          ),
        ),
        PopupMenuItem<String>(
          value: 'edit_title',
          child: _buildMenuItemContent(
            icon: HugeIcons.strokeRoundedEdit02,
            label: 'Edit Title',
          ),
        ),
      ],
    ).then((value) {
      if (value == 'share_name') {
        setState(() => _shareYourName = !_shareYourName);
      } else if (value == 'edit_title') {
        _showEditTitleDialog();
      }
    });
  }

  Widget _buildMenuItemContent({
    required dynamic icon,
    required String label,
    bool isSelected = false,
  }) {
    return Row(
      children: [
        HugeIcon(
          icon: icon,
          size: 20,
          color: _textColor,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: _textColor),
        ),
        if (isSelected) ...[
          const Spacer(),
          Icon(Icons.check, size: 18, color: AppColors.primary),
        ],
      ],
    );
  }

  void _showEditTitleDialog() {
    final controller = TextEditingController(text: _chatTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? AppColors.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Title', style: TextStyle(color: _textColor)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: _textColor),
          decoration: InputDecoration(
            hintText: 'Enter title',
            hintStyle: TextStyle(color: _textSecondaryColor),
            filled: true,
            fillColor: _isDarkMode ? AppColors.surfaceElevated : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: _textSecondaryColor)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _chatTitle = controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteShareLink() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? AppColors.surface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Share Link?', style: TextStyle(color: _textColor)),
        content: Text(
          'This will delete the share link. Anyone with the link will no longer be able to view this chat.',
          style: TextStyle(color: _textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: _textSecondaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to chat
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Share link deleted'),
                  backgroundColor: _isDarkMode ? AppColors.surface : Colors.black87,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }



  Future<void> _shareLink() async {
    setState(() => _isSharing = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final link = _generatedLink!;
      final author = _shareYourName ? 'You' : 'Anonymous';
      
      // Use share_plus which shows Android native share sheet
      await Share.share(
        '$_chatTitle\nShared by $author\n\n$link',
        subject: _chatTitle,
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _textColor => _isDarkMode ? AppColors.textPrimary : Colors.black87;
  Color get _textSecondaryColor => _isDarkMode ? AppColors.textSecondary : Colors.black54;
  Color get _bgColor => _isDarkMode ? AppColors.backgroundDark : const Color(0xFFF5F5F5);
  // Chat container: white in light mode, surface in dark mode
  Color get _chatContainerColor => _isDarkMode ? AppColors.surface : Colors.white;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.of(context).textScaler;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // MediaQuery-based responsive values
    final basePadding = (screenWidth * 0.04).clamp(12.0, 24.0);
    final iconSize = 22.0 * textScaler.scale(1.0).clamp(1.0, 1.3);
    final titleFontSize = 17.0 * textScaler.scale(1.0).clamp(1.0, 1.2);
    
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            _buildAppBar(iconSize, titleFontSize, basePadding),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(basePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description text
                    _buildDescriptionText(textScaler),
                    SizedBox(height: basePadding * 1.5),
                    
                    // Chat preview card container - white in light mode
                    _buildChatPreviewContainer(textScaler, basePadding),
                    
                    // Chat info row with delete icon
                    _buildChatInfoRow(textScaler, basePadding),
                  ],
                ),
              ),
            ),
            
            // Share Link button - dark in light mode, light in dark mode
            _buildShareButton(basePadding, textScaler),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionText(TextScaler textScaler) {
    final fontSize = 14.0 * textScaler.scale(1.0).clamp(1.0, 1.2);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _chatPreviewReady
              ? 'You\'ve already shared a link to this chat. If you\'d like to include new messages, delete this link and share your chat again.'
              : 'Messages sent or received after sharing your link won\'t be shared. Anyone with the URL will be able to view your shared chat.',
          style: TextStyle(
            color: _textSecondaryColor,
            fontSize: fontSize,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Recipients won\'t be able to view images, download files, or custom profiles.',
          style: TextStyle(
            color: _textSecondaryColor,
            fontSize: fontSize,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(double iconSize, double titleFontSize, double padding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding / 2, vertical: padding / 2),
      child: Row(
        children: [
          // Back button with padding
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
                  color: _textColor,
                ),
              ),
            ),
          ),
          
          // Title
          Expanded(
            child: Text(
              'Share link to chat',
              style: TextStyle(
                color: _textColor,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Help button with padding
          GestureDetector(
            onTap: _showHelpDialog,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _textSecondaryColor,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        color: _textSecondaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPreviewContainer(TextScaler textScaler, double basePadding) {
    final messageFontSize = 14.0 * textScaler.scale(1.0).clamp(1.0, 1.2);
    final previewMessages = widget.messages.toList();
    
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 200,
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      decoration: BoxDecoration(
        color: _chatContainerColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _textSecondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading chat preview...',
                      style: TextStyle(color: _textSecondaryColor),
                    ),
                  ],
                ),
              )
            : previewMessages.isEmpty
                ? Center(
                    child: Text(
                      'No messages to preview',
                      style: TextStyle(color: _textSecondaryColor),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(basePadding),
                    itemCount: previewMessages.length,
                    itemBuilder: (context, index) {
                      final message = previewMessages[index];
                      return _buildMessageBubble(message, messageFontSize, basePadding, index == previewMessages.length - 1);
                    },
                  ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, double fontSize, double basePadding, bool isLast) {
    final isUser = message.role == 'user';
    
    // User messages: right aligned with background
    // Assistant messages: left aligned, no background
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        margin: EdgeInsets.only(
          bottom: isLast ? 0 : 12,
          left: isUser ? 40 : 0,
          right: isUser ? 0 : 40,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: basePadding,
          vertical: basePadding * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? (_isDarkMode ? AppColors.surfaceElevated : Colors.grey[200])
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.content.length > 100
              ? '${message.content.substring(0, 100)}...'
              : message.content,
          style: TextStyle(
            color: _textColor,
            fontSize: fontSize,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildChatInfoRow(TextScaler textScaler, double basePadding) {
    final authState = ref.watch(authProvider);
    final authorName = _shareYourName 
        ? (authState.user?.username ?? 'You')
        : 'Anonymous';
    final dateStr = DateFormat('d MMM yyyy h:mm:ss a').format(DateTime.now());
    
    final titleFontSize = 16.0 * textScaler.scale(1.0).clamp(1.0, 1.2);
    final subtitleFontSize = 13.0 * textScaler.scale(1.0).clamp(1.0, 1.2);
    
    return Padding(
      padding: EdgeInsets.only(top: basePadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _chatTitle,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$authorName · $dateStr',
                  style: TextStyle(
                    color: _textSecondaryColor,
                    fontSize: subtitleFontSize,
                  ),
                ),
              ],
            ),
          ),
          
          // Icon: loading dots OR delete icon based on state
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? _showOptionsMenu : _deleteShareLink,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isDarkMode 
                      ? AppColors.surfaceElevated 
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: _isLoading
                      ? HugeIcon(
                          icon: HugeIcons.strokeRoundedMoreHorizontal,
                          size: 22,
                          color: _textColor,
                        )
                      : HugeIcon(
                          icon: HugeIcons.strokeRoundedDelete02,
                          size: 22,
                          color: Colors.red,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(double basePadding, TextScaler textScaler) {
    final buttonFontSize = 16.0 * textScaler.scale(1.0).clamp(1.0, 1.2);
    
    // Share Link button: DARK in light mode, WHITE in dark mode
    final buttonBgColor = _isDarkMode 
        ? Colors.white 
        : Colors.black87;
    final buttonTextColor = _isDarkMode 
        ? Colors.black87 
        : Colors.white;
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        basePadding,
        basePadding * 0.75,
        basePadding,
        basePadding * 0.75 + MediaQuery.of(context).padding.bottom,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading || _isSharing ? null : _shareLink,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonBgColor,
            foregroundColor: buttonTextColor,
            disabledBackgroundColor: buttonBgColor.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            elevation: 0,
          ),
          child: _isSharing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: buttonTextColor,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedShare08,
                      size: 20,
                      color: buttonTextColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Share Link',
                      style: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w500,
                        color: buttonTextColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

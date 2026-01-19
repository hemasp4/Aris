import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/chatgpt_code_theme.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../providers/chat_provider.dart';

/// ChatGPT-exact message bubble widget with:
/// - User messages: Right aligned with grey bubble, rounded corners
/// - AI messages: Full width, no bubble, markdown with code highlighting
/// - Long-press menu: Copy, Select Text, Edit Message, Share
class MessageBubble extends ConsumerStatefulWidget {
  final ChatMessage message;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onRegenerate;
  final VoidCallback? onShare;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;

  const MessageBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.onEdit,
    this.onRegenerate,
    this.onShare,
    this.onLike,
    this.onDislike,
  });

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final isUser = widget.message.role == 'user';
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaler = MediaQuery.of(context).textScaler;
    
    // Responsive padding based on screen size
    final basePadding = (screenWidth * 0.04).clamp(12.0, 20.0);

    if (isUser) {
      return _buildUserMessage(context, isDark, screenWidth, textScaler, basePadding);
    } else {
      return _buildAIMessage(context, isDark, screenWidth, textScaler, basePadding, settings);
    }
  }

  /// User message: Right aligned with grey bubble
  Widget _buildUserMessage(
    BuildContext context,
    bool isDark,
    double screenWidth,
    TextScaler textScaler,
    double basePadding,
  ) {
    final fontSize = 15.0 * textScaler.scale(1.0).clamp(0.8, 1.3);
    
    return GestureDetector(
      onLongPress: () => _showLongPressMenu(context, true),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: basePadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Copy and Share icons on left (show on hover/tap)
            if (_isHovered) ...[
              _buildQuickActionIcon(
                icon: HugeIcons.strokeRoundedCopy01,
                onTap: () => _copyToClipboard(context),
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _buildQuickActionIcon(
                icon: HugeIcons.strokeRoundedShare08,
                onTap: widget.onShare,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
            ],
            
            // Message bubble
            MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: screenWidth * 0.75,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: basePadding,
                  vertical: basePadding * 0.8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.userBubble : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SelectableText(
                  widget.message.content,
                  style: GoogleFonts.inter(
                    color: isDark ? AppColors.primaryText : Colors.black87,
                    fontSize: fontSize,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AI message: Full width, no bubble, with markdown/code
  Widget _buildAIMessage(
    BuildContext context,
    bool isDark,
    double screenWidth,
    TextScaler textScaler,
    double basePadding,
    dynamic settings,
  ) {
    final fontSize = 15.0 * textScaler.scale(1.0).clamp(0.8, 1.3);
    
    // Build message content with fallback
    Widget messageContent;
    try {
      if (settings.enableMarkdown) {
        messageContent = _buildMarkdownContent(context, settings, isDark, fontSize);
      } else {
        messageContent = SelectableText(
          widget.message.content,
          style: GoogleFonts.inter(
            color: isDark ? AppColors.primaryText : Colors.black87,
            fontSize: fontSize,
            height: 1.5,
          ),
        );
      }
    } catch (e) {
      // Fallback to plain text if markdown fails
      messageContent = SelectableText(
        widget.message.content,
        style: GoogleFonts.inter(
          color: isDark ? AppColors.primaryText : Colors.black87,
          fontSize: fontSize,
          height: 1.5,
        ),
      );
    }
    
    return GestureDetector(
      onLongPress: () => _showLongPressMenu(context, false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: basePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message content - only show if has content
              if (widget.message.content.isNotEmpty)
                messageContent,
              
              // Streaming indicator - show only while streaming
              if (widget.message.isStreaming) ...[
                if (widget.message.content.isNotEmpty)
                  const SizedBox(height: 4),
                _buildStreamingIndicator(),
              ],
              
              // Action bar (shown after message complete, like ChatGPT)
              if (!widget.message.isStreaming && widget.message.content.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildAIActionBar(context, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required dynamic icon,
    required VoidCallback? onTap,
    required Color color,
    String? tooltip,
  }) {
    return IconButton(
      icon: icon is IconData
          ? Icon(icon, size: 18, color: color)
          : HugeIcon(
              icon: icon,
              size: 18,
              color: color,
            ),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: tooltip,
    );
  }

  /// AI action bar with Copy, Like, Dislike, Sound, Share, More
  Widget _buildAIActionBar(BuildContext context, bool isDark) {
    final iconColor = isDark ? AppColors.textSecondary : Colors.grey[600];
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Copy
        _buildActionIcon(
          icon: HugeIcons.strokeRoundedCopy01,
          onTap: widget.onCopy,
          color: iconColor!,
          tooltip: 'Copy',
        ),
        
        // Like mechanism
        _buildActionIcon(
          icon: HugeIcons.strokeRoundedThumbsUp,
          onTap: widget.onLike,
          color: iconColor,
          tooltip: 'Good response',
        ),

        // Dislike mechanism
        _buildActionIcon(
          icon: HugeIcons.strokeRoundedThumbsDown,
          onTap: widget.onDislike,
          color: iconColor,
          tooltip: 'Bad response',
        ),
        
        // Sound / Read Aloud
        _buildActionIcon(
          icon: HugeIcons.strokeRoundedVolumeHigh,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Read aloud coming soon'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.surfaceElevated,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          color: iconColor,
          tooltip: 'Read Aloud',
        ),

        // Share
        _buildActionIcon(
          icon: HugeIcons.strokeRoundedShare08,
          onTap: widget.onShare,
          color: iconColor,
          tooltip: 'Share',
        ),

        // More Options (Retry, Branch)
        Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                color: AppColors.surfaceElevated,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            child: PopupMenuButton<String>(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedMoreHorizontal,
                size: 18,
                color: iconColor,
              ),
              tooltip: 'More',
              offset: const Offset(0, 30),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'retry',
                  child: Row(
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 20, color: AppColors.primaryText),
                      const SizedBox(width: 12),
                      Text('Retry', style: TextStyle(color: AppColors.primaryText, fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'branch',
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedGitFork,
                        size: 20,
                        color: AppColors.primaryText,
                      ),
                      const SizedBox(width: 12),
                      Text('Branch in new chat', style: TextStyle(color: AppColors.primaryText, fontSize: 14)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'retry') {
                   widget.onRegenerate?.call();
                } else if (value == 'branch') {
                   ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Branching coming soon'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.surfaceElevated,
                      ),
                   );
                }
              },
            ),
        ),
      ],
    );
  }

  Widget _buildQuickActionIcon({
    required dynamic icon,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevated : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: HugeIcon(
          icon: icon,
          size: 16,
          color: isDark ? AppColors.secondaryText : Colors.grey[600]!,
        ),
      ),
    );
  }

  /// ChatGPT-style long press menu
  void _showLongPressMenu(BuildContext context, bool isUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textScaler = MediaQuery.of(context).textScaler;
    final fontSize = 15.0 * textScaler.scale(1.0).clamp(1.0, 1.2);
    
    // Get message preview for header
    final previewText = widget.message.content.length > 30
        ? '${widget.message.content.substring(0, 30)}...'
        : widget.message.content;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with message preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceElevated : Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Text(
                previewText,
                style: GoogleFonts.inter(
                  color: isDark ? AppColors.textSecondary : Colors.grey[600],
                  fontSize: fontSize * 0.9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Menu items
            _buildMenuItem(
              icon: HugeIcons.strokeRoundedCopy01,
              label: 'Copy',
              onTap: () {
                Navigator.pop(ctx);
                _copyToClipboard(context);
              },
              isDark: isDark,
              fontSize: fontSize,
            ),
            _buildMenuDivider(isDark),
            _buildMenuItem(
              icon: HugeIcons.strokeRoundedTextSelection,
              label: 'Select Text',
              onTap: () {
                Navigator.pop(ctx);
                // Text is already selectable
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Long press on text to select'),
                    backgroundColor: isDark ? AppColors.surface : Colors.black87,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              isDark: isDark,
              fontSize: fontSize,
            ),
            if (isUser) ...[
              _buildMenuDivider(isDark),
              _buildMenuItem(
                icon: HugeIcons.strokeRoundedEdit02,
                label: 'Edit Message',
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onEdit?.call();
                },
                isDark: isDark,
                fontSize: fontSize,
              ),
            ],
            _buildMenuDivider(isDark),
            _buildMenuItem(
              icon: HugeIcons.strokeRoundedShare08,
              label: 'Share',
              onTap: () {
                Navigator.pop(ctx);
                widget.onShare?.call();
              },
              isDark: isDark,
              fontSize: fontSize,
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required dynamic icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required double fontSize,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              HugeIcon(
                icon: icon,
                size: 22,
                color: isDark ? AppColors.textPrimary : Colors.black87,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isDark ? AppColors.textPrimary : Colors.black87,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.borderSubtle : Colors.grey[200],
    );
  }

  Widget _buildStreamingIndicator() {
    // ChatGPT-style: Single blinking dot
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: _BlinkingCursor(),
    );
  }

  Widget _buildMarkdownContent(
    BuildContext context,
    dynamic settings,
    bool isDark,
    double fontSize,
  ) {
    return MarkdownBody(
      data: widget.message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.inter(
          color: isDark ? AppColors.primaryText : Colors.black87,
          fontSize: fontSize,
          height: 1.5,
        ),
        h1: GoogleFonts.inter(
          color: isDark ? AppColors.primaryText : Colors.black87,
          fontSize: fontSize * 1.5,
          fontWeight: FontWeight.w700,
        ),
        h2: GoogleFonts.inter(
          color: isDark ? AppColors.primaryText : Colors.black87,
          fontSize: fontSize * 1.3,
          fontWeight: FontWeight.w600,
        ),
        h3: GoogleFonts.inter(
          color: isDark ? AppColors.primaryText : Colors.black87,
          fontSize: fontSize * 1.1,
          fontWeight: FontWeight.w600,
        ),
        strong: GoogleFonts.inter(
          color: isDark ? AppColors.primaryText : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        em: GoogleFonts.inter(
          color: isDark ? AppColors.primaryText : Colors.black87,
          fontStyle: FontStyle.italic,
        ),
        code: GoogleFonts.jetBrainsMono(
          backgroundColor: isDark ? AppColors.surfaceDarkElevated : Colors.grey[200],
          color: isDark ? AppColors.accent : Colors.pink[700],
          fontSize: fontSize * 0.9,
        ),
        codeblockDecoration: const BoxDecoration(
          color: Colors.transparent, // Fix: Remove double background using transparent
        ),
        blockquote: GoogleFonts.inter(
          color: isDark ? AppColors.secondaryText : Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isDark ? AppColors.accent : Colors.grey[400]!,
              width: 3,
            ),
          ),
        ),
        listBullet: GoogleFonts.inter(
          color: isDark ? AppColors.primaryText : Colors.black87,
        ),
        a: GoogleFonts.inter(
          color: AppColors.accent,
          decoration: TextDecoration.underline,
        ),
        tableHead: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.primaryText : Colors.black87,
        ),
        tableBorder: TableBorder.all(
          color: isDark ? AppColors.borderSubtle : Colors.grey[300]!,
        ),
      ),
      builders: {
        'code': _SmartCodeBuilder(
          isDark: isDark,
          blockBuilder: settings.enableCodeHighlighting
              ? _ChatGPTCodeBlockBuilder(isDark: isDark)
              : _DefaultCodeBuilder(isDark: isDark),
          inlineBuilder: _InlineCodeBuilder(isDark: isDark),
        ),
      },
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        backgroundColor: isDark ? AppColors.surface : Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}


/// Blinking cursor for streaming indicator
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.4 + (_controller.value * 0.6)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _SmartCodeBuilder extends MarkdownElementBuilder {
  final bool isDark;
  final MarkdownElementBuilder blockBuilder;
  final MarkdownElementBuilder inlineBuilder;

  _SmartCodeBuilder({
    required this.isDark,
    required this.blockBuilder,
    required this.inlineBuilder,
  });

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final hasClass = element.attributes.containsKey('class');
    final hasNewlines = element.textContent.contains('\n');
    
    if (hasClass || hasNewlines) {
      return blockBuilder.visitElementAfter(element, preferredStyle)!;
    } else {
      return inlineBuilder.visitElementAfter(element, preferredStyle)!;
    }
  }
}

// ... classes continue below ...

class _ChatGPTCodeBlockBuilder extends MarkdownElementBuilder {
  final bool isDark;

  _ChatGPTCodeBlockBuilder({required this.isDark});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;
    final language = element.attributes['class']?.replaceFirst('language-', '') ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF7F7F8),
        border: Border.all(
          color: isDark ? const Color(0xFF444444) : const Color(0xFFE5E5E5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with language label and Copy code button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF7F7F8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.isNotEmpty ? language : 'code',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Code copied'),
                          backgroundColor: isDark ? AppColors.surface : Colors.black87,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCopy01,
                          size: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Copy code',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Code content with ChatGPT-accurate syntax highlighting
          Padding(
            padding: const EdgeInsets.all(16),
            child: HighlightView(
              code,
              language: language.isNotEmpty ? language : 'plaintext',
              // Use ChatGPT-accurate theme (red for definitions, yellow for calls)
              theme: isDark ? chatGPTDarkTheme : chatGPTLightTheme,
              textStyle: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                height: 1.5,
                color: isDark ? const Color(0xFFE0E0E0) : const Color(0xff24292e),
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}


class _DefaultCodeBuilder extends MarkdownElementBuilder {
  final bool isDark;

  _DefaultCodeBuilder({required this.isDark});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(
        code,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          color: Colors.grey[300],
          height: 1.5,
        ),
      ),
    );
  }
}

/// Builder for inline code styling with padding and radius
class _InlineCodeBuilder extends MarkdownElementBuilder {
  final bool isDark;

  _InlineCodeBuilder({required this.isDark});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2E2E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF444444) : const Color(0xFFE5E5E5),
          width: 0.5,
        ),
      ),
      child: Text(
        element.textContent,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFFC7254E), // ChatGPT style pink for light mode, white for dark
        ),
      ),
    );
  }
}

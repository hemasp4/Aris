import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../settings/providers/settings_provider.dart';
import '../../providers/chat_provider.dart';

/// Message bubble widget with markdown and code highlighting
class MessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onRegenerate;

  const MessageBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.onEdit,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final isUser = message.role == 'user';
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: settings.compactMode ? 4 : 8,
        horizontal: settings.compactMode ? 8 : 16,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && settings.showAvatars) ...[
            _buildAvatar(theme, isUser: false),
            const SizedBox(width: 12),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Message content
                Container(
                  padding: EdgeInsets.all(settings.compactMode ? 10 : 14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary
                        : (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isUser || !settings.enableMarkdown)
                        SelectableText(
                          message.content,
                          style: TextStyle(
                            color: isUser ? Colors.white : theme.colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        )
                      else
                        _buildMarkdownContent(context, settings, isDark),
                      
                      if (message.isStreaming) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Generating...',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Timestamp and actions
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (settings.showTimestamps) ...[
                        Text(
                          _formatTime(message.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      
                      // Action buttons (only for completed messages)
                      if (!message.isStreaming) ...[
                        _ActionButton(
                          icon: Icons.copy,
                          tooltip: 'Copy',
                          onPressed: () => _copyToClipboard(context),
                        ),
                        if (isUser) ...[
                          _ActionButton(
                            icon: Icons.edit,
                            tooltip: 'Edit',
                            onPressed: onEdit,
                          ),
                        ] else ...[
                          _ActionButton(
                            icon: Icons.refresh,
                            tooltip: 'Regenerate',
                            onPressed: onRegenerate,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isUser && settings.showAvatars) ...[
            const SizedBox(width: 12),
            _buildAvatar(theme, isUser: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, {required bool isUser}) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser
          ? theme.colorScheme.secondary
          : theme.colorScheme.primary,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context, dynamic settings, bool isDark) {
    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
          height: 1.5,
        ),
        h1: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        h2: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        h3: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        code: TextStyle(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          color: Theme.of(context).colorScheme.primary,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
          ),
        ),
        listBullet: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        tableHead: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        tableBorder: TableBorder.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      builders: {
        'code': settings.enableCodeHighlighting
            ? _CodeBlockBuilder(isDark: isDark)
            : _DefaultCodeBuilder(),
      },
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 14),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  final bool isDark;

  _CodeBlockBuilder({required this.isDark});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;
    final language = element.attributes['class']?.replaceFirst('language-', '') ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with language and copy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Text(
                  language.isNotEmpty ? language : 'code',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const Spacer(),
                Builder(
                  builder: (context) => InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied')),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.copy,
                          size: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Code content
          Padding(
            padding: const EdgeInsets.all(12),
            child: HighlightView(
              code,
              language: language.isNotEmpty ? language : 'plaintext',
              theme: isDark ? draculaTheme : githubTheme,
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultCodeBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        element.textContent,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }
}

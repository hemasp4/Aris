import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';

/// Article preview sheet showing extracted text with external link option
/// 
/// ChatGPT-style article preview:
/// - Header with source name and external link icon (top-right)
/// - Scrollable extracted text content
/// - Opens in-app, not WebView
/// - User can tap external link to open full site
class ArticlePreviewSheet extends StatelessWidget {
  final String title;
  final String domain;
  final String url;
  final String content;
  final String? imageUrl;

  const ArticlePreviewSheet({
    super.key,
    required this.title,
    required this.domain,
    required this.url,
    required this.content,
    this.imageUrl,
  });

  /// Show the article preview as a modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String domain,
    required String url,
    required String content,
    String? imageUrl,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ArticlePreviewSheet(
        title: title,
        domain: domain,
        url: url,
        content: content,
        imageUrl: imageUrl,
      ),
    );
  }

  Future<void> _openExternalLink() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with source and external link
          _buildHeader(context, theme, isDark),

          const Divider(height: 1),

          // Content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero image if available
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    const SizedBox(height: 20),

                  // Title
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Extracted content
                  Text(
                    content.isNotEmpty
                        ? content
                        : 'No content available. Tap the link icon to view the full article.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.7,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Read more button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openExternalLink,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedLinkSquare02,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                      label: const Text('Read full article'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    // Generate badge color based on domain
    final badgeColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    final colorIndex = domain.hashCode.abs() % badgeColors.length;
    final letter = domain.isNotEmpty ? domain[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          // Source icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: badgeColors[colorIndex],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Source name
          Expanded(
            child: Text(
              domain,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // External link button (ChatGPT-style)
          IconButton(
            onPressed: _openExternalLink,
            tooltip: 'Open in browser',
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedLinkSquare02,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),

          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

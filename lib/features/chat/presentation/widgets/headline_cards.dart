import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';

/// Model for a headline card
class HeadlineData {
  final String title;
  final String source;
  final String? imageUrl;
  final String? sourceIconUrl;
  final String? date;
  final String? url;

  const HeadlineData({
    required this.title,
    required this.source,
    this.imageUrl,
    this.sourceIconUrl,
    this.date,
    this.url,
  });
}

/// ChatGPT-style horizontal scrolling headline cards
/// Shows scraped news articles with images, source, title, and date
class HeadlineCards extends StatelessWidget {
  final List<HeadlineData> headlines;
  final Function(HeadlineData)? onTap;

  const HeadlineCards({
    super.key,
    required this.headlines,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (headlines.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: headlines.length,
        itemBuilder: (context, index) {
          final headline = headlines[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < headlines.length - 1 ? 12 : 0,
            ),
            child: _HeadlineCard(
              headline: headline,
              onTap: () => onTap?.call(headline),
            ),
          );
        },
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  final HeadlineData headline;
  final VoidCallback? onTap;

  const _HeadlineCard({
    required this.headline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E5E5),
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (headline.imageUrl != null)
              SizedBox(
                height: 100,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: headline.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 100,
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                child: Center(
                  child: Icon(
                    Icons.article_outlined,
                    color: Colors.grey[600],
                    size: 32,
                  ),
                ),
              ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source row
                    Row(
                      children: [
                        if (headline.sourceIconUrl != null)
                          Container(
                            width: 16,
                            height: 16,
                            margin: const EdgeInsets.only(right: 6),
                            child: CachedNetworkImage(
                              imageUrl: headline.sourceIconUrl!,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) =>
                                  _buildSourceIcon(headline.source, isDark),
                            ),
                          )
                        else
                          _buildSourceIcon(headline.source, isDark),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            headline.source,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Title
                    Expanded(
                      child: Text(
                        headline.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Date
                    if (headline.date != null)
                      Text(
                        headline.date!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceIcon(String source, bool isDark) {
    // Get first letter of source
    final letter = source.isNotEmpty ? source[0].toUpperCase() : '?';
    
    // Generate color based on source name
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    final colorIndex = source.hashCode.abs() % colors.length;
    
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: colors[colorIndex],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Source badge that appears inline with text (e.g., "Ars Technica")
class SourceBadge extends StatelessWidget {
  final String source;
  final String? iconUrl;
  
  const SourceBadge({
    super.key,
    required this.source,
    this.iconUrl,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        source,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.grey[400] : Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

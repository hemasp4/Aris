import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hugeicons/hugeicons.dart';

import 'article_preview_sheet.dart';

/// Model for a headline card
class HeadlineData {
  final String title;
  final String source;
  final String? imageUrl;
  final String? sourceIconUrl;
  final String? date;
  final String? url;
  final String? snippet;

  const HeadlineData({
    required this.title,
    required this.source,
    this.imageUrl,
    this.sourceIconUrl,
    this.date,
    this.url,
    this.snippet,
  });
}

/// ChatGPT-EXACT Horizontal Scrolling Headline Cards
/// Matches the reference images:
/// - Horizontal scroll with snap behavior
/// - Card: Image top (120dp) + Source badge + Title (2 lines) + Date
/// - Dark theme styling with proper shadows
class HeadlineCards extends StatelessWidget {
  final List<HeadlineData> headlines;
  final Function(HeadlineData)? onTap;
  final int maxCards;
  final EdgeInsetsGeometry? padding;

  const HeadlineCards({
    super.key,
    required this.headlines,
    this.onTap,
    this.maxCards = 10,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (headlines.isEmpty) return const SizedBox.shrink();

    final displayHeadlines = headlines.take(maxCards).toList();

    return SizedBox(
      height: 220, // Fixed height for horizontal scroll cards
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: displayHeadlines.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index < displayHeadlines.length - 1 ? 12 : 0,
            ),
            child: _ChatGPTHeadlineCard(
              headline: displayHeadlines[index],
              onTap: () => onTap?.call(displayHeadlines[index]),
            ),
          );
        },
      ),
    );
  }
}

/// Individual ChatGPT-style headline card
class _ChatGPTHeadlineCard extends StatefulWidget {
  final HeadlineData headline;
  final VoidCallback? onTap;

  const _ChatGPTHeadlineCard({
    required this.headline,
    this.onTap,
  });

  @override
  State<_ChatGPTHeadlineCard> createState() => _ChatGPTHeadlineCardState();
}

class _ChatGPTHeadlineCardState extends State<_ChatGPTHeadlineCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: 200, // Card width for horizontal scroll
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark 
                    ? const Color(0xFF2E2E2E) 
                    : const Color(0xFFE5E5E5),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image (120dp height)
                _buildImage(isDark),
                
                // Content area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Source row with icon badge
                        _buildSourceBadge(isDark),
                        const SizedBox(height: 8),
                        
                        // Title (2 lines max)
                        Expanded(
                          child: Text(
                            widget.headline.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Date
                        if (widget.headline.date != null)
                          Text(
                            widget.headline.date!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          )
                        else
                          Text(
                            'Yesterday', // Default fallback
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
        ),
      ),
    );
  }

  Widget _buildImage(bool isDark) {
    if (widget.headline.imageUrl != null && 
        widget.headline.imageUrl!.isNotEmpty) {
      return SizedBox(
        height: 120,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: widget.headline.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildImagePlaceholder(isDark),
          errorWidget: (context, url, error) => _buildImagePlaceholder(isDark),
        ),
      );
    }
    return _buildImagePlaceholder(isDark);
  }

  Widget _buildImagePlaceholder(bool isDark) {
    // Generate gradient color based on source name
    final colors = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
    ];
    final colorIndex = widget.headline.source.hashCode.abs() % colors.length;
    
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors[colorIndex],
        ),
      ),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedNews,
          color: Colors.white.withValues(alpha: 0.8),
          size: 36,
        ),
      ),
    );
  }

  Widget _buildSourceBadge(bool isDark) {
    // Generate badge color based on source
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
    final colorIndex = widget.headline.source.hashCode.abs() % badgeColors.length;
    final letter = widget.headline.source.isNotEmpty 
        ? widget.headline.source[0].toUpperCase() 
        : '?';
    
    return Row(
      children: [
        // Icon badge (letter-based fallback - no CORS issues)
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: badgeColors[colorIndex],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              letter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        
        // Source name
        Expanded(
          child: Text(
            widget.headline.source,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[isDark ? 400 : 600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
    
    // Generate badge color
    final badgeColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    final colorIndex = source.hashCode.abs() % badgeColors.length;
    final letter = source.isNotEmpty ? source[0].toUpperCase() : '?';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: badgeColors[colorIndex],
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            source,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

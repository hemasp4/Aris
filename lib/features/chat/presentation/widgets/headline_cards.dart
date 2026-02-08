import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/constants/api_constants.dart';
import 'shimmer_loading.dart';

/// Helper to proxy external images through our backend to avoid CORS issues
String _proxyImageUrl(String? originalUrl) {
  if (originalUrl == null || originalUrl.isEmpty) return '';
  if (!originalUrl.startsWith('http')) return originalUrl;
  // Route through our backend proxy
  final encodedUrl = Uri.encodeComponent(originalUrl);
  return '${ApiConstants.baseUrl}/proxy/image?url=$encodedUrl';
}


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
    // Filter for valid cards with images (Strict Mode)
    final validHeadlines = headlines.where((h) => 
      h.imageUrl != null && 
      h.imageUrl!.isNotEmpty && 
      h.imageUrl != 'null' &&
      h.imageUrl!.startsWith('http')
    ).toList();

    // MATCHING CHATGPT: If fewer than 2 valid cards with images, do not show the section at all.
    // Single cards look awkward in a horizontal list.
    if (validHeadlines.length < 2) return const SizedBox.shrink();

    final displayHeadlines = validHeadlines.take(maxCards).toList();

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
      // Use proxy to avoid CORS issues with external images
      final proxiedUrl = _proxyImageUrl(widget.headline.imageUrl);
      return SizedBox(
        height: 120,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: proxiedUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildImagePlaceholder(isDark),
          errorWidget: (context, url, error) => _buildImagePlaceholder(isDark),
        ),
      );
    }
    return _buildImagePlaceholder(isDark);
  }

  Widget _buildImagePlaceholder(bool isDark) {
    // ChatGPT-style shimmer loading animation
    return const ShimmerLoading(
      height: 120,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
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
        // Icon badge (Favicon or fallback)
        if (widget.headline.sourceIconUrl != null && widget.headline.sourceIconUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: _proxyImageUrl(widget.headline.sourceIconUrl),
            width: 20,
            height: 20,
            imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
            placeholder: (context, url) => _buildLetterFallback(badgeColors, colorIndex, letter),
            errorWidget: (context, url, error) => _buildLetterFallback(badgeColors, colorIndex, letter),
          )
        else
          _buildLetterFallback(badgeColors, colorIndex, letter),
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

  Widget _buildLetterFallback(List<Color> badgeColors, int colorIndex, String letter) {
    return Container(
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

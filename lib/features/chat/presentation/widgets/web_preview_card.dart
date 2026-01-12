import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/scraping_service.dart';

/// Widget to display scraped web content with images
class WebPreviewCard extends StatelessWidget {
  final ScrapeResult result;
  final VoidCallback? onTap;
  final bool showImages;
  final bool compact;

  const WebPreviewCard({
    super.key,
    required this.result,
    this.onTap,
    this.showImages = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (!result.success) {
      return _buildErrorCard(context);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => _openUrl(result.url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured image
            if (showImages && result.images.isNotEmpty)
              _buildFeaturedImage(result.images.first),
            
            // Content
            Padding(
              padding: EdgeInsets.all(compact ? 8 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    result.title.isNotEmpty ? result.title : 'Untitled',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // URL
                  Text(
                    _formatUrl(result.url),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (!compact) ...[
                    const SizedBox(height: 8),
                    
                    // Summary or content preview
                    Text(
                      result.summary ?? _getPreview(result.content),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedImage(String imageUrl) {
    return SizedBox(
      height: compact ? 80 : 140,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.image, size: 40, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.error ?? 'Failed to load content',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url;
    }
  }

  String _getPreview(String content) {
    final clean = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.length > 200 ? '${clean.substring(0, 200)}...' : clean;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Grid of scraped web results
class WebResultsGrid extends StatelessWidget {
  final List<ScrapeResult> results;
  final Function(ScrapeResult)? onResultTap;
  final bool loading;

  const WebResultsGrid({
    super.key,
    required this.results,
    this.onResultTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No results found'),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return WebPreviewCard(
          result: result,
          compact: true,
          onTap: onResultTap != null ? () => onResultTap!(result) : null,
        );
      },
    );
  }
}

/// Image gallery from scraped content
class ScrapedImageGallery extends StatelessWidget {
  final List<String> images;
  final Function(String)? onImageTap;
  final int maxImages;

  const ScrapedImageGallery({
    super.key,
    required this.images,
    this.onImageTap,
    this.maxImages = 6,
  });

  @override
  Widget build(BuildContext context) {
    final displayImages = images.take(maxImages).toList();
    final remaining = images.length - maxImages;

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayImages.length + (remaining > 0 ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayImages.length && remaining > 0) {
            return _buildMoreIndicator(context, remaining);
          }
          
          return _buildImageThumbnail(displayImages[index]);
        },
      ),
    );
  }

  Widget _buildImageThumbnail(String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onImageTap?.call(url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: url,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 80,
              height: 80,
              color: Colors.grey[200],
            ),
            errorWidget: (_, __, ___) => Container(
              width: 80,
              height: 80,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, size: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreIndicator(BuildContext context, int count) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

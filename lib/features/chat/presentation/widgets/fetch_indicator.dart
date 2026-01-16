import 'dart:async';
import 'package:flutter/material.dart';

/// ChatGPT-style thinking indicator
/// A single blinking dot that indicates the AI is processing/thinking
class ThinkingIndicator extends StatefulWidget {
  final Color? color;
  final double size;

  const ThinkingIndicator({
    super.key,
    this.color,
    this.size = 8,
  });

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    
    // Breathing/pulse animation
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = widget.color ?? (isDark ? Colors.white : Colors.black);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: dotColor.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// ChatGPT-style "Searching..." text indicator
class SearchingIndicator extends StatefulWidget {
  final String text;
  final Color? color;

  const SearchingIndicator({
    super.key,
    this.text = 'Searching...',
    this.color,
  });

  @override
  State<SearchingIndicator> createState() => _SearchingIndicatorState();
}

class _SearchingIndicatorState extends State<SearchingIndicator> {
  int _dotCount = 0;
  Timer? _timer;
  
  final List<String> _searchTexts = [
    'Searching the web',
    'Fetching trusted sources',
    'Gathering information',
  ];
  int _textIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _dotCount = (_dotCount + 1) % 4;
        if (_dotCount == 0) {
          _textIndex = (_textIndex + 1) % _searchTexts.length;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = widget.color ?? (isDark ? Colors.grey[400] : Colors.grey[600]);
    final dots = '.' * _dotCount;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ThinkingIndicator(size: 6),
        const SizedBox(width: 12),
        Text(
          '${_searchTexts[_textIndex]}$dots',
          style: TextStyle(
            fontSize: 14,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

/// Combined fetch indicator that shows thinking/searching states
class FetchIndicator extends StatelessWidget {
  final bool isThinking;
  final bool isSearching;
  final bool isScraping;
  final List<String> scrapingSources;

  const FetchIndicator({
    super.key,
    this.isThinking = false,
    this.isSearching = false,
    this.isScraping = false,
    this.scrapingSources = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (!isThinking && !isSearching && !isScraping) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isThinking && !isSearching && !isScraping)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ThinkingIndicator(),
                ],
              ),
            
            if (isSearching || isScraping)
              const SearchingIndicator(),
            
            if (isScraping && scrapingSources.isNotEmpty) ...[
              const SizedBox(height: 12),
              SourceIconsRow(sources: scrapingSources),
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple placeholder for source icons - will be enhanced
class SourceIconsRow extends StatelessWidget {
  final List<String> sources;
  
  const SourceIconsRow({super.key, required this.sources});
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sources.map((source) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _formatSourceName(source),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  String _formatSourceName(String url) {
    // Extract domain name from URL
    try {
      final uri = Uri.parse(url);
      String host = uri.host;
      // Remove www. prefix
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      // Capitalize first letter
      return host.split('.').first.replaceFirst(
        host[0],
        host[0].toUpperCase(),
      );
    } catch (_) {
      return url;
    }
  }
}

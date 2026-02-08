import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class ResearchSourcesSheet extends StatelessWidget {
  final List<Map<String, dynamic>> sources; // {title, url, snippet, sourceName}

  const ResearchSourcesSheet({super.key, required this.sources});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // De-duplicate sources by URL
    final uniqueSources = <String, Map<String, dynamic>>{};
    for (var s in sources) {
      if (!uniqueSources.containsKey(s['url'])) {
        uniqueSources[s['url']] = s;
      }
    }
    final sourceList = uniqueSources.values.toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171717) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Citations',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${sourceList.length} sources',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 0.5),
          
          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: sourceList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final source = sourceList[index];
                final url = source['url'] as String;
                final title = source['title'] as String? ?? 'Unknown Source';
                // Extract domain
                final uri = Uri.tryParse(url);
                final domain = uri?.host.replaceFirst('www.', '') ?? url;
                
                return InkWell(
                  onTap: () {
                    // TODO: Open URL
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Favicon Placeholder or specific logic
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            domain.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              domain,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (source['snippet'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                source['snippet'],
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                  height: 1.4,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

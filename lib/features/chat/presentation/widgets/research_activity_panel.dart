import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class ResearchActivityPanel extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  final VoidCallback onClose;

  const ResearchActivityPanel({
    super.key,
    required this.logs,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedGlobalSearch,
                      size: 20,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Research Activity',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: onClose,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          
          // Logs List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final state = log['state'] as String? ?? 'INFO';
                final message = log['message'] as String? ?? '';
                final data = log['data'] as Map<String, dynamic>?;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStateIcon(state, isDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? Colors.grey[300] : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            if (data != null && data.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: _buildDataPreview(data, isDark),
                              ),
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

  Widget _buildStateIcon(String state, bool isDark) {
    dynamic icon; // Changed to dynamic because HugeIcons are Lists
    Color color;

    switch (state) {
      case 'SEARCHING':
        icon = HugeIcons.strokeRoundedSearch01;
        color = Colors.blue;
        break;
      case 'READING':
        icon = HugeIcons.strokeRoundedBookOpen01;
        color = Colors.orange;
        break;
      case 'ANALYZING':
        icon = HugeIcons.strokeRoundedBrain02;
        color = Colors.purple;
        break;
      case 'DONE':
        icon = HugeIcons.strokeRoundedTick02;
        color = Colors.green;
        break;
      default:
        icon = HugeIcons.strokeRoundedInformationCircle;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: HugeIcon(icon: icon, size: 14, color: color),
    );
  }

  Widget _buildDataPreview(Map<String, dynamic> data, bool isDark) {
    if (data.containsKey('url')) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            HugeIcon(icon: HugeIcons.strokeRoundedLinkSquare01, 
              size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                data['title']?.toString() ?? data['url'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

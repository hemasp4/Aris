import 'package:flutter/material.dart';

import 'package:hugeicons/hugeicons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/chat_provider.dart';

class ResearchProgressCapsule extends StatefulWidget {
  final ResearchProgress progress;
  final VoidCallback onTap;

  const ResearchProgressCapsule({
    super.key,
    required this.progress,
    required this.onTap,
  });

  @override
  State<ResearchProgressCapsule> createState() => _ResearchProgressCapsuleState();
}

class _ResearchProgressCapsuleState extends State<ResearchProgressCapsule> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buildIcon() {
      switch (widget.progress.currentState) {
        case 'SEARCHING':
          return HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: AppColors.accent, size: 16);
        case 'READING':
          return HugeIcon(icon: HugeIcons.strokeRoundedBookOpen01, color: AppColors.accent, size: 16);
        case 'ANALYZING':
          return HugeIcon(icon: HugeIcons.strokeRoundedBrain02, color: AppColors.accent, size: 16);
        case 'SYNTHESIZING':
          return HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: AppColors.accent, size: 16);
        case 'DONE':
          return HugeIcon(icon: HugeIcons.strokeRoundedTick02, color: AppColors.accent, size: 16);
        default:
          return HugeIcon(icon: HugeIcons.strokeRoundedLoading02, color: AppColors.accent, size: 16);
      }
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                // Pulse border opacity
                color: AppColors.accent.withValues(alpha: 0.2 + (_controller.value * 0.3)),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulse Icon Container
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1 + (_controller.value * 0.15)),
                      shape: BoxShape.circle,
                    ),
                    child: buildIcon(),
                ),
                const SizedBox(width: 12),
                
                // Text Column
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatState(widget.progress.currentState),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (widget.progress.currentMessage.isNotEmpty)
                        Text(
                          widget.progress.currentMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12, // Increased legibility
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.2,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Animated Chevron
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  size: 16,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatState(String state) {
    if (state.isEmpty) return 'Thinking...';
    // Capitalize first letter, lower rest
    return state[0].toUpperCase() + state.substring(1).toLowerCase();
  }
}

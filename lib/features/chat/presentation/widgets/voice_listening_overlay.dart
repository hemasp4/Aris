import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

class VoiceListeningOverlay extends StatelessWidget {
  final String text;
  final bool isThinking;

  const VoiceListeningOverlay({
    super.key,
    required this.text,
    this.isThinking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // Semi-transparent background (Light/Dark adaptive)
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xB3303030) // Dark: rgba(48, 47, 47, 0.7)
            : const Color(0xB3F5F5F5), // Light: rgba(205, 199, 199, 0.7)
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        text.isEmpty ? (isThinking ? "Thinking..." : "Listening...") : text,
        style: TextStyle(
          color: AppColors.secondaryText,
          fontSize: 16,
          height: 1.4,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      )
      .animate(
        onPlay: (controller) => controller.repeat(reverse: true),
      )
      .fade(
        duration: const Duration(milliseconds: 1000), 
        begin: 0.6, 
        end: 1.0,
        curve: Curves.easeInOut,
      ), // Breathing opacity
    );
  }
}

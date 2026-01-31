import 'package:flutter/material.dart';
import 'package:aris_chatbot/core/theme/app_colors.dart';

class CustomModal extends StatelessWidget {
  final String title;
  final String content;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const CustomModal({
    Key? key,
    required this.title,
    required this.content,
    this.cancelLabel = 'Cancel',
    this.confirmLabel = 'Confirm',
    required this.onConfirm,
    this.isDestructive = false,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Confirm',
    bool isDestructive = false,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5), // Image 0: Dark backdrop
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              backgroundColor: const Color(0xFF2E2E2E), // Image 0: surfaceElevated
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomModal(
                title: title,
                content: content,
                onConfirm: onConfirm,
                cancelLabel: cancelLabel,
                confirmLabel: confirmLabel,
                isDestructive: isDestructive,
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18, // Image 0: Large title
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8), // Image 0: Muted content
              fontSize: 14,
              height: 1.5,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.6), // Cancel is grey
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(cancelLabel),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  onConfirm();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDestructive ? AppColors.danger : AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

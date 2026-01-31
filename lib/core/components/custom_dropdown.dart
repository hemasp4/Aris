import 'package:flutter/material.dart';
import 'package:aris_chatbot/core/theme/app_colors.dart';

class CustomDropdownMenu extends StatelessWidget {
  final List<CustomDropdownItem> items;
  final VoidCallback? onDismiss;

  const CustomDropdownMenu({
    Key? key,
    required this.items,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark grey bg from Image 1
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  onDismiss?.call();
                  item.onTap();
                },
                hoverColor: Colors.white.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: item.isDestructive 
                            ? AppColors.danger 
                            : Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: item.isDestructive 
                                ? AppColors.danger 
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class CustomDropdownItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  CustomDropdownItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// ChatGPT-style Temporary Chat info screen
class TemporaryChatInfoScreen extends StatelessWidget {
  final VoidCallback? onContinue;

  const TemporaryChatInfoScreen({super.key, this.onContinue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 32, 24, bottomPadding + 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Temporary chat',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Info items (list style for light, cards for dark - matching ChatGPT)
                        if (isDark) ...[
                          // Dark mode: Rounded card style
                          _buildInfoCard(
                            isDark: isDark,
                            icon: HugeIcons.strokeRoundedClock01,
                            title: 'Not in history',
                            description: 'Temporary chats won\'t appear in your history. For safety purposes, we may keep a copy of your chat for up to 30 days.',
                          ),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            isDark: isDark,
                            icon: HugeIcons.strokeRoundedFile02,
                            title: 'No memory',
                            description: 'Aris won\'t use or create memories in Temporary Chats. If you have Custom Instructions, they\'ll still be followed.',
                          ),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            isDark: isDark,
                            icon: HugeIcons.strokeRoundedUserBlock01,
                            title: 'No model training',
                            description: 'Temporary Chats won\'t be used to improve our models.',
                          ),
                        ] else ...[
                          // Light mode: Simple list with dividers
                          _buildInfoListItem(
                            icon: HugeIcons.strokeRoundedClock01,
                            title: 'Not in history',
                            description: 'Temporary chats won\'t appear in your history. For safety purposes, we may keep a copy of your chat for up to 30 days.',
                          ),
                          const Divider(height: 32),
                          _buildInfoListItem(
                            icon: HugeIcons.strokeRoundedFile02,
                            title: 'No memory',
                            description: 'Aris won\'t use or create memories in Temporary Chats. If you have Custom Instructions, they\'ll still be followed.',
                          ),
                          const Divider(height: 32),
                          _buildInfoListItem(
                            icon: HugeIcons.strokeRoundedUserBlock01,
                            title: 'No model training',
                            description: 'Temporary Chats won\'t be used to improve our models.',
                          ),
                        ],
                        
                        const Spacer(),
                        
                        const SizedBox(height: 24),
                        
                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onContinue?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Light mode: Simple list item with icon
  Widget _buildInfoListItem({
    required dynamic icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HugeIcon(
          icon: icon,
          size: 24,
          color: Colors.black87,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required dynamic icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: icon,
            size: 24,
            color: isDark ? Colors.white : Colors.black,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

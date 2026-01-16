import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/settings_widgets.dart';

/// About Settings Screen - ChatGPT exact
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'About',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App version
            SettingsListTile(
              icon: Icons.phone_android,
              title: 'App version',
              subtitle: '1.0.0+1',
              onTap: () {},
              trailing: const SizedBox.shrink(),
            ),
            
            const Divider(color: AppColors.borderLight, height: 1),
            
            // Terms of Service
            SettingsListTile(
              icon: Icons.article_outlined,
              title: 'Terms of Service',
              onTap: () => _openUrl(context, 'https://example.com/terms'),
            ),
            
            const Divider(color: AppColors.borderLight, height: 1),
            
            // Privacy Policy
            SettingsListTile(
              icon: Icons.lock_outline,
              title: 'Privacy Policy',
              onTap: () => _openUrl(context, 'https://example.com/privacy'),
            ),
            
            const Divider(color: AppColors.borderLight, height: 1),
            
            // Open source licenses
            SettingsListTile(
              icon: Icons.gavel_outlined,
              title: 'Open source licenses',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OpenSourceLicensesScreen()),
              ),
            ),
            
            const Divider(color: AppColors.borderLight, height: 1),
            
            // Help & Support
            SettingsListTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => _openUrl(context, 'https://example.com/help'),
            ),
            
            const Divider(color: AppColors.borderLight, height: 1),
            
            // Send feedback
            SettingsListTile(
              icon: Icons.chat_bubble_outline,
              title: 'Send feedback',
              onTap: () => _showFeedbackDialog(context),
            ),
            
            const SizedBox(height: 32),
            
            // App logo and info
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aris AI',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Powered by Local LLM',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUrl(BuildContext context, String url) {
    // TODO: Use url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $url'),
        backgroundColor: AppColors.settingsCard,
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Send Feedback',
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tell us what you think...',
            hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.settingsCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: AppColors.settingsCard,
                ),
              );
            },
            child: Text('Send', style: GoogleFonts.inter(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

/// Open Source Licenses Screen
class OpenSourceLicensesScreen extends StatelessWidget {
  const OpenSourceLicensesScreen({super.key});

  // Sample licenses data
  static final List<Map<String, String>> _licenses = [
    {'name': 'flutter_riverpod', 'version': '2.4.10', 'author': 'Remi Rousselet', 'license': 'MIT License'},
    {'name': 'go_router', 'version': '13.2.0', 'author': 'Flutter Team', 'license': 'BSD License'},
    {'name': 'google_fonts', 'version': '6.1.0', 'author': 'Google', 'license': 'Apache License 2.0'},
    {'name': 'flutter_markdown', 'version': '0.6.22', 'author': 'Flutter Team', 'license': 'BSD License'},
    {'name': 'dio', 'version': '5.4.1', 'author': 'Flutter China', 'license': 'MIT License'},
    {'name': 'hive', 'version': '2.2.3', 'author': 'Simon Leier', 'license': 'Apache License 2.0'},
    {'name': 'flutter_secure_storage', 'version': '9.0.0', 'author': 'German Saprykin', 'license': 'BSD License'},
    {'name': 'image_picker', 'version': '1.0.7', 'author': 'Flutter Team', 'license': 'Apache License 2.0'},
    {'name': 'file_picker', 'version': '8.1.3', 'author': 'Miguel Ruivo', 'license': 'MIT License'},
    {'name': 'lottie', 'version': '3.1.0', 'author': 'xvrh', 'license': 'MIT License'},
    {'name': 'flutter_animate', 'version': '4.5.0', 'author': 'Grant Skinner', 'license': 'MIT License'},
    {'name': 'uuid', 'version': '4.3.3', 'author': 'Yulian Kuncheff', 'license': 'MIT License'},
    {'name': 'intl', 'version': '0.19.0', 'author': 'Dart Team', 'license': 'BSD License'},
    {'name': 'url_launcher', 'version': '6.2.4', 'author': 'Flutter Team', 'license': 'BSD License'},
    {'name': 'share_plus', 'version': '10.0.0', 'author': 'Flutter Community', 'license': 'BSD License'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Open source licenses',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _licenses.length,
        itemBuilder: (context, index) {
          final license = _licenses[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.settingsCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        license['name']!,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      license['version']!,
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  license['author']!,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    license['license']!,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

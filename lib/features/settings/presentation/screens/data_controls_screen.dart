import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/settings_widgets.dart';

/// Data Controls Settings Screen - ChatGPT exact
class DataControlsScreen extends ConsumerStatefulWidget {
  const DataControlsScreen({super.key});

  @override
  ConsumerState<DataControlsScreen> createState() => _DataControlsScreenState();
}

class _DataControlsScreenState extends ConsumerState<DataControlsScreen> {
  bool _improveModel = false;
  bool _includeAudioRecordings = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Data controls',
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
            // Improve model toggle
            SettingsToggleCard(
              title: 'Improve the model for everyone',
              value: _improveModel,
              onChanged: (value) => setState(() => _improveModel = value),
            ),
            
            const SizedBox(height: 8),
            
            // Description with learn more link
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Allow your content to be used to improve our models for you and other users. We take steps to protect your privacy. ',
                    ),
                    TextSpan(
                      text: 'Learn more',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Export data button
            SettingsActionButton(
              label: 'Export Data',
              icon: Icons.download_outlined,
              onTap: () => _showExportDialog(),
            ),
            
            const SizedBox(height: 12),
            
            // Delete account button
            SettingsActionButton(
              label: 'Delete Aris account',
              icon: Icons.delete_outline,
              isDangerous: true,
              onTap: () => _showDeleteAccountDialog(),
            ),
            
            const SizedBox(height: 32),
            
            // Voice mode section
            const SettingsSectionHeader(title: 'Voice mode'),
            
            SettingsToggleCard(
              title: 'Include your audio recordings',
              value: _includeAudioRecordings,
              onChanged: (value) => setState(() => _includeAudioRecordings = value),
            ),
            
            const SizedBox(height: 8),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Include your audio recordings from voice mode to train our models. Transcripts and other files are covered by Improve the model for everyone. ',
                    ),
                    TextSpan(
                      text: 'Learn more',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Chat history section
            const SettingsSectionHeader(title: 'Chat history'),
            
            SettingsActionButton(
              label: 'View archived chats',
              icon: Icons.archive_outlined,
              onTap: () {},
            ),
            
            const SizedBox(height: 12),
            
            SettingsActionButton(
              label: 'Archive chat history',
              icon: Icons.inventory_2_outlined,
              onTap: () => _showArchiveDialog(),
            ),
            
            const SizedBox(height: 12),
            
            SettingsActionButton(
              label: 'Clear chat history',
              icon: Icons.delete_sweep_outlined,
              isDangerous: true,
              onTap: () => _showClearHistoryDialog(),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Export Data',
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'We\'ll prepare your data and send you a download link via email. This may take a few minutes.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
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
                  content: Text('Export requested. Check your email soon.'),
                  backgroundColor: AppColors.settingsCard,
                ),
              );
            },
            child: Text('Export', style: GoogleFonts.inter(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Account',
          style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This action cannot be undone. All your data, chats, and settings will be permanently deleted.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
            },
            child: Text('Delete', style: GoogleFonts.inter(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showArchiveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Archive Chat History',
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Your chats will be archived and hidden from the sidebar. You can view them anytime in archived chats.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
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
                  content: Text('Chats archived successfully.'),
                  backgroundColor: AppColors.settingsCard,
                ),
              );
            },
            child: Text('Archive', style: GoogleFonts.inter(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Chat History',
          style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will permanently delete all your chat history. This action cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
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
                  content: Text('Chat history cleared.'),
                  backgroundColor: AppColors.settingsCard,
                ),
              );
            },
            child: Text('Clear', style: GoogleFonts.inter(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

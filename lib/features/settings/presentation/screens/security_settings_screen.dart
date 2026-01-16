import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/settings_widgets.dart';

/// Security Settings Screen - ChatGPT exact
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  bool _mfaEnabled = false;
  bool _appLock = true;
  bool _biometricAuth = true;
  String _autoLockTimeout = '5 minutes';

  final List<String> _timeoutOptions = [
    'Immediately',
    '1 minute',
    '5 minutes',
    '15 minutes',
    '30 minutes',
    'Never',
  ];

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
          'Security',
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
            // Multi-factor authentication
            Container(
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
                          'Multi-factor authentication',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch(
                        value: _mfaEnabled,
                        onChanged: (value) => setState(() => _mfaEnabled = value),
                        activeColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                        inactiveThumbColor: AppColors.textMuted,
                        inactiveTrackColor: AppColors.toggleTrackOff,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Require an extra security challenge when logging in. If you are unable to pass this challenge, you will have the option to recover your account via email.',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App Lock
            SettingsToggleCard(
              title: 'App lock',
              description: 'Require authentication to open the app.',
              value: _appLock,
              onChanged: (value) => setState(() => _appLock = value),
            ),
            
            const SizedBox(height: 12),
            
            // Biometric authentication
            SettingsToggleCard(
              title: 'Biometric authentication',
              description: 'Use fingerprint or face recognition.',
              value: _biometricAuth,
              onChanged: (value) {
                if (_appLock) setState(() => _biometricAuth = value);
              },
              enabled: _appLock,
            ),
            
            const SizedBox(height: 12),
            
            // Auto-lock timeout
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _appLock ? () => _showTimeoutPicker() : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.settingsCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Auto-lock after inactivity',
                          style: GoogleFonts.inter(
                            color: _appLock ? AppColors.textPrimary : AppColors.textMuted,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Text(
                        _autoLockTimeout,
                        style: GoogleFonts.inter(
                          color: _appLock ? AppColors.textSecondary : AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: _appLock ? AppColors.textMuted : AppColors.textMuted.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Personal Space security link
            SettingsActionButton(
              label: 'Personal Space security',
              icon: Icons.lock_outline,
              onTap: () => context.push('/settings/personal-space-security'),
            ),
            
            const SizedBox(height: 32),
            
            // Danger zone
            const SettingsSectionHeader(title: 'Danger zone'),
            
            SettingsActionButton(
              label: 'Change password',
              icon: Icons.key_outlined,
              onTap: () => _showChangePasswordDialog(),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeoutPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Auto-lock timeout',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ..._timeoutOptions.map((option) => ListTile(
              title: Text(
                option,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
              ),
              trailing: option == _autoLockTimeout
                  ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                  : null,
              onTap: () {
                setState(() => _autoLockTimeout = option);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Change Password',
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current password',
                labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.settingsCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.inter(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New password',
                labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.settingsCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.inter(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.settingsCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.inter(color: AppColors.textPrimary),
            ),
          ],
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
                  content: Text('Password changed successfully.'),
                  backgroundColor: AppColors.settingsCard,
                ),
              );
            },
            child: Text('Change', style: GoogleFonts.inter(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

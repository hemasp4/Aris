import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

/// ChatGPT-exact settings screen matching reference images
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final _ = ref.watch(settingsProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundMain,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundMain,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => context.go('/chat'),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: AppColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Header
            _buildUserProfileHeader(user),
            
            const SizedBox(height: 32),
            
            // My ChatGPT Section
            _buildSectionHeader('My Aris'),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.face_outlined,
                title: 'Personalization',
                onTap: () => context.push('/settings/personalization'),
              ),
              _buildSettingsTile(
                icon: Icons.apps_outlined,
                title: 'Apps',
                onTap: () {},
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Account Section
            _buildSectionHeader('Account'),
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.folder_outlined,
                title: 'Workspace',
                subtitle: 'Personal',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.star_border_outlined,
                title: 'Upgrade to Plus',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.add_box_outlined,
                title: 'Subscription',
                subtitle: 'Go',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.mail_outline,
                title: 'Email',
                subtitle: user?.email ?? 'Not set',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.phone_outlined,
                title: 'Phone number',
                subtitle: '+916379922559',
                onTap: () {},
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Appearance Section
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.brightness_6_outlined,
                title: 'Appearance',
                subtitle: 'System (Default)',
                onTap: () => _showAppearanceDialog(),
              ),
              _buildSettingsTile(
                icon: Icons.palette_outlined,
                title: 'Accent color',
                subtitle: 'Default',
                trailing: Icon(Icons.keyboard_arrow_down, color: AppColors.secondaryText),
                onTap: () => _showAccentColorDialog(),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Other Settings Section
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.settings_outlined,
                title: 'General',
                onTap: () => context.push('/settings/general'),
              ),
              _buildSettingsTile(
                icon: Icons.graphic_eq_outlined,
                title: 'Voice',
                onTap: () => context.push('/settings/speech'),
              ),
              _buildSettingsTile(
                icon: Icons.tune_outlined,
                title: 'Data controls',
                onTap: () => context.push('/settings/data-controls'),
              ),
              _buildSettingsTile(
                icon: Icons.security_outlined,
                title: 'Security',
                onTap: () => context.push('/settings/security'),
              ),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () => context.push('/settings/about'),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.settingsCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.logout, color: AppColors.danger),
                  title: Text(
                    'Log out',
                    style: GoogleFonts.inter(color: AppColors.danger),
                  ),
                  onTap: () => _showLogoutDialog(),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileHeader(User? user) {
    final initials = user?.username != null && user!.username.length >= 2
        ? user.username.substring(0, 2).toUpperCase()
        : 'U';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Orange circular avatar with initials
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.avatarOrange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // User display name
          Text(
            user?.username ?? 'User',
            style: GoogleFonts.inter(
              color: AppColors.primaryText,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Username/email
          Text(
            user?.email?.split('@').first ?? user?.username ?? '',
            style: GoogleFonts.inter(
              color: AppColors.secondaryText,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Edit profile button
          OutlinedButton(
            onPressed: () => _showEditProfileDialog(user),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryText,
              side: BorderSide(color: AppColors.borderSubtle),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Edit profile',
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: AppColors.secondaryText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.settingsCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                color: AppColors.borderSubtle,
                indent: 56,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryText, size: 22),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: AppColors.primaryText,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                color: AppColors.secondaryText,
                fontSize: 13,
              ),
            )
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: AppColors.secondaryText, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  void _showEditProfileDialog(User? user) {
    final nameController = TextEditingController(text: user?.username ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Profile', style: GoogleFonts.inter(color: AppColors.primaryText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.avatarOrange,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user?.username.substring(0, 2).toUpperCase() ?? 'U',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: GoogleFonts.inter(color: AppColors.primaryText),
              decoration: InputDecoration(
                labelText: 'Display name',
                labelStyle: GoogleFonts.inter(color: AppColors.secondaryText),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Save', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  void _showAppearanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Appearance', style: GoogleFonts.inter(color: AppColors.primaryText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAppearanceOption('System (Default)', true),
            _buildAppearanceOption('Light', false),
            _buildAppearanceOption('Dark', false),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceOption(String label, bool isSelected) {
    return ListTile(
      title: Text(label, style: GoogleFonts.inter(color: AppColors.primaryText)),
      trailing: isSelected
          ? Icon(Icons.check, color: AppColors.accent)
          : null,
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  void _showAccentColorDialog() {
    final colors = [
      ('Default', AppColors.primary),
      ('Blue', Colors.blue),
      ('Purple', Colors.purple),
      ('Pink', Colors.pink),
      ('Orange', Colors.orange),
      ('Red', Colors.red),
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Accent Color', style: GoogleFonts.inter(color: AppColors.primaryText)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.$2,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log out', style: GoogleFonts.inter(color: AppColors.primaryText)),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.inter(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: Text('Log out', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

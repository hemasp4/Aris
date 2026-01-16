import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/settings_widgets.dart';

/// General Settings Screen - ChatGPT exact
class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen> {
  String _language = 'English';
  String _appLanguage = 'System default';
  bool _autoUpdateModels = true;

  final List<String> _languages = [
    'System default',
    'English',
    'Español',
    'Français',
    'Deutsch',
    '中文',
    '日本語',
    '한국어',
    'العربية',
    'हिन्दी',
    'Português',
    'Русский',
    'Italiano',
    'Nederlands',
    'Polski',
    'Türkçe',
    'Tiếng Việt',
    'ไทย',
    'Bahasa Indonesia',
    'Bahasa Melayu',
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
          'General',
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
            // Language
            SettingsListTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: _language,
              onTap: () => _showLanguagePicker(),
            ),
            
            const Divider(color: AppColors.borderLight, height: 1),
            
            // App language
            SettingsListTile(
              icon: Icons.phone_android,
              title: 'App language',
              subtitle: _appLanguage,
              onTap: () => _showAppLanguagePicker(),
            ),
            
            const Divider(color: AppColors.borderLight, height: 1),
            
            // Notifications
            SettingsListTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () => context.push('/settings/notifications'),
            ),
            
            const Divider(color: AppColors.borderLight, height: 1),
            
            // Storage
            SettingsListTile(
              icon: Icons.storage_outlined,
              title: 'Storage',
              onTap: () => context.push('/settings/storage'),
            ),
            
            const SizedBox(height: 24),
            
            // Auto-update models
            SettingsToggleCard(
              title: 'Auto-update models',
              description: 'Automatically download model updates when available.',
              value: _autoUpdateModels,
              onChanged: (value) => setState(() => _autoUpdateModels = value),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Language',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  final isSelected = lang == _language;
                  return ListTile(
                    title: Text(
                      lang,
                      style: GoogleFonts.inter(color: AppColors.textPrimary),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                        : null,
                    onTap: () {
                      setState(() => _language = lang);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppLanguagePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'App language',
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final lang = _languages[index];
              final isSelected = lang == _appLanguage;
              return RadioListTile<String>(
                title: Text(
                  lang,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                ),
                value: lang,
                groupValue: _appLanguage,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _appLanguage = value);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.inter(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

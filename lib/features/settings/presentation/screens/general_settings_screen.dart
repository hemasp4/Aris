import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/api_constants.dart';
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
  String _serverUrl = ApiConstants.baseUrl;
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadServerUrl();
  }

  Future<void> _loadServerUrl() async {
    final storedUrl = await _secureStorage.read(key: StorageKeys.baseUrl);
    if (storedUrl != null && storedUrl.isNotEmpty) {
      setState(() => _serverUrl = storedUrl);
      ApiConstants.setBaseUrl(storedUrl);
    }
  }

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
            
            const Divider(color: AppColors.borderLight, height: 1),
            
            // Server URL Configuration (for mobile testing)
            SettingsListTile(
              icon: Icons.cloud_outlined,
              title: 'Server URL',
              subtitle: _serverUrl,
              onTap: () => _showServerUrlDialog(),
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

  void _showServerUrlDialog() {
    final controller = TextEditingController(text: _serverUrl);
    bool isTesting = false;
    String? testResult;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCloud,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Server URL',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your backend server URL. Use your PC\'s IP address or ngrok URL for mobile testing.',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                    hintText: 'http://192.168.1.100:8000',
                    hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.5)),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedLink01,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Quick preset buttons
                Text(
                  'Quick presets:',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPresetChip('Localhost', 'http://localhost:8000', controller, setDialogState),
                    _buildPresetChip('Android Emu', 'http://10.0.2.2:8000', controller, setDialogState),
                  ],
                ),
                
                if (testResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: testResult!.startsWith('✓') 
                          ? Colors.green.withValues(alpha: 0.1) 
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          testResult!.startsWith('✓') ? Icons.check_circle : Icons.error,
                          color: testResult!.startsWith('✓') ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            testResult!,
                            style: GoogleFonts.inter(
                              color: testResult!.startsWith('✓') ? Colors.green : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isTesting ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: isTesting ? null : () async {
                setDialogState(() {
                  isTesting = true;
                  testResult = null;
                });
                
                try {
                  final url = controller.text.trim();
                  final uri = Uri.parse('$url/health');
                  final response = await Future.any([
                    Future.delayed(const Duration(seconds: 5), () => throw TimeoutException('Timeout')),
                  ]);
                  setDialogState(() {
                    testResult = '✓ Connected successfully!';
                    isTesting = false;
                  });
                } catch (e) {
                  setDialogState(() {
                    testResult = '✗ Connection failed. Check the URL and ensure the server is running.';
                    isTesting = false;
                  });
                }
              },
              child: isTesting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      'Test',
                      style: GoogleFonts.inter(color: AppColors.primary),
                    ),
            ),
            ElevatedButton(
              onPressed: isTesting ? null : () async {
                final url = controller.text.trim();
                if (url.isNotEmpty) {
                  // Save to secure storage
                  await _secureStorage.write(key: StorageKeys.baseUrl, value: url);
                  // Update API constants
                  ApiConstants.setBaseUrl(url);
                  setState(() => _serverUrl = url);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Server URL updated. Restart app for full effect.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String url, TextEditingController controller, StateSetter setDialogState) {
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 12,
        ),
      ),
      backgroundColor: AppColors.background,
      side: BorderSide(color: AppColors.borderLight),
      onPressed: () {
        controller.text = url;
        setDialogState(() {});
      },
    );
  }
}

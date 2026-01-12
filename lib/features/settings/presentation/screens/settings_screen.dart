import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/auth_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/settings_model.dart';
import '../../providers/settings_provider.dart';

/// Comprehensive settings screen like ChatGPT
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _biometricAvailable = false;

  final List<_SettingsTab> _tabs = [
    _SettingsTab('General', Icons.settings),
    _SettingsTab('Chat', Icons.chat_bubble),
    _SettingsTab('Model', Icons.smart_toy),
    _SettingsTab('Appearance', Icons.palette),
    _SettingsTab('Security', Icons.security),
    _SettingsTab('Data', Icons.storage),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await authService.isBiometricsAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chat'),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(
            icon: Icon(t.icon, size: 20),
            text: t.label,
          )).toList(),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Reset to Defaults'),
                  ],
                ),
                onTap: () => _showResetDialog(),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Settings'),
                  ],
                ),
                onTap: () => _exportSettings(),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(settings, user),
          _buildChatTab(settings),
          _buildModelTab(settings),
          _buildAppearanceTab(settings),
          _buildSecurityTab(settings),
          _buildDataTab(settings),
        ],
      ),
    );
  }

  // ==================== General Tab ====================
  Widget _buildGeneralTab(AppSettings settings, User? user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Section
        _buildSectionHeader('Profile'),
        _buildProfileCard(user),
        const SizedBox(height: 24),

        // Language
        _buildSectionHeader('Language & Region'),
        _buildSettingsCard([
          _buildDropdownTile(
            'Language',
            Icons.language,
            settings.language,
            {
              'en': 'English',
              'es': 'Español',
              'fr': 'Français',
              'de': 'Deutsch',
              'zh': '中文',
              'ja': '日本語',
            },
            (value) => _updateSetting('language', value),
          ),
        ]),
        const SizedBox(height: 24),

        // Notifications
        _buildSectionHeader('Notifications'),
        _buildSettingsCard([
          _buildSwitchTile(
            'Enable Notifications',
            'Get notified about responses',
            Icons.notifications,
            settings.notificationsEnabled,
            (value) => _updateSetting('notificationsEnabled', value),
          ),
          if (settings.notificationsEnabled) ...[
            _buildSwitchTile(
              'Sound',
              'Play sound for notifications',
              Icons.volume_up,
              settings.soundEnabled,
              (value) => _updateSetting('soundEnabled', value),
            ),
            _buildSwitchTile(
              'Vibration',
              'Vibrate for notifications',
              Icons.vibration,
              settings.vibrationEnabled,
              (value) => _updateSetting('vibrationEnabled', value),
            ),
          ],
        ]),
        const SizedBox(height: 24),

        // Accessibility
        _buildSectionHeader('Accessibility'),
        _buildSettingsCard([
          _buildSwitchTile(
            'Reduce Motion',
            'Minimize animations',
            Icons.animation,
            settings.reduceMotion,
            (value) => _updateSetting('reduceMotion', value),
          ),
          _buildSwitchTile(
            'High Contrast',
            'Increase color contrast',
            Icons.contrast,
            settings.highContrast,
            (value) => _updateSetting('highContrast', value),
          ),
          _buildSwitchTile(
            'Screen Reader Optimized',
            'Better support for screen readers',
            Icons.accessibility,
            settings.screenReaderOptimized,
            (value) => _updateSetting('screenReaderOptimized', value),
          ),
        ]),
      ],
    );
  }

  // ==================== Chat Tab ====================
  Widget _buildChatTab(AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Input Behavior'),
        _buildSettingsCard([
          _buildSwitchTile(
            'Send on Enter',
            'Press Enter to send message',
            Icons.keyboard_return,
            settings.sendOnEnter,
            (value) => _updateSetting('sendOnEnter', value),
          ),
        ]),
        const SizedBox(height: 24),

        _buildSectionHeader('Display'),
        _buildSettingsCard([
          _buildSwitchTile(
            'Show Timestamps',
            'Display time on messages',
            Icons.access_time,
            settings.showTimestamps,
            (value) => _updateSetting('showTimestamps', value),
          ),
          _buildSwitchTile(
            'Show Avatars',
            'Display user and AI avatars',
            Icons.face,
            settings.showAvatars,
            (value) => _updateSetting('showAvatars', value),
          ),
          _buildSwitchTile(
            'Typing Indicator',
            'Show when AI is generating',
            Icons.more_horiz,
            settings.showTypingIndicator,
            (value) => _updateSetting('showTypingIndicator', value),
          ),
        ]),
        const SizedBox(height: 24),

        _buildSectionHeader('Formatting'),
        _buildSettingsCard([
          _buildSwitchTile(
            'Enable Markdown',
            'Render markdown in messages',
            Icons.text_format,
            settings.enableMarkdown,
            (value) => _updateSetting('enableMarkdown', value),
          ),
          _buildSwitchTile(
            'Code Highlighting',
            'Syntax highlighting for code',
            Icons.code,
            settings.enableCodeHighlighting,
            (value) => _updateSetting('enableCodeHighlighting', value),
          ),
        ]),
        const SizedBox(height: 24),

        _buildSectionHeader('Response'),
        _buildSettingsCard([
          _buildSwitchTile(
            'Stream Responses',
            'Show responses as they generate',
            Icons.stream,
            settings.streamResponses,
            (value) => _updateSetting('streamResponses', value),
          ),
          _buildSliderTile(
            'Context Messages',
            'Messages to include for context',
            Icons.history,
            settings.maxContextMessages.toDouble(),
            0,
            50,
            10,
            (value) => _updateSetting('maxContextMessages', value.round()),
            valueLabel: settings.maxContextMessages == 0 
                ? 'Unlimited' 
                : '${settings.maxContextMessages}',
          ),
        ]),
      ],
    );
  }

  // ==================== Model Tab ====================
  Widget _buildModelTab(AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Default Model'),
        _buildModelSelector(settings),
        const SizedBox(height: 24),

        _buildSectionHeader('Generation Parameters'),
        _buildSettingsCard([
          _buildSliderTile(
            'Temperature',
            'Creativity level (0 = focused, 2 = creative)',
            Icons.thermostat,
            settings.temperature,
            0,
            2,
            20,
            (value) => _updateSetting('temperature', value),
            valueLabel: settings.temperature.toStringAsFixed(1),
          ),
          _buildSliderTile(
            'Max Tokens',
            'Maximum response length',
            Icons.format_size,
            settings.maxTokens.toDouble(),
            0,
            4096,
            8,
            (value) => _updateSetting('maxTokens', value.round()),
            valueLabel: settings.maxTokens == 0 
                ? 'Auto' 
                : '${settings.maxTokens}',
          ),
        ]),
        const SizedBox(height: 24),

        _buildSectionHeader('System Prompt'),
        _buildSettingsCard([
          _buildTextAreaTile(
            'Custom Instructions',
            'Instructions applied to every conversation',
            Icons.edit_note,
            settings.systemPrompt,
            (value) => _updateSetting('systemPrompt', value),
          ),
        ]),
        const SizedBox(height: 24),

        _buildSectionHeader('Favorite Models'),
        _buildFavoriteModels(settings),
      ],
    );
  }

  // ==================== Appearance Tab ====================
  Widget _buildAppearanceTab(AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Theme'),
        _buildThemeSelector(settings),
        const SizedBox(height: 24),

        _buildSectionHeader('Accent Color'),
        _buildColorSelector(settings),
        const SizedBox(height: 24),

        _buildSectionHeader('Typography'),
        _buildSettingsCard([
          _buildDropdownTile(
            'Font Family',
            Icons.font_download,
            settings.fontFamily,
            {
              'Inter': 'Inter',
              'Roboto': 'Roboto',
              'System': 'System Default',
              'OpenSans': 'Open Sans',
              'Poppins': 'Poppins',
            },
            (value) => _updateSetting('fontFamily', value),
          ),
          _buildSliderTile(
            'Font Size',
            'Adjust text size',
            Icons.text_fields,
            settings.fontSize,
            0.8,
            1.4,
            3,
            (value) => _updateSetting('fontSize', value),
            valueLabel: _getFontSizeLabel(settings.fontSize),
          ),
        ]),
        const SizedBox(height: 24),

        _buildSectionHeader('Layout'),
        _buildSettingsCard([
          _buildSwitchTile(
            'Compact Mode',
            'Reduce spacing between elements',
            Icons.view_compact,
            settings.compactMode,
            (value) => _updateSetting('compactMode', value),
          ),
        ]),
      ],
    );
  }

  // ==================== Security Tab ====================
  Widget _buildSecurityTab(AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_biometricAvailable) ...[
          _buildSectionHeader('Biometric Authentication'),
          _buildSettingsCard([
            _buildSwitchTile(
              'Biometric Unlock',
              'Use fingerprint or face ID',
              Icons.fingerprint,
              settings.biometricEnabled,
              (value) async {
                if (value) {
                  await authService.enableBiometricLogin();
                } else {
                  await authService.disableBiometricLogin();
                }
                _updateSetting('biometricEnabled', value);
              },
            ),
            _buildSwitchTile(
              'Require on Launch',
              'Authenticate when app opens',
              Icons.lock_open,
              settings.requireAuthOnLaunch,
              (value) => _updateSetting('requireAuthOnLaunch', value),
            ),
          ]),
          const SizedBox(height: 24),
        ],

        _buildSectionHeader('Auto-Lock'),
        _buildSettingsCard([
          _buildSwitchTile(
            'Auto-Lock',
            'Lock app when inactive',
            Icons.lock_clock,
            settings.autoLockEnabled,
            (value) => _updateSetting('autoLockEnabled', value),
          ),
          if (settings.autoLockEnabled)
            _buildDropdownTile(
              'Lock After',
              Icons.timer,
              settings.autoLockTimeout.toString(),
              {
                '1': '1 minute',
                '5': '5 minutes',
                '15': '15 minutes',
                '30': '30 minutes',
                '60': '1 hour',
              },
              (value) => _updateSetting('autoLockTimeout', int.parse(value)),
            ),
        ]),
        const SizedBox(height: 24),

        _buildSectionHeader('Account'),
        _buildSettingsCard([
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, 
              color: Theme.of(context).colorScheme.error),
            title: Text('Delete Account',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDeleteAccountDialog(),
          ),
        ]),
      ],
    );
  }

  // ==================== Data Tab ====================
  Widget _buildDataTab(AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Chat History'),
        _buildSettingsCard([
          _buildSwitchTile(
            'Save History',
            'Keep conversation history',
            Icons.history,
            settings.saveHistory,
            (value) => _updateSetting('saveHistory', value),
          ),
          _buildSwitchTile(
            'Auto-Save',
            'Automatically save chats',
            Icons.save,
            settings.autoSaveChats,
            (value) => _updateSetting('autoSaveChats', value),
          ),
          _buildDropdownTile(
            'Retention',
            Icons.schedule,
            settings.historyRetentionDays.toString(),
            {
              '0': 'Forever',
              '7': '7 days',
              '30': '30 days',
              '90': '90 days',
              '365': '1 year',
            },
            (value) => _updateSetting('historyRetentionDays', int.parse(value)),
          ),
        ]),
        const SizedBox(height: 24),

        _buildSectionHeader('Export'),
        _buildSettingsCard([
          _buildDropdownTile(
            'Export Format',
            Icons.file_present,
            settings.exportFormat,
            {
              'markdown': 'Markdown (.md)',
              'json': 'JSON (.json)',
              'txt': 'Plain Text (.txt)',
              'html': 'HTML (.html)',
            },
            (value) => _updateSetting('exportFormat', value),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export All Chats'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportChats(),
          ),
        ]),
        const SizedBox(height: 24),

        _buildSectionHeader('Storage'),
        _buildSettingsCard([
          _buildSwitchTile(
            'Cache Images',
            'Store images locally',
            Icons.image,
            settings.cacheImages,
            (value) => _updateSetting('cacheImages', value),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up storage space'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClearCacheDialog(),
          ),
        ]),
        const SizedBox(height: 24),

        _buildSectionHeader('Privacy'),
        _buildSettingsCard([
          _buildSwitchTile(
            'Analytics',
            'Help improve Aris with usage data',
            Icons.analytics,
            settings.shareChatData,
            (value) => _updateSetting('shareChatData', value),
          ),
        ]),
        const SizedBox(height: 24),

        _buildSectionHeader('Advanced'),
        _buildSettingsCard([
          ListTile(
            leading: const Icon(Icons.api),
            title: const Text('API Endpoint'),
            subtitle: Text(settings.apiEndpoint),
            trailing: const Icon(Icons.edit),
            onTap: () => _showEndpointDialog(settings),
          ),
          _buildSliderTile(
            'Request Timeout',
            'Seconds to wait for response',
            Icons.hourglass_empty,
            settings.requestTimeout.toDouble(),
            10,
            120,
            11,
            (value) => _updateSetting('requestTimeout', value.round()),
            valueLabel: '${settings.requestTimeout}s',
          ),
          _buildSwitchTile(
            'Debug Mode',
            'Show detailed logging',
            Icons.bug_report,
            settings.debugMode,
            (value) => _updateSetting('debugMode', value),
          ),
        ]),
        const SizedBox(height: 24),

        // Danger Zone
        _buildSectionHeader('Danger Zone'),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.error),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.delete_sweep, 
                  color: Theme.of(context).colorScheme.error),
                title: Text('Delete All Chats',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () => _showDeleteAllChatsDialog(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),

        // Logout
        ElevatedButton.icon(
          onPressed: () => _showLogoutDialog(),
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
        ),

        const SizedBox(height: 24),

        // Version
        Center(
          child: Text(
            'Aris Chatbot v1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ==================== Helper Widgets ====================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      child: Column(children: children),
    );
  }

  Widget _buildProfileCard(User? user) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                user?.username.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.username ?? 'User',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? 'No email',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showProfileDialog(user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownTile<T>(
    String title,
    IconData icon,
    String value,
    Map<String, String> options,
    Function(String) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.entries.map((e) => 
          DropdownMenuItem(value: e.key, child: Text(e.value))
        ).toList(),
        onChanged: (v) => v != null ? onChanged(v) : null,
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    IconData icon,
    double value,
    double min,
    double max,
    int divisions,
    Function(double) onChanged, {
    String? valueLabel,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Row(
        children: [
          Text(title),
          const Spacer(),
          Text(
            valueLabel ?? value.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      subtitle: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextAreaTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    Function(String) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: TextEditingController(text: value),
          decoration: InputDecoration(
            hintText: subtitle,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(AppSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _ThemeOption(
                label: 'Light',
                icon: Icons.light_mode,
                isSelected: settings.themeMode == 'light',
                onTap: () => _updateSetting('themeMode', 'light'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ThemeOption(
                label: 'System',
                icon: Icons.settings_brightness,
                isSelected: settings.themeMode == 'system',
                onTap: () => _updateSetting('themeMode', 'system'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ThemeOption(
                label: 'Dark',
                icon: Icons.dark_mode,
                isSelected: settings.themeMode == 'dark',
                onTap: () => _updateSetting('themeMode', 'dark'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector(AppSettings settings) {
    final colors = [
      '#4F46E5', // Indigo
      '#7C3AED', // Purple
      '#EC4899', // Pink
      '#EF4444', // Red
      '#F97316', // Orange
      '#EAB308', // Yellow
      '#22C55E', // Green
      '#06B6D4', // Cyan
      '#3B82F6', // Blue
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final isSelected = settings.accentColor == color;
            return InkWell(
              onTap: () => _updateSetting('accentColor', color),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 3,
                  ) : null,
                ),
                child: isSelected 
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildModelSelector(AppSettings settings) {
    final models = [
      {'name': 'llama3.2', 'params': '8B', 'desc': 'Fast & balanced', 'speed': 'Fast'},
      {'name': 'llama3.2:1b', 'params': '1B', 'desc': 'Ultra fast', 'speed': 'Very Fast'},
      {'name': 'mistral', 'params': '7B', 'desc': 'Great reasoning', 'speed': 'Fast'},
      {'name': 'codellama', 'params': '13B', 'desc': 'Code focused', 'speed': 'Medium'},
      {'name': 'phi3', 'params': '3.8B', 'desc': 'Compact & smart', 'speed': 'Very Fast'},
      {'name': 'gemma2', 'params': '9B', 'desc': 'Latest Google model', 'speed': 'Fast'},
    ];

    return Card(
      child: Column(
        children: models.map((model) {
          final isSelected = settings.defaultModel == model['name'];
          return ListTile(
            leading: Radio<String>(
              value: model['name']!,
              groupValue: settings.defaultModel,
              onChanged: (v) => _updateSetting('defaultModel', v),
            ),
            title: Text(model['name']!),
            subtitle: Text('${model['params']} • ${model['desc']}'),
            trailing: Chip(
              label: Text(model['speed']!),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFavoriteModels(AppSettings settings) {
    final allModels = ['llama3.2', 'llama3.2:1b', 'mistral', 'codellama', 'phi3', 'gemma2'];
    
    return Card(
      child: Column(
        children: allModels.map((model) {
          final isFavorite = settings.favoriteModels.contains(model);
          return ListTile(
            leading: IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : null,
              ),
              onPressed: () {
                final favorites = List<String>.from(settings.favoriteModels);
                if (isFavorite) {
                  favorites.remove(model);
                } else {
                  favorites.add(model);
                }
                _updateSetting('favoriteModels', favorites);
              },
            ),
            title: Text(model),
          );
        }).toList(),
      ),
    );
  }

  String _getFontSizeLabel(double size) {
    if (size <= 0.85) return 'Small';
    if (size <= 1.05) return 'Medium';
    if (size <= 1.25) return 'Large';
    return 'Extra Large';
  }

  Future<void> _updateSetting<T>(String key, T value) async {
    await ref.read(settingsProvider.notifier).updateSetting(key, value);
  }

  // ==================== Dialogs ====================

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('This will reset all settings to their default values. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(settingsProvider.notifier).resetToDefaults();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to defaults')),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(User? user) {
    final usernameController = TextEditingController(text: user?.username ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This will permanently delete your account and all data. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. Your chats and settings will be preserved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllChatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Chats'),
        content: const Text('This will permanently delete all your chat history. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showEndpointDialog(AppSettings settings) {
    final controller = TextEditingController(text: settings.apiEndpoint);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Endpoint'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'http://localhost:8000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateSetting('apiEndpoint', controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _exportSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings exported')),
    );
  }

  void _exportChats() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chats exported')),
    );
  }
}

// ==================== Helper Classes ====================

class _SettingsTab {
  final String label;
  final IconData icon;
  
  _SettingsTab(this.label, this.icon);
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withOpacity(0.1)
              : null,
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.primary : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

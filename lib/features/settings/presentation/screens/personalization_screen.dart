import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/settings_widgets.dart';

/// Personalization Settings Screen - ChatGPT exact
class PersonalizationScreen extends ConsumerStatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  ConsumerState<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends ConsumerState<PersonalizationScreen> {
  // Base style
  String _baseStyle = 'Default';
  final List<Map<String, String>> _styleOptions = [
    {'name': 'Default', 'description': 'Preset style and tone'},
    {'name': 'Professional', 'description': 'Polished and precise'},
    {'name': 'Friendly', 'description': 'Warm and chatty'},
    {'name': 'Candid', 'description': 'Direct and encouraging'},
    {'name': 'Quirky', 'description': 'Playful and imaginative'},
    {'name': 'Efficient', 'description': 'Concise and plain'},
    {'name': 'Nerdy', 'description': 'Exploratory and enthusiastic'},
    {'name': 'Cynical', 'description': 'Critical and sarcastic'},
  ];

  // Characteristics
  String _warmLevel = 'Default';
  String _enthusiasticLevel = 'Default';
  String _headersListsLevel = 'Default';
  String _emojiLevel = 'Default';

  // Custom instructions
  final _customInstructionsController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _occupationController = TextEditingController();
  final _aboutYouController = TextEditingController();

  // Advanced toggles
  bool _webSearch = true;
  bool _code = true;
  bool _canvas = true;
  bool _advancedVoice = true;

  // Expand states
  bool _advancedExpanded = false;
  bool _warmExpanded = false;
  bool _enthusiasticExpanded = false;
  bool _headersExpanded = false;
  bool _emojiExpanded = false;

  @override
  void dispose() {
    _customInstructionsController.dispose();
    _nicknameController.dispose();
    _occupationController.dispose();
    _aboutYouController.dispose();
    super.dispose();
  }

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
          'Personalization',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Base style dropdown
            _buildStyleDropdown(),
            
            const SizedBox(height: 12),
            
            // Help text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.settingsCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This is the main style for your conversations. Adjust Aris\'s capabilities.',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Characteristics section
            const SettingsSectionHeader(title: 'Characteristics'),
            
            const SizedBox(height: 8),
            
            Text(
              'Choose some aspects of how Aris communicates with your base style.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildCharacteristicDropdown(
              title: 'Warm',
              value: _warmLevel,
              expanded: _warmExpanded,
              onToggle: () => setState(() => _warmExpanded = !_warmExpanded),
              onSelect: (v) => setState(() => _warmLevel = v),
              moreDescription: 'Friendlier and more personable',
              lessDescription: 'More professional and factual',
            ),
            
            const SizedBox(height: 8),
            
            _buildCharacteristicDropdown(
              title: 'Enthusiastic',
              value: _enthusiasticLevel,
              expanded: _enthusiasticExpanded,
              onToggle: () => setState(() => _enthusiasticExpanded = !_enthusiasticExpanded),
              onSelect: (v) => setState(() => _enthusiasticLevel = v),
              moreDescription: 'More energy and excitement',
              lessDescription: 'Calmer and more neutral',
            ),
            
            const SizedBox(height: 8),
            
            _buildCharacteristicDropdown(
              title: 'Headers & Lists',
              value: _headersListsLevel,
              expanded: _headersExpanded,
              onToggle: () => setState(() => _headersExpanded = !_headersExpanded),
              onSelect: (v) => setState(() => _headersListsLevel = v),
              moreDescription: 'Use more structured formatting',
              lessDescription: 'Use more flowing text',
            ),
            
            const SizedBox(height: 8),
            
            _buildCharacteristicDropdown(
              title: 'Emoji',
              value: _emojiLevel,
              expanded: _emojiExpanded,
              onToggle: () => setState(() => _emojiExpanded = !_emojiExpanded),
              onSelect: (v) => setState(() => _emojiLevel = v),
              moreDescription: 'Use more emoji',
              lessDescription: 'Don\'t use as many emoji',
            ),
            
            const SizedBox(height: 16),
            
            // Reset characteristics
            TextButton(
              onPressed: _resetCharacteristics,
              child: Text(
                'Reset characteristics',
                style: GoogleFonts.inter(color: AppColors.danger, fontSize: 14),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Custom instructions section
            const SettingsSectionHeader(title: 'Custom instructions'),
            
            _buildTextField(
              controller: _customInstructionsController,
              hint: 'Share anything Aris should consider in its responses...',
              maxLines: 4,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Your nickname',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nicknameController,
              hint: 'Nickname',
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Your occupation',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _occupationController,
              hint: 'Engineer, student, etc.',
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'More about you',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _aboutYouController,
              hint: 'Interests, values, or preferences to keep in mind',
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Memories button
            SettingsActionButton(
              label: 'Memories',
              icon: Icons.psychology_outlined,
              onTap: () => context.push('/settings/memories'),
            ),
            
            const SizedBox(height: 24),
            
            // Advanced section
            _buildAdvancedSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleDropdown() {
    return InkWell(
      onTap: _showStylePicker,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Base style and tone',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _baseStyle,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showStylePicker() {
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
            ..._styleOptions.map((option) => ListTile(
              title: Text(
                option['name']!,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                option['description']!,
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
              ),
              trailing: option['name'] == _baseStyle
                  ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                  : null,
              onTap: () {
                setState(() => _baseStyle = option['name']!);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicDropdown({
    required String title,
    required String value,
    required bool expanded,
    required VoidCallback onToggle,
    required ValueChanged<String> onSelect,
    required String moreDescription,
    required String lessDescription,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.settingsCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _buildCharacteristicOption('More', moreDescription, value == 'More', () => onSelect('More')),
                  const SizedBox(height: 8),
                  _buildCharacteristicOption('Default', '', value == 'Default', () => onSelect('Default')),
                  const SizedBox(height: 8),
                  _buildCharacteristicOption('Less', lessDescription, value == 'Less', () => onSelect('Less')),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCharacteristicOption(String label, String description, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        filled: true,
        fillColor: AppColors.settingsCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.settingsCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _advancedExpanded = !_advancedExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'ADVANCED',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _advancedExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_advancedExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _buildAdvancedToggle(
                    icon: Icons.language,
                    title: 'Web search',
                    description: 'Search the web to find answers',
                    value: _webSearch,
                    onChanged: (v) => setState(() => _webSearch = v),
                  ),
                  const SizedBox(height: 12),
                  _buildAdvancedToggle(
                    icon: Icons.code,
                    title: 'Code',
                    description: 'Execute code using Code Interpreter',
                    value: _code,
                    onChanged: (v) => setState(() => _code = v),
                  ),
                  const SizedBox(height: 12),
                  _buildAdvancedToggle(
                    icon: Icons.palette_outlined,
                    title: 'Canvas',
                    description: 'Collaborate with Aris on text and code',
                    value: _canvas,
                    onChanged: (v) => setState(() => _canvas = v),
                  ),
                  const SizedBox(height: 12),
                  _buildAdvancedToggle(
                    icon: Icons.mic_outlined,
                    title: 'Advanced voice',
                    description: 'More natural conversation in voice mode',
                    value: _advancedVoice,
                    onChanged: (v) => setState(() => _advancedVoice = v),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdvancedToggle({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
          inactiveThumbColor: AppColors.textMuted,
          inactiveTrackColor: AppColors.toggleTrackOff,
        ),
      ],
    );
  }

  void _resetCharacteristics() {
    setState(() {
      _warmLevel = 'Default';
      _enthusiasticLevel = 'Default';
      _headersListsLevel = 'Default';
      _emojiLevel = 'Default';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Characteristics reset to defaults.'),
        backgroundColor: AppColors.settingsCard,
      ),
    );
  }

  void _saveSettings() {
    // TODO: Save to backend/local storage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved.'),
        backgroundColor: AppColors.settingsCard,
      ),
    );
    context.pop();
  }
}

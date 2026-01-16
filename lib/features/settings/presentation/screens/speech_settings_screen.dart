import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/settings_widgets.dart';

/// Speech/Voice Settings Screen - ChatGPT exact
class SpeechSettingsScreen extends ConsumerStatefulWidget {
  const SpeechSettingsScreen({super.key});

  @override
  ConsumerState<SpeechSettingsScreen> createState() => _SpeechSettingsScreenState();
}

class _SpeechSettingsScreenState extends ConsumerState<SpeechSettingsScreen> {
  String _inputLanguage = 'Auto-Detect';
  String _selectedVoice = 'Breeze';
  bool _separateMode = false;
  bool _backgroundConversations = false;
  bool _defaultAssistant = false;

  final List<String> _languages = [
    'Auto-Detect',
    'Arabic',
    'Bengali',
    'Bosnian',
    'Bulgarian',
    'Catalan',
    'Chinese',
    'Croatian',
    'Czech',
    'Danish',
    'Dutch',
    'English',
    'Estonian',
    'Finnish',
    'French',
    'German',
    'Greek',
    'Hebrew',
    'Hindi',
    'Hungarian',
    'Indonesian',
    'Italian',
    'Japanese',
    'Korean',
    'Latvian',
    'Lithuanian',
    'Malay',
    'Norwegian',
    'Polish',
    'Portuguese',
    'Romanian',
    'Russian',
    'Serbian',
    'Slovak',
    'Slovenian',
    'Spanish',
    'Swedish',
    'Thai',
    'Turkish',
    'Ukrainian',
    'Vietnamese',
  ];

  final List<Map<String, dynamic>> _voices = [
    {'name': 'Breeze', 'description': 'Animated and earnest', 'color': Colors.blue},
    {'name': 'Cove', 'description': 'Calm and collected', 'color': Colors.teal},
    {'name': 'Ember', 'description': 'Warm and expressive', 'color': Colors.orange},
    {'name': 'Juniper', 'description': 'Fresh and energetic', 'color': Colors.green},
    {'name': 'Sky', 'description': 'Light and airy', 'color': Colors.lightBlue},
    {'name': 'Sage', 'description': 'Wise and thoughtful', 'color': Colors.purple},
    {'name': 'Vale', 'description': 'Gentle and soothing', 'color': Colors.indigo},
    {'name': 'Reef', 'description': 'Deep and resonant', 'color': Colors.cyan},
    {'name': 'Arbor', 'description': 'Natural and grounded', 'color': Colors.brown},
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
          'Speech',
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
            // Input language dropdown
            SettingsDropdown(
              label: 'Input language',
              value: _inputLanguage,
              options: _languages,
              onChanged: (value) => setState(() => _inputLanguage = value),
            ),
            
            const SizedBox(height: 8),
            
            // Help text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.settingsCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'For best results, select the language you mainly speak. If it\'s not listed, it may still be supported via auto-detection.',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Voice selection
            InkWell(
              onTap: () => _showVoiceSelector(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq, color: AppColors.textPrimary, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            _selectedVoice,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Toggle switches
            SettingsToggleCard(
              title: 'Separate mode',
              value: _separateMode,
              onChanged: (value) => setState(() => _separateMode = value),
            ),
            
            const SizedBox(height: 12),
            
            SettingsToggleCard(
              title: 'Background conversations',
              description: 'Keep the conversation going in other apps or while your screen is off.',
              value: _backgroundConversations,
              onChanged: (value) => setState(() => _backgroundConversations = value),
            ),
            
            const SizedBox(height: 12),
            
            SettingsToggleCard(
              title: 'Use as default assistant',
              description: 'Set Aris as your default digital assistant in Android settings.',
              value: _defaultAssistant,
              onChanged: (value) => setState(() => _defaultAssistant = value),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoiceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _VoiceCarousel(
        voices: _voices,
        selectedVoice: _selectedVoice,
        onSelect: (voice) {
          setState(() => _selectedVoice = voice);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Voice carousel widget with swipe
class _VoiceCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> voices;
  final String selectedVoice;
  final ValueChanged<String> onSelect;

  const _VoiceCarousel({
    required this.voices,
    required this.selectedVoice,
    required this.onSelect,
  });

  @override
  State<_VoiceCarousel> createState() => _VoiceCarouselState();
}

class _VoiceCarouselState extends State<_VoiceCarousel> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.voices.indexWhere((v) => v['name'] == widget.selectedVoice);
    if (_currentIndex < 0) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Close button
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          const Spacer(),
          
          // Voice carousel
          Expanded(
            flex: 3,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.voices.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final voice = widget.voices[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated orb
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 1.05),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  (voice['color'] as Color).withValues(alpha: 0.8),
                                  (voice['color'] as Color).withValues(alpha: 0.3),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (voice['color'] as Color).withValues(alpha: 0.4),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Text(
                      voice['name'],
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      voice['description'],
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          const Spacer(),
          
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.voices.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentIndex
                      ? AppColors.textPrimary
                      : AppColors.textPrimary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Done button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => widget.onSelect(widget.voices[_currentIndex]['name']),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.settingsCard,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                'Done',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

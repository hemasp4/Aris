import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_colors.dart';

/// Random suggestions per category - 20-25 suggestions each
class SuggestionData {
  static final Random _random = Random();

  // Create Image suggestions
  static const List<String> createImageSuggestions = [
    'a futuristic city at sunset',
    'a lion in a jungle',
    'a magical forest with fireflies',
    'a cozy coffee shop interior',
    'a space station orbiting Earth',
    'a vintage car on Route 66',
    'an underwater coral reef',
    'a mountain landscape at dawn',
    'a cyberpunk street scene',
    'a medieval castle in mist',
    'a tropical beach paradise',
    'a steampunk flying machine',
    'a Japanese zen garden',
    'a northern lights display',
    'a vintage 1950s diner',
    'a dragon flying over mountains',
    'an ancient Egyptian temple',
    'a cozy cabin in snow',
    'a neon-lit Tokyo street',
    'a magical unicorn in meadow',
    'a pirate ship at sea',
    'a serene lake at sunrise',
    'a futuristic robot assistant',
  ];

  // Analyze Image suggestions
  static const List<String> analyzeImageSuggestions = [
    'describe what you see',
    'identify objects in this photo',
    'extract text from this image',
    'analyze the color palette',
    'identify the art style',
    'detect emotions in faces',
    'find similar images',
    'explain this diagram',
    'identify the location',
    'analyze the composition',
    'identify plants or animals',
    'read the handwriting',
    'identify the brand or logo',
    'describe the mood',
    'identify the time period',
    'analyze product packaging',
    'identify landmarks',
    'explain this chart or graph',
    'identify the food items',
    'analyze fashion elements',
    'identify the vehicle model',
    'describe the architecture style',
  ];

  // Summarize Text suggestions
  static const List<String> summarizeTextSuggestions = [
    'this article for me',
    'the key points briefly',
    'in 3 bullet points',
    'in one paragraph',
    'for a 5-year-old',
    'the main arguments',
    'the conclusions',
    'the methodology used',
    'for a presentation',
    'in a tweet',
    'the pros and cons',
    'the timeline of events',
    'the key statistics',
    'for an executive summary',
    'the action items',
    'the main themes',
    'in simple language',
    'the research findings',
    'the recommendations',
    'for a newsletter',
    'the chapter overview',
    'the legal implications',
    'the technical details',
  ];

  // Analyze Data suggestions
  static const List<String> analyzeDataSuggestions = [
    'find trends in this data',
    'calculate the average',
    'identify outliers',
    'create a visualization',
    'find correlations',
    'predict future values',
    'compare these datasets',
    'find patterns',
    'calculate growth rate',
    'identify seasonality',
    'segment the data',
    'find anomalies',
    'create a pivot table',
    'calculate percentages',
    'rank the items',
    'find the median',
    'analyze distribution',
    'compare year over year',
    'identify clusters',
    'calculate ROI',
    'find peak values',
    'analyze by category',
    'forecast trends',
  ];

  // Code suggestions
  static const List<String> codeSuggestions = [
    'sorts an array efficiently',
    'fetches data from an API',
    'validates email format',
    'creates a login form',
    'implements pagination',
    'handles file uploads',
    'creates a REST API',
    'implements authentication',
    'creates a database schema',
    'implements caching',
    'handles errors gracefully',
    'creates unit tests',
    'implements search function',
    'creates a responsive layout',
    'implements dark mode',
    'creates animations',
    'implements WebSocket',
    'creates a state machine',
    'implements OAuth',
    'creates middleware',
  ];

  // Get random suggestions for a category
  static List<String> getRandomSuggestions(String category, {int count = 4}) {
    List<String> source;
    switch (category) {
      case 'Create image':
        source = createImageSuggestions;
        break;
      case 'Analyze images':
        source = analyzeImageSuggestions;
        break;
      case 'Summarize text':
        source = summarizeTextSuggestions;
        break;
      case 'Analyze data':
        source = analyzeDataSuggestions;
        break;
      case 'Code':
        source = codeSuggestions;
        break;
      default:
        source = createImageSuggestions;
    }
    
    final shuffled = List<String>.from(source)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  // Get prompt prefix for category
  static String getPromptPrefix(String category) {
    switch (category) {
      case 'Create image':
        return 'Create an image of';
      case 'Analyze images':
        return 'Analyze this image:';
      case 'Summarize text':
        return 'Summarize';
      case 'Analyze data':
        return 'Analyze this data:';
      case 'Code':
        return 'Write code that';
      default:
        return '';
    }
  }
}

/// ChatGPT-EXACT suggestion chip with HugeIcon
/// Height: 44dp, Border radius: 22dp (fully rounded)
/// Press animation: scale 0.97 with haptic feedback
class SuggestionChip extends StatefulWidget {
  final String label;
  final dynamic icon; // HugeIcons use List<List<dynamic>>, not IconData
  final Color iconColor;
  final VoidCallback onTap;

  const SuggestionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<SuggestionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.selectionClick();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery text scale for responsive sizing
    final textScaler = MediaQuery.textScalerOf(context);
    final scaledHeight = textScaler.scale(44);
    final scaledIconSize = textScaler.scale(20);
    final scaledFontSize = textScaler.scale(14);
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: scaledHeight.clamp(40, 56), // Responsive but clamped
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(scaledHeight / 2),
            border: Border.all(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Use HugeIcon widget for polished icons
              HugeIcon(
                icon: widget.icon,
                size: scaledIconSize.clamp(18, 24),
                color: widget.iconColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: scaledFontSize.clamp(12, 16),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ChatGPT-EXACT quick action chips - 2 rows layout
/// Row 1: Create image, Analyze images
/// Row 2: Summarize text, Analyze data, More
class ExpandedSuggestionChips extends ConsumerStatefulWidget {
  final Function(String) onSuggestionTap;
  final Function(String)? onCategorySelected; // Optional callback for category selection

  const ExpandedSuggestionChips({
    super.key,
    required this.onSuggestionTap,
    this.onCategorySelected,
  });

  @override
  ConsumerState<ExpandedSuggestionChips> createState() => _ExpandedSuggestionChipsState();
}

class _ExpandedSuggestionChipsState extends ConsumerState<ExpandedSuggestionChips> {
  bool _expanded = false;

  // ChatGPT-exact suggestions with HugeIcons (using dynamic type)
  static final List<Map<String, dynamic>> _primarySuggestions = [
    // Row 1 - exactly like ChatGPT
    {'label': 'Create image', 'icon': HugeIcons.strokeRoundedImage01, 'color': AppColors.chipGreen, 'prompt': 'Create an image of'},
    {'label': 'Analyze images', 'icon': HugeIcons.strokeRoundedView, 'color': AppColors.chipPink, 'prompt': 'Analyze this image'},
    // Row 2
    {'label': 'Summarize text', 'icon': HugeIcons.strokeRoundedTextAlignLeft, 'color': AppColors.chipOrange, 'prompt': 'Summarize the following text:'},
    {'label': 'Analyze data', 'icon': HugeIcons.strokeRoundedChartLineData01, 'color': AppColors.chipBlue, 'prompt': 'Analyze this data:'},
  ];

  static final List<Map<String, dynamic>> _expandedSuggestions = [
    {'label': 'Get advice', 'icon': HugeIcons.strokeRoundedIdea01, 'color': AppColors.chipGreen, 'prompt': 'Give me advice about'},
    {'label': 'Make a plan', 'icon': HugeIcons.strokeRoundedSun03, 'color': AppColors.chipOrange, 'prompt': 'Help me make a plan for'},
    {'label': 'Surprise me', 'icon': HugeIcons.strokeRoundedGift, 'color': AppColors.chipPink, 'prompt': 'Tell me something interesting'},
    {'label': 'Code', 'icon': HugeIcons.strokeRoundedSourceCode, 'color': AppColors.chipPurple, 'prompt': 'Write code that'},
    {'label': 'Help me write', 'icon': HugeIcons.strokeRoundedPencilEdit01, 'color': AppColors.chipBlue, 'prompt': 'Help me write'},
    {'label': 'Brainstorm', 'icon': HugeIcons.strokeRoundedBrain, 'color': AppColors.chipPurple, 'prompt': 'Brainstorm ideas for'},
  ];

  void _handleChipTap(Map<String, dynamic> suggestion) {
    final label = suggestion['label'] as String;
    final prompt = suggestion['prompt'] as String;
    
    // Call the suggestion tap callback with the prompt
    widget.onSuggestionTap(prompt);
    
    // Notify parent about category selection for showing random hints
    widget.onCategorySelected?.call(label);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: 2 chips (exactly like ChatGPT)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildChip(_primarySuggestions[0]), // Create image
            _buildChip(_primarySuggestions[1]), // Analyze images
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Row 2: 2 chips + More button (exactly like ChatGPT)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildChip(_primarySuggestions[2]), // Summarize text
            _buildChip(_primarySuggestions[3]), // Analyze data
            if (!_expanded) _buildMoreButton(),
          ],
        ),
        
        // Expanded rows
        if (_expanded) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _expandedSuggestions.map((s) => _buildChip(s)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildChip(Map<String, dynamic> suggestion) {
    return SuggestionChip(
      label: suggestion['label'] as String,
      icon: suggestion['icon'], // Pass as dynamic (HugeIcons type)
      iconColor: suggestion['color'] as Color,
      onTap: () => _handleChipTap(suggestion),
    );
  }

  Widget _buildMoreButton() {
    return SuggestionChip(
      label: 'More',
      icon: HugeIcons.strokeRoundedMoreHorizontal, // Pass directly (dynamic type)
      iconColor: AppColors.chipGray,
      onTap: () => setState(() => _expanded = true),
    );
  }
}

/// Random suggestion hints displayed above input box
/// Shows 4 random suggestions based on selected category
class SuggestionHints extends StatelessWidget {
  final String? selectedCategory;
  final Function(String) onHintTap;

  const SuggestionHints({
    super.key,
    this.selectedCategory,
    required this.onHintTap,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCategory == null) return const SizedBox.shrink();

    final hints = SuggestionData.getRandomSuggestions(selectedCategory!, count: 4);
    final textScaler = MediaQuery.textScalerOf(context);
    final fontSize = textScaler.scale(13).clamp(11.0, 15.0);
    final padding = textScaler.scale(8).clamp(6.0, 12.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: padding),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: hints.map((hint) => GestureDetector(
          onTap: () => onHintTap(hint),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              hint,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: fontSize,
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }
}

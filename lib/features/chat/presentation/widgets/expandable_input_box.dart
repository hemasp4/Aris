import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_colors.dart';
import 'full_screen_text_editor.dart';
import 'voice_waveform_widget.dart';
import '../../providers/voice_input_provider.dart';
import 'voice_listening_overlay.dart';

/// ChatGPT-style expandable input box with:
/// - Expansion from 1 to 10 lines with smooth animation (120ms ease)
/// - Image thumbnail preview row with horizontal scroll
/// - Fixed + (left) and Send (right) buttons that don't move during expansion
class ExpandableInputBox extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool isStreaming;
  final bool isVoiceListening;
  final bool isVoiceConvertedText; // True if text came from voice-to-text (keep mic visible)
  final List<File> attachedImages;
  final String? researchMode; // 'web_search', 'deep_research', 'shopping'
  final VoidCallback? onSend;
  final VoidCallback? onAttachmentTap;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onVoiceStopAndSend;
  final VoidCallback? onVoiceCancel;
  final VoidCallback? onCancelStream;
  final VoidCallback? onClearResearchMode;
  final Function(File)? onRemoveImage;

  const ExpandableInputBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = 'Message Aris...',
    this.isStreaming = false,
    this.isVoiceListening = false,
    this.isVoiceConvertedText = false,
    this.attachedImages = const [],
    this.researchMode,
    this.onSend,
    this.onAttachmentTap,
    this.onVoiceTap,
    this.onVoiceStopAndSend,
    this.onVoiceCancel,
    this.onCancelStream,
    this.onClearResearchMode,
    this.onRemoveImage,
  });

  @override
  ConsumerState<ExpandableInputBox> createState() => _ExpandableInputBoxState();
}

class _ExpandableInputBoxState extends ConsumerState<ExpandableInputBox>
    with SingleTickerProviderStateMixin {
  // Line height calculations for expansion
  static const double _baseLineHeight = 20.0;
  static const double _basePadding = 24.0; // vertical padding
  static const double _minHeight = 48.0;
  static const double _maxLines = 10;
  
  double _currentHeight = _minHeight;
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    _calculateLines();
  }

  void _calculateLines() {
    final text = widget.controller.text;
    if (text.isEmpty) {
      if (_lineCount != 1) {
        setState(() {
          _lineCount = 1;
          _currentHeight = _minHeight;
        });
      }
      return;
    }

    // Calculate approximate line count based on text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 15, height: 1.4),
      ),
      textDirection: TextDirection.ltr,
      maxLines: _maxLines.toInt(),
    );

    // Layout with approximate input width (accounting for padding and button)
    final screenWidth = MediaQuery.of(context).size.width;
    final inputWidth = (screenWidth - 120).clamp(200.0, 600.0); // Account for buttons
    textPainter.layout(maxWidth: inputWidth);

    // Count lines based on height
    final lineHeight = textPainter.preferredLineHeight;
    int lines = (textPainter.height / lineHeight).ceil();
    lines = lines.clamp(1, _maxLines.toInt());

    if (lines != _lineCount) {
      setState(() {
        _lineCount = lines;
        _currentHeight = _minHeight + ((lines - 1) * _baseLineHeight);
        _currentHeight = _currentHeight.clamp(_minHeight, _minHeight + ((_maxLines - 1) * _baseLineHeight));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    final hasImages = widget.attachedImages.isNotEmpty;
    final hasResearchMode = widget.researchMode != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Fixed + button (OUTSIDE rounded box, left side)
              _buildAttachmentButton(),
              
              const SizedBox(width: 8),
              
              // Rounded input container (holds pill + images + text + buttons)
              Expanded(
                child: _buildRoundedInputContainer(
                  hasText: hasText,
                  hasImages: hasImages,
                  hasResearchMode: hasResearchMode,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Rounded container that holds all input content (ChatGPT style)
  /// Layout: [Search Pill] → [Image Previews] → [Text + Zoom | Mic + Send]
  Widget _buildRoundedInputContainer({
    required bool hasText,
    required bool hasImages,
    required bool hasResearchMode,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search pill (inside, top-left) - no separator
          if (hasResearchMode)
            _buildInlineResearchPill(),
          
          // Image previews (inside, horizontal scroll) - no separator
          if (hasImages)
            _buildInlineImagePreviews(),
          
          // Text input row with mic/send buttons
          _buildTextInputRow(hasText),
        ],
      ),
    );
  }

  /// Research mode pill INSIDE the input box (ChatGPT style)
  Widget _buildInlineResearchPill() {
    dynamic icon;
    String label;
    
    switch (widget.researchMode) {
      case 'deep_research':
        icon = HugeIcons.strokeRoundedBrain;
        label = 'Deep Research';
        break;
      case 'shopping':
        icon = HugeIcons.strokeRoundedShoppingCart01;
        label = 'Shopping';
        break;
      case 'web_search':
      default:
        icon = HugeIcons.strokeRoundedSearch01;
        label = 'Search';
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 10, right: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, size: 14, color: const Color(0xFF0EA5E9)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0EA5E9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: widget.onClearResearchMode,
              child: Icon(
                Icons.close,
                size: 14,
                color: Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Image previews INSIDE the input box (horizontal scroll)
  Widget _buildInlineImagePreviews() {
    return Container(
      height: 72,
      padding: const EdgeInsets.only(left: 12, top: 8, right: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.attachedImages.length,
        itemBuilder: (context, index) {
          final image = widget.attachedImages[index];
          return Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    image,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => widget.onRemoveImage?.call(image),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
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

  /// Text input row: [Text area + Zoom] [Mic] [Send]
  Widget _buildTextInputRow(bool hasText) {
    // Watch voice provider for overlay data
    final voiceData = ref.watch(voiceInputProvider);
    final isVoiceActive = voiceData.state == VoiceInputState.listening || 
                          voiceData.state == VoiceInputState.thinking ||
                          voiceData.state == VoiceInputState.finalizing;
    
    // Voice Mode Layout (ChatGPT-style) - REFACTORED
    // Instead of replacing the row, we overlay/modify the input behavior
    if (widget.isVoiceListening) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      
      return Container(
        height: 110, // Expanded height for voice mode
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Left: Cancel Button (X) + Loading Animation
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Round Loading Animation (ChatGPT style)
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDarkMode ? Colors.white : const Color(0xFF10A37F),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1500.ms, color: isDarkMode ? Colors.white24 : Colors.green.shade100),
                ),
                
                // Cancel Button (X)
                GestureDetector(
                  onTap: widget.onVoiceCancel,
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(bottom: 1),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: AppColors.secondaryText, size: 20),
                  ),
                ),
              ],
            ),
            
            // Center: Stacked Overlay + Waveform
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                   // Base: "See text" placeholder
                   Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'See text',
                        style: TextStyle(
                          color: AppColors.primaryText.withValues(alpha: 0.5),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const VoiceWaveformBars(height: 24, barCount: 20),
                    ],
                  ),
                  
                  // Overlay: Partial Text (only when active)
                  if (isVoiceActive && (voiceData.transcribedText?.isNotEmpty ?? false))
                    Positioned.fill(
                      child: VoiceListeningOverlay(
                        text: voiceData.transcribedText ?? '',
                        isThinking: voiceData.state == VoiceInputState.thinking,
                      ),
                    ),
                ],
              ),
            ),
            
            // Right: Send Button (Up Arrow)
            _buildSendButton(hasText),
          ],
        ),
      );
    }

    // Default Text Input Layout
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 6, top: 6, bottom: 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             // Text input (Normal state)
             Expanded(
               child: ConstrainedBox(
                 constraints: BoxConstraints(
                   minHeight: 36,
                   maxHeight: (_maxLines * _baseLineHeight) + _basePadding,
                 ),
                 child: SingleChildScrollView(
                   reverse: true,
                   child: TextField(
                     controller: widget.controller,
                     focusNode: widget.focusNode,
                     style: TextStyle(
                       color: AppColors.primaryText,
                       fontSize: 15,
                       height: 1.4,
                     ),
                     decoration: InputDecoration(
                       hintText: widget.hintText,
                       hintStyle: TextStyle(color: AppColors.secondaryText),
                       border: InputBorder.none,
                       contentPadding: EdgeInsets.zero,
                       isDense: true,
                     ),
                     maxLines: null,
                     enabled: !widget.isStreaming,
                     textInputAction: TextInputAction.newline,
                     keyboardType: TextInputType.multiline,
                     textAlignVertical: TextAlignVertical.center,
                   ),
                 ),
               ),
             ),
            
            const SizedBox(width: 6),
            
            // Right side: Column with [Zoom (optional)] + [Mic + Send row]
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom button - appears aligned with first line when 4+ lines
                if (hasText && _lineCount >= 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 6), // Align with first text line
                    child: GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenTextEditor(
                              initialText: widget.controller.text,
                            ),
                          ),
                        );
                        if (result != null && result is String) {
                          widget.controller.text = result;
                        }
                      },
                      child: Icon(
                        Icons.open_in_full,
                        size: 16,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  )
                else
                   // Spacer placeholder to ensure buttons stay at bottom if no zoom
                   const SizedBox(height: 0),

                if (hasText && _lineCount >= 4)
                  const Spacer(),
                
                // Mic + Send row at bottom
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mic button - visible when no text OR voice-converted text, AND NOT LISTENING
                    if ((!hasText || widget.isVoiceConvertedText) && !widget.isStreaming)
                      _buildMicButton(),
                    
                    if ((!hasText || widget.isVoiceConvertedText) && !widget.isStreaming)
                      const SizedBox(width: 4),
                    
                    // Send/Stop button
                    _buildSendButton(hasText),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Fixed attachment button (+)
  Widget _buildAttachmentButton() {
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(Icons.add, color: AppColors.primaryText),
        onPressed: widget.onAttachmentTap,
        padding: EdgeInsets.zero,
        tooltip: 'Attach',
      ),
    );
  }

  /// Microphone button inside input
  Widget _buildMicButton() {
    return GestureDetector(
      onTap: widget.onVoiceTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedMic02,
            size: 20,
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  /// Send/Stop button (fixed right position, never moves)
  Widget _buildSendButton(bool hasText) {
    return Container(
      width: 35,
      height: 35,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          widget.isStreaming
              ? Icons.stop
              : (hasText || widget.isVoiceListening) // Show send arrow if text OR listening
                  ? Icons.arrow_upward
                  : Icons.graphic_eq,
          color: Colors.black87,
          size: 22,
        ),
        onPressed: widget.isStreaming
            ? widget.onCancelStream
            : widget.isVoiceListening
                ? widget.onVoiceStopAndSend // Direct Stop & Send
                : hasText
                    ? widget.onSend
                    : widget.onVoiceTap,
        padding: EdgeInsets.zero,
        tooltip: widget.isStreaming
            ? 'Stop generating'
            : hasText
                ? 'Send'
                : 'Voice mode',
      ),
    );
  }
}

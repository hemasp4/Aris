import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final VoidCallback? onVoiceRestart; // New: Restart voice recording
  final VoidCallback? onCancelStream;
  final VoidCallback? onClearResearchMode;
  final Function(File)? onRemoveImage;

  const ExpandableInputBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = 'Ask Aris',
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
    this.onVoiceRestart,
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
  void didUpdateWidget(covariant ExpandableInputBox oldWidget) {
    super.didUpdateWidget(oldWidget);

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
    
    // Watch voice state for the Floating Preview Box
    final voiceData = ref.watch(voiceInputProvider);
    final isVoiceActive = voiceData.state == VoiceInputState.listening || 
                          voiceData.state == VoiceInputState.thinking || 
                          voiceData.state == VoiceInputState.finalizing;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Floating Preview Box (Above Input)
              if (isVoiceActive && (voiceData.transcribedText?.isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 48, right: 48), // Centered above input
                  child: VoiceListeningOverlay(
                    text: voiceData.transcribedText ?? '',
                    isThinking: voiceData.state == VoiceInputState.thinking,
                  ),
                ),

              // 2. Main Input Row
              Row(
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // ChatGPT Style: Deep dark/black background with blur
    // The user's image shows a very dark, neutral pill.
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(26), // Reverted to 26 as requested (less rounded)
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Stronger blur
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            // ChatGPT-style: glassmorphic with transparency + blur
            color: isDarkMode 
                ? const Color(0xFF1A1A1A).withValues(alpha: 0.95) 
                : const Color(0xFFFFFFFF).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
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
        ),
      ),
    );
  }

  /// Research mode pill INSIDE the input box (ChatGPT style)
  Widget _buildInlineResearchPill() {
    dynamic icon;
    String pillText = "";
    
    switch (widget.researchMode) {
      case 'deep_research':
        icon = HugeIcons.strokeRoundedBrain;
        pillText = "Deep Research";
        break;
      case 'shopping':
        icon = HugeIcons.strokeRoundedShoppingCart01;
        pillText = "Shopping";
        break;
      case 'web_search':
        icon = HugeIcons.strokeRoundedSearch01;
        pillText = "Web Search";
        break;
      default:
        icon = HugeIcons.strokeRoundedSearch01;
        pillText = "Search";
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 10, right: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8), // Darker, more distinct pill
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, size: 14, color: Colors.white), // White text/icon for contrast
            const SizedBox(width: 6),
            Text(
              pillText, 
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onClearResearchMode,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 10, color: Colors.white),
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
    
    // Voice Mode Layout (ChatGPT-style) - REFACTORED
    // Instead of replacing the row, we overlay/modify the input behavior
    if (widget.isVoiceListening) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final isProcessing = voiceData.state == VoiceInputState.thinking || 
                           voiceData.state == VoiceInputState.finalizing ||
                           voiceData.state == VoiceInputState.transcribing;
      
      // Check if we're in the noSpeech state
      final hasNoSpeech = voiceData.state == VoiceInputState.noSpeech;
      
      // ChatGPT-exact floating card layout - NOW TRANSPARENT to match outer pill
      // Removed excessive padding to let content fill the pill better
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent, 
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              // Top section: Loading indicator at top-left (when processing)
              if (isProcessing)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 12, right: 16, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDarkMode ? Colors.white70 : const Color(0xFF10A37F),
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Main content area: "See text" or waveform or "No speech detected"
              if (!isProcessing && !hasNoSpeech)
                GestureDetector(
                  onTap: widget.onVoiceStopAndSend,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      'See text',
                      style: TextStyle(
                        color: isDarkMode 
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              
              // Bottom row: [X] [Waveform/No speech message] [↑/Retry]
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // X button (cancel)
                    GestureDetector(
                      onTap: widget.onVoiceCancel,
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(top: 20),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close,
                            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Center: Waveform OR "No speech detected" message
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onVoiceStopAndSend,
                        child: hasNoSpeech
                            ? Center(
                                child: Text(
                                  'No speech detected',
                                  style: TextStyle(
                                    color: isDarkMode 
                                        ? Colors.white.withValues(alpha: 0.5)
                                        : Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : const VoiceWaveformBars(height: 28, barCount: 30),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Right: Send button OR Retry button (when no speech)
                    GestureDetector(
                      onTap: hasNoSpeech 
                          ? widget.onVoiceTap  // Retry - start recording again
                          : widget.onVoiceStopAndSend,  // Send/finalize
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(top: 20),
                        decoration: BoxDecoration(
                          color: hasNoSpeech
                              ? (isDarkMode ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300)
                              : (isDarkMode ? Colors.white : Colors.black),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: hasNoSpeech
                              ? Icon(
                                  Icons.refresh,
                                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                  size: 20,
                                )
                              : Icon(
                                  Icons.arrow_upward,
                                  color: isDarkMode ? Colors.black : Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    
    // Responsive font scaling
    final textScaler = MediaQuery.textScalerOf(context);
    final scaledFontSize = 15.0 * textScaler.scale(1.0).clamp(0.8, 1.3);

    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 6, top: 4, bottom: 4),
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
                   child: TextField(
                     controller: widget.controller,
                     focusNode: widget.focusNode,
                     style: TextStyle(
                       color: AppColors.primaryText,
                       fontSize: scaledFontSize,
                       height: 1.4,
                     ),
                     decoration: InputDecoration(
                       hintText: widget.hintText,
                       hintStyle: TextStyle(color: AppColors.secondaryText),
                       border: InputBorder.none,
                       enabledBorder: InputBorder.none,
                       focusedBorder: InputBorder.none,
                       filled: false, // Override global theme
                       fillColor: Colors.transparent, // Ensure transparency
                       contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // Adjusted padding (vertical 12 as requested)
                       isDense: true,
                     ),
                     maxLines: null,
                     enabled: !widget.isStreaming && !widget.isVoiceListening, // Lock input during voice
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
                      child: Icon( // Keep Zoom as standard icon or switch? Standard is fine for util.
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
                    // Mic button - visible when no text, OR if text is from voice
                    if (!widget.isStreaming)
                      if (!hasText)
                        _buildMicButton()
                      else if (widget.isVoiceConvertedText)
                        _buildReloadMicButton(),
                    
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Match the exact style of the input box (Deep Dark Glass) with same blur effect
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            // Match navbar/input box: glassmorphic
            color: isDarkMode 
                ? const Color(0xFF1A1A1A).withValues(alpha: 0.95) 
                : const Color(0xFFFFFFFF).withValues(alpha: 0.95),
            shape: BoxShape.circle,
            border: Border.all(
               color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
               width: 1,
            ),
          ),
          child: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01, 
              color: isDarkMode ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.9), // Match other icons
              size: 24,
            ), 
            onPressed: widget.onAttachmentTap,
            padding: EdgeInsets.zero,
            tooltip: 'Attach',
          ),
        ),
      ),
    );
  }

  /// Microphone button inside input
  Widget _buildMicButton() {
    return GestureDetector(
      onTap: () {
        // debugPrint('[UI] Mic button tapped in ExpandableInputBox');
        widget.onVoiceTap?.call();
      },
      child: Container(
        width: 30,
        height: 30,
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

  /// Reload Voice button (Clear text + Restart Voice)
  Widget _buildReloadMicButton() {
    return GestureDetector(
      onTap: () {
        widget.controller.clear();
        // Use restart callback if available, otherwise fall back to onVoiceTap
        (widget.onVoiceRestart ?? widget.onVoiceTap)?.call();
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: HugeIcon(
            // When text is already present (converted), show Mic to restart, 
            // or we could show a special "Redo" icon. User asked for Mic icon change logic.
            // If we want "Redo", "refresh" is good.
            // But user said "after we converted... the mic icon changing so fix that also"
            // implying it should probably go back to Mic or allow adding more?
            // Actually, if we are in "See text" mode, usually we are done. 
            // Let's stick to mic but maybe filled? Or just keep Refresh.
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
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(left: 4,bottom: 2,right: 4),
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

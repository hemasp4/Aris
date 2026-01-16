import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_colors.dart';

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
  final List<File> attachedImages;
  final VoidCallback? onSend;
  final VoidCallback? onAttachmentTap;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onCancelStream;
  final Function(File)? onRemoveImage;

  const ExpandableInputBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = 'Message Aris...',
    this.isStreaming = false,
    this.isVoiceListening = false,
    this.attachedImages = const [],
    this.onSend,
    this.onAttachmentTap,
    this.onVoiceTap,
    this.onCancelStream,
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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image preview row (above input, if images attached)
              if (hasImages) _buildImagePreviewRow(),
              
              // Main input row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Fixed + button (left)
                  _buildAttachmentButton(),
                  
                  const SizedBox(width: 8),
                  
                  // Expandable input field
                  Expanded(
                    child: _buildInputField(hasText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Image preview row with horizontal scroll and remove buttons
  Widget _buildImagePreviewRow() {
    return Container(
      height: 72,
      margin: const EdgeInsets.only(bottom: 8, left: 52), // Align with input
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Image thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.file(
                    image,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                
                // Remove button (X)
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => widget.onRemoveImage?.call(image),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
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

  /// Expandable input field with animated height
  Widget _buildInputField(bool hasText) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      constraints: BoxConstraints(
        minHeight: _minHeight,
        maxHeight: _minHeight + ((_maxLines - 1) * _baseLineHeight),
      ),
      padding: const EdgeInsets.only(left: 16, right: 6, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field - expands vertically
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (_maxLines * _baseLineHeight) + _basePadding,
              ),
              child: SingleChildScrollView(
                // Enable internal scroll after max lines
                reverse: true, // Keep cursor visible at bottom
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                  maxLines: null, // Allow unlimited lines (scroll handles it)
                  enabled: !widget.isStreaming && !widget.isVoiceListening,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Microphone button (only when no text and not streaming)
          if (!hasText && !widget.isStreaming)
            _buildMicButton(),
          
          const SizedBox(width: 4),
          
          // Send/Stop/Voice button (fixed position)
          _buildSendButton(hasText),
        ],
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
            icon: HugeIcons.strokeRoundedMic01,
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
              : hasText
                  ? Icons.arrow_upward
                  : Icons.graphic_eq,
          color: Colors.black87,
          size: 22,
        ),
        onPressed: widget.isStreaming
            ? widget.onCancelStream
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

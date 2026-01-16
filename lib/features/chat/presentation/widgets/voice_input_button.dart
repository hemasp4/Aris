import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/voice_input_provider.dart';
import 'voice_waveform_widget.dart';

/// Voice input button with 3 states: idle, listening, transcribing
/// ChatGPT-exact behavior:
/// - IDLE: Mic icon with tooltip "Voice input"
/// - LISTENING: Pulsing mic with white waveform
/// - TRANSCRIBING: Waveform stops, loading indicator
class VoiceInputButton extends ConsumerWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const VoiceInputButton({
    super.key,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceInput = ref.watch(voiceInputProvider);
    final isRecording = voiceInput.state == VoiceInputState.listening;
    final isTranscribing = voiceInput.state == VoiceInputState.transcribing;

    return Tooltip(
      message: 'Voice input',
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: (_) => onLongPressStart(),
        onLongPressEnd: (_) => onLongPressEnd(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isRecording 
                ? AppColors.accent.withValues(alpha: 0.15)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse animation for listening state
              if (isRecording)
                _PulseAnimation(amplitude: voiceInput.amplitude),
              
              // Loading indicator for transcribing state
              if (isTranscribing)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.secondaryText,
                  ),
                ),
              
              // Icon
              if (!isTranscribing)
                Icon(
                  isRecording ? Icons.mic : Icons.mic_none_outlined,
                  color: isRecording ? AppColors.accent : AppColors.secondaryText,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulse animation that reacts to audio amplitude
class _PulseAnimation extends StatefulWidget {
  final double amplitude;

  const _PulseAnimation({required this.amplitude});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (widget.amplitude * 0.4) + 
            (math.sin(_controller.value * 2 * math.pi) * 0.08);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.2 - (_controller.value * 0.15)),
            ),
          ),
        );
      },
    );
  }
}

/// Voice waveform animation for more advanced visualization (legacy)
class VoiceWaveform extends ConsumerWidget {
  const VoiceWaveform({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the new waveform widget
    return const VoiceWaveformBars(
      height: 40,
      barCount: 7,
    );
  }
}

/// Full-screen voice recording overlay
class VoiceRecordingOverlay extends ConsumerWidget {
  final VoidCallback onCancel;
  final VoidCallback onStop;

  const VoiceRecordingOverlay({
    super.key,
    required this.onCancel,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceInput = ref.watch(voiceInputProvider);
    final isListening = voiceInput.state == VoiceInputState.listening;
    final isTranscribing = voiceInput.state == VoiceInputState.transcribing;

    if (voiceInput.state == VoiceInputState.idle) {
      return const SizedBox.shrink();
    }

    return Container(
      color: AppColors.backgroundMain.withValues(alpha: 0.95),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // Status text
            Text(
              isTranscribing ? 'Transcribing...' : 'Listening...',
              style: GoogleFonts.inter(
                color: AppColors.primaryText,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(duration: 200.ms),
            
            const SizedBox(height: 48),
            
            // Waveform or loading
            if (isListening)
              const LargeVoiceWaveform()
            else if (isTranscribing)
              CircularProgressIndicator(
                color: AppColors.accent,
              ),
            
            const Spacer(),
            
            // Control buttons
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close),
                    iconSize: 32,
                    color: AppColors.secondaryText,
                  ),
                  
                  // Stop button
                  if (isListening)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: onStop,
                        icon: const Icon(Icons.stop),
                        iconSize: 36,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

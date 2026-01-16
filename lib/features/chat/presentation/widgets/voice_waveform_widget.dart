import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/voice_input_provider.dart';

/// ChatGPT-exact white pulse waveform for voice input
/// Appears INSIDE the input box during LISTENING state
/// 
/// Specifications:
/// - Color: pure white (#FFFFFF), ~85% opacity
/// - Height: 14-18px
/// - 5-7 vertical bars, 2-3px width, ~2px gap, rounded edges
/// - Driven ONLY by microphone amplitude
/// - Smooth interpolation, ~30-45 FPS
/// - Duration per pulse: 120-180ms
class VoiceWaveformBars extends ConsumerStatefulWidget {
  final double height;
  final int barCount;
  
  const VoiceWaveformBars({
    super.key,
    this.height = 16,
    this.barCount = 5,
  });

  @override
  ConsumerState<VoiceWaveformBars> createState() => _VoiceWaveformBarsState();
}

class _VoiceWaveformBarsState extends ConsumerState<VoiceWaveformBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Keep track of smoothed amplitude values for each bar
  List<double> _barHeights = [];
  double _lastAmplitude = 0.0;

  @override
  void initState() {
    super.initState();
    _barHeights = List.filled(widget.barCount, 0.3);
    
    // Animation runs at ~33ms intervals (~30 FPS)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    )..repeat();
    
    _controller.addListener(_updateBars);
  }

  void _updateBars() {
    if (!mounted) return;
    
    final amplitude = ref.read(voiceAmplitudeProvider);
    
    // Smooth interpolation between current and target amplitude
    _lastAmplitude = _lastAmplitude + (amplitude - _lastAmplitude) * 0.3;
    
    setState(() {
      for (int i = 0; i < widget.barCount; i++) {
        // Create wave effect with phase offset for each bar
        final phase = (_controller.value * 2 * math.pi) + (i * 0.5);
        final waveOffset = math.sin(phase) * 0.15;
        
        // Base height + amplitude contribution + wave motion
        final targetHeight = 0.3 + (_lastAmplitude * 0.6) + waveOffset;
        
        // Smooth interpolation for each bar
        _barHeights[i] = _barHeights[i] + (targetHeight - _barHeights[i]) * 0.2;
        _barHeights[i] = _barHeights[i].clamp(0.2, 1.0);
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateBars);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: (widget.barCount * 3) + ((widget.barCount - 1) * 2).toDouble(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index < widget.barCount - 1 ? 2 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              width: 3,
              height: widget.height * _barHeights[index],
              decoration: BoxDecoration(
                color: AppColors.waveformPurple,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Compact voice waveform for inline use in input field
class InlineVoiceWaveform extends ConsumerWidget {
  const InlineVoiceWaveform({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceInputProvider);
    
    // Only show during listening state
    if (voiceState.state != VoiceInputState.listening) {
      return const SizedBox.shrink();
    }
    
    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: VoiceWaveformBars(
        height: 16,
        barCount: 5,
      ),
    );
  }
}

/// Larger voice waveform for overlay/full-screen mode
class LargeVoiceWaveform extends ConsumerStatefulWidget {
  const LargeVoiceWaveform({super.key});

  @override
  ConsumerState<LargeVoiceWaveform> createState() => _LargeVoiceWaveformState();
}

class _LargeVoiceWaveformState extends ConsumerState<LargeVoiceWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amplitude = ref.watch(voiceAmplitudeProvider);
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // Outer pulse ring
        final pulseScale = 1.0 + (_pulseController.value * 0.3);
        final pulseOpacity = (1.0 - _pulseController.value) * 0.3;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing background ring
            Transform.scale(
              scale: pulseScale,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: pulseOpacity),
                    width: 2,
                  ),
                ),
              ),
            ),
            
            // Amplitude-reactive ring
            Container(
              width: 100 + (amplitude * 20),
              height: 100 + (amplitude * 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.1 + (amplitude * 0.1)),
              ),
            ),
            
            // Inner waveform bars (larger version)
            const VoiceWaveformBars(
              height: 40,
              barCount: 7,
            ),
          ],
        );
      },
    );
  }
}

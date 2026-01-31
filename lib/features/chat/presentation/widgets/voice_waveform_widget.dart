import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/voice_input_provider.dart';

/// ChatGPT-Style Waveform with Right-to-Left Flow
class WaveformController extends ChangeNotifier {
  final int barCount; 
  
  // The buffer of amplitudes. We essentially have a "tape" moving left.
  late final List<double> amplitudes;
  
  // Global energy envelope
  double _energy = 0.0;
  
  // Tuning for ChatGPT-like feel
  final double attack = 0.5;   // Fast rise
  final double decay = 0.1;    // Slow fall for smooth tail
  final double flowSpeed = 0.5; // Blend factor for propagation

  final math.Random _rand = math.Random();
  
  WaveformController({this.barCount = 40}) { // Default 40 for smooth flow
     amplitudes = List.filled(barCount, 0.1);
  }

  /// Update loop called by widget ticker
  void update(double inputAmplitude) {
    // 1. Smooth the energy envelope
    if (inputAmplitude > _energy) {
      _energy = _energy + (inputAmplitude - _energy) * attack;
    } else {
      _energy = _energy + (inputAmplitude - _energy) * decay;
    }
    
    // 2. "Alive" Animation Logic
    // Instead of scrolling history, we update ALL bars to react to the current energy.
    // We simulate "frequency bands" by assigning random sensitivities to each bar, 
    // but they all pulse with the main energy.
    final t = DateTime.now().millisecondsSinceEpoch / 2000.0;
    
    for (int i = 0; i < barCount; i++) {
      // Base height from energy
      double barHeight = _energy;
      
      // Add "breathing" / "noise" to make it feel organic and not just a single solid block
      // Sine wave offset to make bars ripple slightly even when energy is constant
      double noise = math.sin((i * 0.5) + (t * 5.0)) * 0.2; 
      
      // Random jitter per bar to look like FFT
      double jitter = _rand.nextDouble() * 0.3;
      
      // Combine
      double value = barHeight * (0.7 + noise + jitter);
      
      // Center bias: Make center bars generally taller (bell curve shape)
      // Normalized position -1 to 1
      double pos = (i - barCount / 2) / (barCount / 2);
      double bellCurve = 1.0 - (pos * pos); // Parabola peaking at center
      
      // Apply bell curve but keep some height at edges
      value = value * (0.3 + 0.7 * bellCurve);
      
      // Clamp
      amplitudes[i] = value.clamp(0.05, 1.0);
    }
    
    notifyListeners();
  }
}

class VoiceWaveformBars extends ConsumerStatefulWidget {
  final double height;
  final int barCount; 
  
  const VoiceWaveformBars({
    super.key,
    this.height = 24,
    this.barCount = 40, // Increased default for flow effect
  });

  @override
  ConsumerState<VoiceWaveformBars> createState() => _VoiceWaveformBarsState();
}

class _VoiceWaveformBarsState extends ConsumerState<VoiceWaveformBars> 
    with SingleTickerProviderStateMixin {
      
  late WaveformController _controller;
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _controller = WaveformController(barCount: widget.barCount);
    
    // Ticker ensures smooth ~60FPS updates for the flow animation
    _ticker = createTicker((elapsed) {
      // Get latest amplitude from provider
      // We read directly to avoid full widget rebuilds, we just want the value to feed controller
      // Accessing provider inside ticker callback is safe? 
      // Better to use ref.read inside update loop if possible, or watch in build and cache.
      // Since we can't context.read in ticker easily without context, 
      // we'll rely on the build method to update a local variable OR check provider here.
      // Actually, we can use a post-frame callback or just ref.read if we have ref.
      
      final state = ref.read(voiceInputProvider);
      double input = 0.0;
      
      if (state.state == VoiceInputState.listening) {
        input = state.amplitude;
      }
      
      _controller.update(input);
    });
    
    _ticker.start();
    
    // Rebuild when controller data changes
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(
        painter: WaveformPainter(
          amplitudes: _controller.amplitudes,
          barCount: widget.barCount,
          color: Colors.white.withValues(alpha: 0.9), // Pure white, slightly transparent
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final int barCount;
  final Color color;

  WaveformPainter({
    required this.amplitudes, 
    required this.barCount, 
    required this.color
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Calculate dynamic widths based on available space
    final totalGapRatio = 0.4; // 40% of space is gaps
    final singleUnit = size.width / (barCount + (barCount - 1) * totalGapRatio);
    final barWidth = 3.0; // Fixed thin bars look better for ChatGPT style
    final gap = 2.0;
    
    // We want to center the waveform visual in the available width
    // Or just fill it. Let's use fixed thin bars.
    final totalWidth = (barCount * barWidth) + ((barCount - 1) * gap);
    final startX = (size.width - totalWidth) / 2; // Center alignment check? 
    // Actually user wants "Input box style" which implies this is inside the input box?
    // The previous image shows it left aligned. 
    // The simplified version: just draw from left 0 if we assume exact width.
    // The widget usage usually puts it in a constrained box.
    
    double currentX = 0; // Align left
    
    // Center Y
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final amp = amplitudes[i];
      // Min height for dot
      double h = 4.0 + (amp * (size.height - 4.0)); 
      h = h.clamp(4.0, size.height);
      
      // Radius
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(currentX + barWidth/2, centerY), 
          width: barWidth, 
          height: h
        ),
        const Radius.circular(2),
      );
      
      // Opacity falloff at the tail (left side) for smooth exit
      // i=0 is tail, i=count-1 is head
      double opacity = 1.0;
      if (i < 5)  opacity = i / 5;
      
      paint.color = color.withValues(alpha: 0.9 * opacity);
      
      canvas.drawRRect(r, paint);
      
      currentX += barWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}

/// Large Voice Waveform for full-screen overlay
class LargeVoiceWaveform extends ConsumerWidget {
  const LargeVoiceWaveform({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox(
      width: 200,
      height: 80,
      child: VoiceWaveformBars(
        height: 80,
        barCount: 30,
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/voice_input_provider.dart';

/// ChatGPT-Style Waveform Controller
class ChatGPTWaveformController extends ChangeNotifier {
  final int barCount;
  
  // Frozen bar heights (once pushed, never change)
  late final List<double> frozenBars;
  
  // Smoothed volume for next bar
  double _smoothedVol = 0;
  double _lastPushTime = 0;
  double _simTime = 0;
  
  // Tuning parameters
  static const double pushIntervalMs = 90;
  static const double attackSpeed = 14;
  static const double releaseSpeed = 2.8;
  static const double minBarHeight = 0.05; // Minimum visible bar
  
  ChatGPTWaveformController({this.barCount = 60}) {
    frozenBars = List.filled(barCount, minBarHeight, growable: true);
  }
  
  /// Update loop - called every frame by ticker
  void update(double inputAmplitude, double elapsedMs, {bool simulationMode = false}) {
    const dt = 0.016; // ~60fps
    
    // Get volume (real or simulated)
    double vol = simulationMode ? _getSimulatedVolume() : inputAmplitude;
    
    // Smooth with fast attack / slow release
    if (vol > _smoothedVol) {
      _smoothedVol += (vol - _smoothedVol) * attackSpeed * dt;
    } else {
      _smoothedVol += (vol - _smoothedVol) * releaseSpeed * dt;
    }
    _smoothedVol = _smoothedVol.clamp(0, 1);
    
    // Push frozen bar at intervals
    if (elapsedMs - _lastPushTime >= pushIntervalMs) {
      _lastPushTime = elapsedMs;
      frozenBars.removeAt(0);  // Remove oldest (left)
      frozenBars.add(_smoothedVol.clamp(minBarHeight, 1.0));  // Add newest (right)
    }
    
    notifyListeners();
  }
  
  /// Organic speech-like volume simulation
  double _getSimulatedVolume() {
    _simTime += 0.016;
    final t = _simTime;
    
    final breathCycle = (math.sin(t * 0.8) * 0.5 + 0.5);
    final syllable = (math.sin(t * 5.5) * 0.5 + 0.5);
    final variation = (math.sin(t * 13.7) * 0.3 + 0.7);
    final pause = math.sin(t * 0.3) > 0.2 ? 1.0 : 0.08;
    final burst = math.Random().nextDouble() > 0.92 
        ? math.Random().nextDouble() * 0.4 
        : 0.0;
    
    return math.min(1.0, (breathCycle * 0.4 + syllable * 0.6 + burst) * variation * pause);
  }
  
  void reset() {
    frozenBars.fillRange(0, barCount, minBarHeight);
    _smoothedVol = 0;
    _lastPushTime = 0;
    _simTime = 0;
    notifyListeners();
  }
}

/// ChatGPT-Style Waveform Widget
class VoiceWaveformBars extends ConsumerStatefulWidget {
  final double height;
  final int barCount; 
  
  const VoiceWaveformBars({
    super.key,
    this.height = 24,
    this.barCount = 60,
  });

  @override
  ConsumerState<VoiceWaveformBars> createState() => _VoiceWaveformBarsState();
}

class _VoiceWaveformBarsState extends ConsumerState<VoiceWaveformBars> 
    with SingleTickerProviderStateMixin {
      
  late ChatGPTWaveformController _controller;
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _controller = ChatGPTWaveformController(barCount: widget.barCount);
    
    _ticker = createTicker((elapsed) {
      final state = ref.read(voiceInputProvider);
      
      if (state.state == VoiceInputState.listening) {
        final hasRealAmplitude = state.amplitude > 0.05; 
        
        _controller.update(
          hasRealAmplitude ? state.amplitude : 0.0,
          elapsed.inMilliseconds.toDouble(),
          simulationMode: !hasRealAmplitude,
        );
      }
    });
    
    _ticker.start();
    
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: CustomPaint(
            painter: ChatGPTWaveformPainter(
              frozenBars: _controller.frozenBars,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for ChatGPT-style waveform
class ChatGPTWaveformPainter extends CustomPainter {
  final List<double> frozenBars;
  final Color color;
  
  // Bar dimensions (ChatGPT-exact)
  static const double barWidth = 3.0;
  static const double gap = 1.5;
  static const double step = barWidth + gap;

  ChatGPTWaveformPainter({
    required this.frozenBars, 
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final numBars = frozenBars.length;
    final totalWidth = numBars * step;
    
    // Draw from right to left (newest on right)
    // CRITICAL: Right alignment required to see newest data (index 299) which is at the end of the array.
    // Centering pushes the live data off-screen if barCount is large.
    final startX = size.width - totalWidth;
    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.88;
    final minBarHeight = 2.0; // Match reference (1.5 -> 2.0)

    for (int i = 0; i < numBars; i++) {
      final x = startX + i * step;
      
      // Skip bars outside visible area
      if (x + barWidth < 0 || x > size.width) continue;
      
      // Calculate bar height from frozen amplitude
      final amp = frozenBars[i];
      final barH = minBarHeight + (amp * (maxBarHeight - minBarHeight));
      final y = centerY - barH / 2;
      
      // NO FADING (Solid bars as requested)

      // Draw rounded bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barH),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ChatGPTWaveformPainter oldDelegate) => true;
}

/// Large Voice Waveform for full-screen overlay (if needed)
class LargeVoiceWaveform extends ConsumerWidget {
  const LargeVoiceWaveform({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox(
      width: 200,
      height: 80,
      child: VoiceWaveformBars(
        height: 80,
        barCount: 40,
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// Voice input state enum
enum VoiceInputState {
  idle,
  listening,
  transcribing,
}

/// Voice input data model
class VoiceInputData {
  final VoiceInputState state;
  final double amplitude;
  final String? transcribedText;
  final String? error;
  final String? audioPath;

  const VoiceInputData({
    this.state = VoiceInputState.idle,
    this.amplitude = 0.0,
    this.transcribedText,
    this.error,
    this.audioPath,
  });

  VoiceInputData copyWith({
    VoiceInputState? state,
    double? amplitude,
    String? transcribedText,
    String? error,
    String? audioPath,
  }) {
    return VoiceInputData(
      state: state ?? this.state,
      amplitude: amplitude ?? this.amplitude,
      transcribedText: transcribedText ?? this.transcribedText,
      error: error ?? this.error,
      audioPath: audioPath ?? this.audioPath,
    );
  }
}

/// Voice input notifier for managing recording state
class VoiceInputNotifier extends StateNotifier<VoiceInputData> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _amplitudeTimer;
  
  VoiceInputNotifier() : super(const VoiceInputData());

  /// Check if microphone permission is granted
  Future<bool> checkPermission() async {
    if (kIsWeb) {
      return await _recorder.hasPermission();
    }
    
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }
    
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Start recording audio
  Future<void> startRecording() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        state = state.copyWith(
          error: 'Microphone permission denied',
        );
        return;
      }

      // Check if recorder is available
      if (!await _recorder.hasPermission()) {
        state = state.copyWith(
          error: 'Microphone not available',
        );
        return;
      }

      // Configure recording
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      );

      // Start recording to a temporary file
      String path;
      if (kIsWeb) {
        path = '';
      } else if (Platform.isAndroid || Platform.isIOS) {
        path = '/tmp/aris_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      } else {
        path = 'aris_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      }

      await _recorder.start(config, path: path);
      
      state = state.copyWith(
        state: VoiceInputState.listening,
        amplitude: 0.0,
        error: null,
        audioPath: path,
      );

      // Start amplitude monitoring
      _startAmplitudeMonitoring();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to start recording: $e',
      );
    }
  }

  /// Start monitoring audio amplitude for animation
  void _startAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      try {
        final amp = await _recorder.getAmplitude();
        // Normalize amplitude to 0-1 range
        // dB values typically range from -60 (silence) to 0 (max)
        final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
        state = state.copyWith(amplitude: normalized);
      } catch (_) {
        // Ignore amplitude errors
      }
    });
  }

  /// Stop recording and prepare for transcription
  Future<String?> stopRecording() async {
    _amplitudeTimer?.cancel();
    
    try {
      final path = await _recorder.stop();
      
      state = state.copyWith(
        state: VoiceInputState.transcribing,
        amplitude: 0.0,
        audioPath: path,
      );
      
      return path;
    } catch (e) {
      state = state.copyWith(
        state: VoiceInputState.idle,
        error: 'Failed to stop recording: $e',
      );
      return null;
    }
  }

  /// Set transcription result
  void setTranscription(String text) {
    state = state.copyWith(
      state: VoiceInputState.idle,
      transcribedText: text,
    );
  }

  /// Set transcription error
  void setTranscriptionError(String error) {
    state = state.copyWith(
      state: VoiceInputState.idle,
      error: error,
    );
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    _amplitudeTimer?.cancel();
    
    try {
      await _recorder.stop();
    } catch (_) {}
    
    state = const VoiceInputData();
  }

  /// Reset state
  void reset() {
    state = const VoiceInputData();
  }

  @override
  void dispose() {
    _amplitudeTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}

/// Voice input provider
final voiceInputProvider = StateNotifierProvider<VoiceInputNotifier, VoiceInputData>((ref) {
  return VoiceInputNotifier();
});

/// Is recording provider
final isRecordingProvider = Provider<bool>((ref) {
  return ref.watch(voiceInputProvider).state == VoiceInputState.listening;
});

/// Is transcribing provider
final isTranscribingProvider = Provider<bool>((ref) {
  return ref.watch(voiceInputProvider).state == VoiceInputState.transcribing;
});

/// Voice amplitude provider
final voiceAmplitudeProvider = Provider<double>((ref) {
  return ref.watch(voiceInputProvider).amplitude;
});

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// Voice input state enum
enum VoiceInputState {
  idle,
  listening,
  thinking, // New "Thinking Pause" state
  finalizing, // Computing final text
  transcribing, // Used for Finalizing/Submit
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
  StreamSubscription? _audioStreamSubscription;
  WebSocketChannel? _channel;
  
  VoiceInputNotifier() : super(const VoiceInputData());

  /// Check permissions
  Future<bool> checkPermission() async {
    if (kIsWeb) return await _recorder.hasPermission();
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Start Streaming (Real-time)
  Future<void> startRecording() async {
    // 0. Immediate UI Feedback
    state = state.copyWith(
      state: VoiceInputState.listening,
      amplitude: 0.0,
      error: null,
    );

    try {
      if (!await checkPermission()) {
        state = state.copyWith(
            state: VoiceInputState.idle, 
            error: 'Microphone permission denied');
        return;
      }

      // 1. Connect WebSocket
      print('[Voice] Step 1: Connecting WebSocket...');
      
      String baseUrl = 'localhost:8000';
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        baseUrl = '10.0.2.2:8000';
      }
      
      final wsUrl = Uri.parse('ws://$baseUrl/api/v1/voice/stream');
      _channel = WebSocketChannel.connect(wsUrl);
      print('[Voice] Step 1: WebSocket Connected');
      
      _channel!.stream.listen(
        (message) {
           // ... (listener implementation)
        },
        // ... (error handlers)
      );

      // 2. Start Audio Stream
      print('[Voice] Step 2: Starting Audio Recorder Stream...');
      try {
        final config = kIsWeb 
            ? const RecordConfig() // Let browser decide (usually WebM/Opus)
            : const RecordConfig(
                encoder: AudioEncoder.wav,
                sampleRate: 16000,
                numChannels: 1,
              );
              
        final stream = await _recorder.startStream(config);
        print('[Voice] Step 2: Stream Started Successfully');

        // 3. Pump audio to WebSocket
        print('[Voice] Step 3: Attaching Listener...');
        _audioStreamSubscription = stream.listen((data) {
           // ... (pump logic)
           if (_channel != null && _channel!.closeCode == null) {
              _channel!.sink.add(data);
              if (state.amplitude == 0.0) {
                  print('[Voice] First chunk sent: ${data.length} bytes');
              }
           }
        }, onError: (e) {
             print('[Voice] Stream error: $e');
        });

        _startAmplitudeMonitoring();

      } catch (recError) {
         print('[Voice] Recorder Error: $recError');
         state = state.copyWith(
             state: VoiceInputState.idle,
             error: 'Recorder failed: $recError');
         return; 
      }

    } catch (e) {
      state = state.copyWith(
          state: VoiceInputState.idle,
          error: 'Failed to start stream: $e');
    }
  }

  /// Stop Streaming
  Future<String?> stopRecording() async {
    _amplitudeTimer?.cancel();
    await _audioStreamSubscription?.cancel();
    _channel?.sink.close(); // Close WS
    await _recorder.stop();
    
    // In streaming mode, there is no "file path".
    // We return NULL or a dummy value, because text is already in state.transcribedText
    return null; 
  }

  /// Start monitoring audio amplitude for animation
  void _startAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      try {
        final amp = await _recorder.getAmplitude();
        final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
        state = state.copyWith(amplitude: normalized);
      } catch (_) {}
    });
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    _amplitudeTimer?.cancel();
    await _audioStreamSubscription?.cancel();
    _channel?.sink.close();
    await _recorder.stop();
    state = const VoiceInputData();
  }

  void setTranscription(String text) {
    state = state.copyWith(transcribedText: text);
  }

  void reset() {
    state = const VoiceInputData();
  }

  @override
  void dispose() {
    _amplitudeTimer?.cancel();
    _audioStreamSubscription?.cancel();
    _channel?.sink.close();
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

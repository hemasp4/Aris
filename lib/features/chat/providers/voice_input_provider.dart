import 'dart:async';

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart'; // Add uuid package dependency if missing, or use simple random string
import '../../../core/constants/api_constants.dart';
import '../../../core/services/dio_client.dart';

/// Voice input state enum (Strict Machine)
enum VoiceInputState {
  idle,
  requestingPermission, // New state
  listening,
  thinking, // "Transcribing..." / Uploading
  transcribing, // Explicit transcribing state
  finalizing, // Computing final text
  noSpeech, // Error state - "No speech detected"
}

/// Voice input data model with Session Isolation
class VoiceInputData {
  final String sessionId; // Critical: Unique ID for every mic tap
  final VoiceInputState state;
  final double amplitude; // Raw amplitude (0.0 - 1.0)
  final String? transcribedText; // Current transcription
  final String accumulatedText; // All transcriptions combined (ChatGPT style)
  final String? error;
  
  const VoiceInputData({
    required this.sessionId,
    this.state = VoiceInputState.idle,
    this.amplitude = 0.0,
    this.transcribedText,
    this.accumulatedText = '',
    this.error,
  });

  // Initial clean state
  factory VoiceInputData.initial() => const VoiceInputData(
    sessionId: '',
    state: VoiceInputState.idle,
    accumulatedText: '',
  );

  VoiceInputData copyWith({
    String? sessionId,
    VoiceInputState? state,
    double? amplitude,
    String? transcribedText,
    String? accumulatedText,
    String? error,
  }) {
    return VoiceInputData(
      sessionId: sessionId ?? this.sessionId,
      state: state ?? this.state,
      amplitude: amplitude ?? this.amplitude,
      transcribedText: transcribedText ?? this.transcribedText,
      accumulatedText: accumulatedText ?? this.accumulatedText,
      error: error ?? this.error,
    );
  }
}

/// Production-Grade Voice Notifier (Master Prompt Implementation)
class VoiceInputNotifier extends StateNotifier<VoiceInputData> {
  final AudioRecorder _recorder = AudioRecorder();
  
  // Platform Pipelines
  WebSocketChannel? _channel; // Mobile Streaming
  StreamSubscription? _audioStreamSubscription;
  Timer? _amplitudeTimer;
  
  VoiceInputNotifier() : super(VoiceInputData.initial());

  /// START NEW SESSION (Strict Isolation)
  Future<void> startRecording() async {
    // print('[Voice] Start called. Creating NEW clean session.');
    
    // 1. Strict Reset: Wipe everything EXCEPT accumulated text for append mode
    final newSessionId = const Uuid().v4();
    final previousAccumulated = state.accumulatedText; // Preserve for append
    state = VoiceInputData(
      sessionId: newSessionId,
      state: VoiceInputState.requestingPermission,
      amplitude: 0.0,
      transcribedText: null, // Clear current transcription
      accumulatedText: previousAccumulated, // PRESERVE previous accumulated text!
      error: null,
    );
    
    try {
      // 2. Permission Check
      if (!await _checkPermission()) {
        state = state.copyWith(state: VoiceInputState.idle, error: 'Microphone permission denied');
        return;
      }

      // 3. Platform Pipeline
      if (kIsWeb) {
        await _startWebPipeline();
      } else {
        await _startMobilePipeline();
      }
      
      // 4. Update State -> Listening
      state = state.copyWith(state: VoiceInputState.listening);
      
      // 5. Start Amplitude/Waveform Driver
      _startAmplitudeLoop();

    } catch (e) {
      // print('[Voice] Start failed: $e');
      _cleanup();
      state = state.copyWith(state: VoiceInputState.idle, error: 'Failed to start: $e');
    }
  }

  /// STOP & TRANSCRIBE
  Future<String?> stopRecording() async {
    // print('[Voice] Stop called. Session: ${state.sessionId}');
    
    if (state.state == VoiceInputState.idle) return null;
    
    // UI: Immediate Feedback -> Thinking
    state = state.copyWith(state: VoiceInputState.thinking, amplitude: 0.0);
    _amplitudeTimer?.cancel();
    
    String? finalText;
    
    try {
      if (kIsWeb) {
        finalText = await _stopWebPipeline();
      } else {
        finalText = await _stopMobilePipeline();
      }
    } catch (e) {
      // print('[Voice] Stop/Transcribe failed: $e');
      state = state.copyWith(error: 'Transcription failed');
    } finally {
      // Final Cleanup
      _cleanup();
    }
    
    // strict logic: If text found -> Idle (ready to send/edit). If empty -> NoSpeech.
    if (finalText != null && finalText.trim().isNotEmpty) {
      // Append to accumulated text (ChatGPT-style: multiple recordings add up)
      final newAccumulated = state.accumulatedText.isEmpty
          ? finalText.trim()
          : '${state.accumulatedText} ${finalText.trim()}';
      
      state = state.copyWith(
        state: VoiceInputState.idle, 
        transcribedText: finalText,
        accumulatedText: newAccumulated,
      );
      return newAccumulated; // Return full accumulated text for UI
    } else {
      state = state.copyWith(state: VoiceInputState.noSpeech);
      return null;
    }
  }

  /// CANCEL (Abort)
  Future<void> cancelRecording() async {
    // print('[Voice] Cancel called. Aborting session.');
    _cleanup();
    // Reset to clean idle
    state = VoiceInputData.initial();
  }

  // ----------------------------------------------------------------
  // WEB PIPELINE (Blob -> Upload)
  // ----------------------------------------------------------------
  Future<void> _startWebPipeline() async {
    // Record to memory (Opus/WebM)
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.opus), path: '');
  }

  Future<String?> _stopWebPipeline() async {
    // Stop returns blob URL
    final path = await _recorder.stop();
    if (path == null) return null;
    
    // print('[Voice-Web] Blob path: $path');
    return await _uploadBlob(path);
  }

  Future<String?> _uploadBlob(String blobUrl) async {
    try {
      // XHR fetch blob
      final blobResp = await http.get(Uri.parse(blobUrl));
      if (blobResp.statusCode != 200) return null;
      
      // Upload
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          blobResp.bodyBytes,
          filename: 'voice_input.webm',
        ),
      });
      
      final response = await dioClient.dio.post(
        '/media/audio/transcribe',
        data: formData,
      );
      
      if (response.statusCode == 200) {
        return response.data['text'] as String?;
      }
    } catch (e) {
      // print('[Voice-Web] Upload error: $e');
    }
    return null;
  }

  // ----------------------------------------------------------------
  // MOBILE PIPELINE (Streaming -> WebSocket)
  // ----------------------------------------------------------------
  Future<void> _startMobilePipeline() async {
    await _connectWebSocket();
    
    // Stream PCM 16bit 16kHz
    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    ));
    
    _audioStreamSubscription = stream.listen((data) {
       if (_channel != null && _channel!.closeCode == null) {
          _channel!.sink.add(data);
       }
    });
  }

  Future<String?> _stopMobilePipeline() async {
    await _recorder.stop();
    await _audioStreamSubscription?.cancel();
    
    // Commit
    _channel?.sink.add(jsonEncode({"type": "commit"}));
    
    // HACK: Wait briefly for VAD/Final result from socket
    // Ideally, we wait for a specific "final" message with a timeout.
    // For now, simple delay + check last text.
    await Future.delayed(const Duration(milliseconds: 600));
    
    _channel?.sink.close();
    _channel = null;
    
    return state.transcribedText;
  }

  Future<void> _connectWebSocket() async {
      final httpUrl = ApiConstants.baseUrl;
      final wsBase = httpUrl.startsWith('https') 
          ? httpUrl.replaceFirst('https://', 'wss://') 
          : httpUrl.replaceFirst('http://', 'ws://');
      final wsUrl = Uri.parse('$wsBase/api/v1/voice/stream');
      
      _channel = WebSocketChannel.connect(wsUrl);
      await _channel!.ready;
      
      _channel!.stream.listen((message) {
         try {
           final response = jsonDecode(message);
           final type = response['type'];
           if (type == 'partial' || type == 'final') {
             if (response['text'] != null) {
                state = state.copyWith(transcribedText: response['text']);
             }
           }
         } catch (_) {}
      });
  }

  // ----------------------------------------------------------------
  // SHARED UTILS
  // ----------------------------------------------------------------
  void _startAmplitudeLoop() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
       if (state.state != VoiceInputState.listening) {
         timer.cancel();
         return;
       }
       
       double normalized = 0.0;
       
       if (kIsWeb) {
         // WEB: Send 0.0 so VoiceWaveformWidget uses its internal "Organic Speech" simulation
         // (The previous random noise prevented the high-quality simulation from running)
         normalized = 0.0; 
       } else {
         // MOBILE: Real RMS
         final amp = await _recorder.getAmplitude();
         final currentAmp = amp.current; 
         if (currentAmp > -60) {
            normalized = ((currentAmp + 60) / 60).clamp(0.0, 1.0);
         }
       }
       state = state.copyWith(amplitude: normalized);
    });
  }

  Future<bool> _checkPermission() async {
    if (kIsWeb) return true; // Browser handles prompt on getUserMedia
    
    if (await Permission.microphone.isGranted) return true;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  void _cleanup() {
    _amplitudeTimer?.cancel();
    _audioStreamSubscription?.cancel();
    _channel?.sink.close();
    try {
      _recorder.stop(); // Safe guard
    } catch (_) {}
  }

  @override
  void dispose() {
    _cleanup();
    _recorder.dispose();
    super.dispose();
  }
  
  // Explicit Reset (clears everything)
  void reset() {
    state = VoiceInputData.initial();
  }
  
  /// Set prefix text (existing typed text before starting voice)
  void setPrefix(String prefix) {
    state = state.copyWith(accumulatedText: prefix);
  }
  
  /// Clear accumulated text (called after sending message)
  void clearAccumulatedText() {
    state = state.copyWith(
      transcribedText: null,
      accumulatedText: '',
    );
  }
  
  /// Restart recording (for "No Speech" retry - keeps accumulated text)
  Future<void> restartRecording() async {
    // Don't clear accumulated text - just start a new recording
    await cancelRecording();
    await startRecording();
  }
}

final voiceInputProvider = StateNotifierProvider<VoiceInputNotifier, VoiceInputData>((ref) {
  return VoiceInputNotifier();
});

final voiceAmplitudeProvider = Provider<double>((ref) {
  return ref.watch(voiceInputProvider).amplitude;
});

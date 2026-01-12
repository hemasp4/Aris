import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/constants/api_constants.dart';

/// Service for real-time audio transcription via WebSocket
class AudioStreamService {
  WebSocketChannel? _channel;
  StreamController<String>? _transcriptionController;
  final List<Uint8List> _audioBuffer = [];
  bool _isConnected = false;

  /// Check if currently connected
  bool get isConnected => _isConnected;

  /// Stream of transcription results
  Stream<String>? get transcriptionStream => _transcriptionController?.stream;

  /// Connect to WebSocket for real-time audio
  Future<void> connect() async {
    if (_isConnected) return;

    final wsUrl = ApiConstants.baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    
    final uri = Uri.parse('$wsUrl${ApiConstants.apiVersion}/media/audio/stream');
    
    _channel = WebSocketChannel.connect(uri);
    _transcriptionController = StreamController<String>.broadcast();
    _isConnected = true;

    _channel!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          
          if (data['text'] != null) {
            _transcriptionController?.add(data['text']);
          }
          
          if (data['error'] != null) {
            _transcriptionController?.addError(data['error']);
          }
          
          if (data['is_final'] == true) {
            // Final result received
          }
        } catch (e) {
          // Handle parse error
        }
      },
      onError: (error) {
        _transcriptionController?.addError(error);
        _isConnected = false;
      },
      onDone: () {
        _isConnected = false;
      },
    );
  }

  /// Send audio chunk for transcription
  void sendAudioChunk(Uint8List audioData) {
    if (!_isConnected || _channel == null) return;
    
    _audioBuffer.add(audioData);
    _channel!.sink.add(audioData);
  }

  /// Signal end of audio and get final transcription
  Future<String?> finishAndGetResult() async {
    if (!_isConnected || _channel == null) return null;

    // Send end signal
    _channel!.sink.add(jsonEncode({'end': true}));

    // Wait for final result
    try {
      final completer = Completer<String>();
      
      late StreamSubscription subscription;
      subscription = _transcriptionController!.stream.listen(
        (text) {
          if (!completer.isCompleted) {
            completer.complete(text);
            subscription.cancel();
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
      );

      // Timeout after 30 seconds
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => '',
      );
    } catch (e) {
      return null;
    }
  }

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    _isConnected = false;
    _audioBuffer.clear();
    
    await _channel?.sink.close();
    await _transcriptionController?.close();
    
    _channel = null;
    _transcriptionController = null;
  }
}

/// Global audio stream service instance
final audioStreamService = AudioStreamService();

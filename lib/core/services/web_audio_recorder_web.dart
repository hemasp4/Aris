import 'dart:async';
import 'dart:html' as html;
import 'dart:web_audio';
import 'dart:typed_data';

class WebAudioRecorder {
  html.MediaRecorder? _mediaRecorder;
  AudioContext? _audioContext;
  AnalyserNode? _analyser;
  MediaStreamAudioSourceNode? _sourceNode;
  
  Future<bool> hasPermission() async {
    try {
      await html.window.navigator.mediaDevices!.getUserMedia({'audio': true});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Stream<Uint8List>> startStream() async {
    final stream = await html.window.navigator.mediaDevices!.getUserMedia({'audio': true});
    
    // 1. Setup AudioContext for Amplitude Analysis
    _audioContext = AudioContext();
    _sourceNode = _audioContext!.createMediaStreamSource(stream);
    _analyser = _audioContext!.createAnalyser();
    _analyser!.fftSize = 256;
    _analyser!.smoothingTimeConstant = 0.3;
    _sourceNode!.connectNode(_analyser!);
    
    // 2. Setup Recorder
    // Use standard webm/opus which is widely supported
    _mediaRecorder = html.MediaRecorder(stream, {'mimeType': 'audio/webm;codecs=opus'});
    
    final controller = StreamController<Uint8List>();
    
    _mediaRecorder!.addEventListener('dataavailable', (event) {
      final blob = (event as html.BlobEvent).data;
      if (blob != null && blob.size > 0) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(blob);
        reader.onLoadEnd.listen((_) {
          controller.add(reader.result as Uint8List);
        });
      }
    });

    _mediaRecorder!.start(100); // 100ms chunks
    
    return controller.stream;
  }

  /// Returns current amplitude (0.0 to 1.0)
  Future<double> getAmplitude() async {
    if (_analyser == null) return 0.0;
    
    final bufferLength = _analyser!.frequencyBinCount ?? 0;
    if (bufferLength == 0) return 0.0;
    
    final dataArray = Uint8List(bufferLength);
    _analyser!.getByteFrequencyData(dataArray);
    
    // Calculate average volume
    int sum = 0;
    for (var i = 0; i < bufferLength; i++) {
      sum += dataArray[i];
    }
    
    final average = sum / bufferLength;
    // Normalize to 0.0-1.0 (255 is max byte value)
    return (average / 255.0).clamp(0.0, 1.0);
  }

  Future<void> stop() async {
    _mediaRecorder?.stop();
    _mediaRecorder?.stream?.getTracks().forEach((track) => track.stop());
    
    // Clean up AudioContext
    _sourceNode?.disconnect();
    _analyser?.disconnect();
    if (_audioContext?.state != 'closed') {
      await _audioContext?.close();
    }
    
    _mediaRecorder = null;
    _sourceNode = null;
    _analyser = null;
    _audioContext = null;
  }
}

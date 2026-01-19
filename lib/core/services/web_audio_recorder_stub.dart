import 'dart:typed_data';

class WebAudioRecorder {
  Future<bool> hasPermission() async => false;

  Future<Stream<Uint8List>> startStream() async {
    throw UnsupportedError('WebAudioRecorder is only supported on web');
  }

  Future<double> getAmplitude() async => 0.0;

  Future<void> stop() async {}
}

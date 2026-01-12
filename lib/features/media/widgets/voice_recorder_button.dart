import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import 'dart:io';

import '../services/media_service.dart';

/// Voice recording button with ChatGPT-like interface
class VoiceRecorderButton extends StatefulWidget {
  final Function(String transcribedText) onTranscriptionComplete;
  final Function(String? error)? onError;
  final bool enabled;

  const VoiceRecorderButton({
    super.key,
    required this.onTranscriptionComplete,
    this.onError,
    this.enabled = true,
  });

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        widget.onError?.call('Microphone permission denied');
        return;
      }

      // Create temp file path
      final tempDir = Directory.systemTemp;
      _recordingPath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _pulseController.repeat(reverse: true);

      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
    } catch (e) {
      widget.onError?.call('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _durationTimer?.cancel();
      _pulseController.stop();

      final path = await _recorder.stop();

      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      if (path != null) {
        await _transcribeAudio(path);
      }
    } catch (e) {
      widget.onError?.call('Failed to stop recording: $e');
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
    }
  }

  Future<void> _cancelRecording() async {
    _durationTimer?.cancel();
    _pulseController.stop();
    await _recorder.stop();

    setState(() {
      _isRecording = false;
      _isProcessing = false;
    });
  }

  Future<void> _transcribeAudio(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();

      final result = await mediaService.transcribeAudio(
        audioData: bytes,
        filename: 'recording.wav',
        mimeType: 'audio/wav',
      );

      widget.onTranscriptionComplete(result.text);

      // Cleanup
      await file.delete();
    } catch (e) {
      widget.onError?.call('Transcription failed: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isProcessing) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (_isRecording) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cancel button
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelRecording,
            color: theme.colorScheme.error,
          ),

          // Duration display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (c) => c.repeat()).fadeIn().fadeOut(),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_recordingDuration),
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Stop/Send button
          IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
            onPressed: _stopRecording,
          ),
        ],
      ).animate().fadeIn(duration: 200.ms);
    }

    return IconButton(
      icon: Icon(
        Icons.mic,
        color: widget.enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withOpacity(0.3),
      ),
      onPressed: widget.enabled ? _startRecording : null,
      tooltip: 'Voice input',
    );
  }
}

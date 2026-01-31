import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/media_service.dart';

/// Media picker widget for images, files, and camera
class MediaPickerButton extends StatefulWidget {
  final Function(Uint8List data, String filename, String mimeType, String? analysis) onMediaSelected;
  final Function(String? error)? onError;
  final bool analyzeWithGemini;
  final bool enabled;

  const MediaPickerButton({
    super.key,
    required this.onMediaSelected,
    this.onError,
    this.analyzeWithGemini = true,
    this.enabled = true,
  });

  @override
  State<MediaPickerButton> createState() => _MediaPickerButtonState();
}

class _MediaPickerButtonState extends State<MediaPickerButton> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _showPickerOptions(BuildContext context) async {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Add Media',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to capture image'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: Colors.green),
              ),
              title: const Text('Photo Library'),
              subtitle: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.attach_file, color: Colors.orange),
              ),
              title: const Text('Document'),
              subtitle: const Text('PDF, text files, etc.'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      widget.onError?.call('Camera error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      widget.onError?.call('Gallery error: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'doc', 'docx'],
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        await _processDocument(file.bytes!, file.name);
      }
    } catch (e) {
      widget.onError?.call('File picker error: $e');
    }
  }

  Future<void> _processImage(XFile image) async {
    setState(() => _isProcessing = true);

    try {
      final bytes = await image.readAsBytes();
      final mimeType = _getMimeType(image.name);
      String? analysis;

      if (widget.analyzeWithGemini) {
        try {
          final result = await mediaService.analyzeImage(
            imageData: bytes,
            filename: image.name,
            prompt: 'Briefly describe this image.',
          );
          analysis = result.result;
        } catch (e) {
          // Continue without analysis if Gemini fails
        }
      }

      widget.onMediaSelected(bytes, image.name, mimeType, analysis);
    } catch (e) {
      widget.onError?.call('Processing error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processDocument(Uint8List bytes, String filename) async {
    setState(() => _isProcessing = true);

    try {
      final mimeType = _getMimeType(filename);
      String? analysis;

      if (widget.analyzeWithGemini) {
        try {
          final result = await mediaService.analyzeDocument(
            fileData: bytes,
            filename: filename,
            mimeType: mimeType,
            prompt: 'Summarize the key points of this document.',
          );
          analysis = result.result;
        } catch (e) {
          // Continue without analysis
        }
      }

      widget.onMediaSelected(bytes, filename, mimeType, analysis);
    } catch (e) {
      widget.onError?.call('Processing error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  String _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    final mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'md': 'text/markdown',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isProcessing) {
      return Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(12),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: theme.colorScheme.primary,
        ),
      );
    }

    return IconButton(
      icon: Icon(
        Icons.attach_file,
        color: widget.enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withOpacity(0.3),
      ),
      onPressed: widget.enabled ? () => _showPickerOptions(context) : null,
      tooltip: 'Attach file',
    );
  }
}

/// Image preview widget for chat
class MediaPreview extends StatelessWidget {
  final Uint8List imageData;
  final String? filename;
  final String? analysis;
  final VoidCallback? onRemove;
  final bool showAnalysis;

  const MediaPreview({
    super.key,
    required this.imageData,
    this.filename,
    this.analysis,
    this.onRemove,
    this.showAnalysis = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              imageData,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),

          // Remove button
          if (onRemove != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Analysis badge
          if (analysis != null && showAnalysis)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'AI analyzed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

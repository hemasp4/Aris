import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../../../core/services/dio_client.dart';
import '../../../core/constants/api_constants.dart';

/// Media service for uploading and analyzing files
class MediaService {
  final DioClient _dioClient = DioClient();

  /// Check if Gemini API is available
  Future<bool> isGeminiAvailable() async {
    try {
      final response = await _dioClient.dio.get('/media/status');
      return response.data['available'] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Upload a file
  Future<MediaUploadResult> uploadFile({
    required Uint8List fileData,
    required String filename,
    required String mimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileData,
          filename: filename,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      final response = await _dioClient.dio.post(
        '/media/upload',
        data: formData,
      );

      return MediaUploadResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  /// Analyze an image with Gemini
  Future<MediaAnalysisResult> analyzeImage({
    required Uint8List imageData,
    required String filename,
    String prompt = 'Describe this image in detail.',
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageData,
          filename: filename,
          contentType: DioMediaType.parse('image/jpeg'),
        ),
        'prompt': prompt,
      });

      final response = await _dioClient.dio.post(
        '/media/analyze/image',
        data: formData,
      );

      return MediaAnalysisResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Analysis failed: $e');
    }
  }

  /// Extract text from image (OCR)
  Future<String> extractTextFromImage(Uint8List imageData, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageData,
          filename: filename,
          contentType: DioMediaType.parse('image/jpeg'),
        ),
      });

      final response = await _dioClient.dio.post(
        '/media/ocr',
        data: formData,
      );

      return response.data['result'] ?? '';
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  /// Transcribe audio file
  Future<TranscriptionResult> transcribeAudio({
    required Uint8List audioData,
    required String filename,
    required String mimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          audioData,
          filename: filename,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      final response = await _dioClient.dio.post(
        '/media/audio/transcribe',
        data: formData,
      );

      return TranscriptionResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Transcription failed: $e');
    }
  }

  /// Analyze a document
  Future<MediaAnalysisResult> analyzeDocument({
    required Uint8List fileData,
    required String filename,
    required String mimeType,
    String prompt = 'Summarize this document.',
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileData,
          filename: filename,
          contentType: DioMediaType.parse(mimeType),
        ),
        'prompt': prompt,
      });

      final response = await _dioClient.dio.post(
        '/media/analyze/document',
        data: formData,
      );

      return MediaAnalysisResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Document analysis failed: $e');
    }
  }

  /// Get media file URL
  String getMediaUrl(String mediaId) {
    return '${ApiConstants.baseUrl}${ApiConstants.apiVersion}/media/$mediaId';
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String mediaId) {
    return '${ApiConstants.baseUrl}${ApiConstants.apiVersion}/media/$mediaId/thumbnail';
  }
}

/// Result from file upload
class MediaUploadResult {
  final String id;
  final String filename;
  final String mimeType;
  final int size;
  final String? thumbnailUrl;

  MediaUploadResult({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.size,
    this.thumbnailUrl,
  });

  factory MediaUploadResult.fromJson(Map<String, dynamic> json) {
    return MediaUploadResult(
      id: json['id'],
      filename: json['filename'],
      mimeType: json['mime_type'],
      size: json['size'],
      thumbnailUrl: json['thumbnail_url'],
    );
  }
}

/// Result from Gemini analysis
class MediaAnalysisResult {
  final String result;
  final String mediaId;

  MediaAnalysisResult({
    required this.result,
    required this.mediaId,
  });

  factory MediaAnalysisResult.fromJson(Map<String, dynamic> json) {
    return MediaAnalysisResult(
      result: json['result'],
      mediaId: json['media_id'],
    );
  }
}

/// Result from audio transcription
class TranscriptionResult {
  final String text;
  final double? durationSeconds;

  TranscriptionResult({
    required this.text,
    this.durationSeconds,
  });

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      text: json['text'],
      durationSeconds: json['duration_seconds']?.toDouble(),
    );
  }
}

/// Global media service instance
final mediaService = MediaService();

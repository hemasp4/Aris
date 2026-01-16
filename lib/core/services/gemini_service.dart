import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService(String apiKey) 
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash', 
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 2048,
          ),
        );

  Stream<String> generateStream(String prompt) async* {
    try {
      final content = [Content.text(prompt)];
      final response = _model.generateContentStream(content);

      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Gemini API Error: $e');
      }
      yield 'Error generating response: $e';
    }
  }
  
  Future<String> generateContent(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? '';
    } catch (e) {
      if (kDebugMode) {
        print('Gemini API Error: $e');
      }
      return 'Error generating response: $e';
    }
  }
}

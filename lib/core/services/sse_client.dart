import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// SSE (Server-Sent Events) client for real-time streaming
/// Uses http package for proper streaming on all platforms
class SSEClient {
  static SSEClient? _instance;
  http.Client? _httpClient;
  
  SSEClient._internal();
  
  factory SSEClient() {
    _instance ??= SSEClient._internal();
    return _instance!;
  }
  
  /// Stream SSE events from an endpoint
  /// 
  /// This uses the http package's streaming API which properly streams
  /// on web (unlike Dio which buffers the entire response)
  Stream<SSEEvent> stream({
    required String url,
    required Map<String, dynamic> body,
    required String? authToken,
  }) async* {
    _httpClient?.close();
    _httpClient = http.Client();
    
    try {
      final request = http.Request('POST', Uri.parse(url));
      
      // Set headers
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['ngrok-skip-browser-warning'] = 'true';
      
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      
      // Set body
      request.body = jsonEncode(body);
      
      // Send request and get streamed response
      final response = await _httpClient!.send(request);
      
      if (response.statusCode != 200) {
        yield SSEEvent(
          event: 'error',
          data: {'error': 'HTTP ${response.statusCode}'},
        );
        return;
      }
      
      // Buffer for incomplete SSE data
      String buffer = '';
      
      // Stream and parse SSE events
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        
        // Process complete lines
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);
          
          if (line.isEmpty) continue;
          
          if (line.startsWith('data:')) {
            var data = line.substring(5).trim();
            
            if (data == '[DONE]') {
              yield SSEEvent(event: 'done', data: {});
              return;
            }
            
            try {
              final json = jsonDecode(data);
              final eventType = json['event'] as String? ?? 'message';
              yield SSEEvent(event: eventType, data: json);
            } catch (e) {
              // Raw text data
              yield SSEEvent(event: 'message', data: {'content': data});
            }
          } else if (line.trim().startsWith('{') && line.trim().endsWith('}')) {
            // Handle raw JSON lines (implicit data)
            try {
              final json = jsonDecode(line);
              final eventType = json['event'] as String? ?? 'message';
              yield SSEEvent(event: eventType, data: json);
            } catch (e) {
              // Ignore invalid JSON lines
            }
          }
        }
      }
      
    } catch (e) {
      yield SSEEvent(event: 'error', data: {'error': e.toString()});
    } finally {
      _httpClient?.close();
      _httpClient = null;
    }
  }
  
  /// Cancel the current stream
  void cancel() {
    _httpClient?.close();
    _httpClient = null;
  }
}

/// SSE Event model
class SSEEvent {
  final String event;
  final Map<String, dynamic> data;
  
  SSEEvent({required this.event, required this.data});
  
  @override
  String toString() => 'SSEEvent($event: $data)';
}

/// Global SSE client instance
final sseClient = SSEClient();

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/dio_client.dart';

/// Chat message model
class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? json['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'] ?? 'assistant',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

/// Chat session model
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isArchived;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? 'New Chat',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      isPinned: json['is_pinned'] ?? false,
      isArchived: json['is_archived'] ?? false,
    );
  }
}

/// Chat state model
class ChatState {
  final List<ChatSession> sessions;
  final String? currentSessionId;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? error;

  const ChatState({
    this.sessions = const [],
    this.currentSessionId,
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatSession>? sessions,
    String? currentSessionId,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? error,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
    );
  }
}

/// Chat notifier for state management
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState()) {
    loadSessions();
  }

  final _client = dioClient;
  StreamSubscription? _streamSubscription;

  /// Load chat sessions
  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _client.dio.get(ApiConstants.chats);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['chats'] ?? response.data ?? [];
        final sessions = data.map((json) => ChatSession.fromJson(json)).toList();
        
        state = state.copyWith(
          sessions: sessions,
          isLoading: false,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['detail'] ?? 'Failed to load chats',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create new chat session
  Future<String?> createSession({String? title}) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.chats,
        data: {'title': title ?? 'New Chat'},
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final session = ChatSession.fromJson(response.data);
        state = state.copyWith(
          sessions: [session, ...state.sessions],
          currentSessionId: session.id,
          messages: [],
        );
        return session.id;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to create chat');
    }
    return null;
  }

  /// Load messages for a chat session
  Future<void> loadMessages(String sessionId) async {
    state = state.copyWith(
      isLoading: true,
      currentSessionId: sessionId,
      error: null,
    );
    
    try {
      final response = await _client.dio.get(ApiConstants.chatMessages(sessionId));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['messages'] ?? response.data ?? [];
        final messages = data.map((json) => ChatMessage.fromJson(json)).toList();
        
        state = state.copyWith(
          messages: messages,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load messages');
    }
  }

  /// Send message and stream response via SSE
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    
    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
    
    // Add placeholder for AI response
    final aiMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_ai',
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    
    state = state.copyWith(
      messages: [...state.messages, userMessage, aiMessage],
      isStreaming: true,
      error: null,
    );
    
    try {
      // Get session ID or create new one
      String? sessionId = state.currentSessionId;
      if (sessionId == null) {
        sessionId = await createSession();
        if (sessionId == null) {
          throw Exception('Failed to create chat session');
        }
      }
      
      // Stream the response
      final response = await _client.dio.post(
        ApiConstants.chatStream(sessionId),
        data: {'content': content},
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );
      
      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';
      
      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        buffer += text;
        
        // Parse SSE events
        final lines = buffer.split('\n');
        buffer = lines.last; // Keep incomplete line in buffer
        
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i];
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              // Streaming complete
              _finalizeStreamingMessage();
              return;
            }
            
            try {
              final json = jsonDecode(data);
              final chunkContent = json['content'] ?? json['chunk'] ?? '';
              _appendToStreamingMessage(chunkContent);
            } catch (e) {
              // Not valid JSON, might be raw text
              _appendToStreamingMessage(data);
            }
          }
        }
      }
      
      _finalizeStreamingMessage();
    } catch (e) {
      state = state.copyWith(
        isStreaming: false,
        error: 'Failed to send message: $e',
      );
      _removeLastMessage();
    }
  }

  void _appendToStreamingMessage(String content) {
    if (state.messages.isEmpty) return;
    
    final messages = List<ChatMessage>.from(state.messages);
    final lastIndex = messages.length - 1;
    final lastMessage = messages[lastIndex];
    
    if (lastMessage.isStreaming) {
      messages[lastIndex] = lastMessage.copyWith(
        content: lastMessage.content + content,
      );
      state = state.copyWith(messages: messages);
    }
  }

  void _finalizeStreamingMessage() {
    if (state.messages.isEmpty) return;
    
    final messages = List<ChatMessage>.from(state.messages);
    final lastIndex = messages.length - 1;
    final lastMessage = messages[lastIndex];
    
    if (lastMessage.isStreaming) {
      messages[lastIndex] = lastMessage.copyWith(isStreaming: false);
      state = state.copyWith(
        messages: messages,
        isStreaming: false,
      );
    }
  }

  void _removeLastMessage() {
    if (state.messages.isEmpty) return;
    final messages = List<ChatMessage>.from(state.messages);
    messages.removeLast(); // Remove failed AI message
    state = state.copyWith(messages: messages, isStreaming: false);
  }

  /// Delete chat session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _client.dio.delete(ApiConstants.chatById(sessionId));
      
      state = state.copyWith(
        sessions: state.sessions.where((s) => s.id != sessionId).toList(),
        currentSessionId: state.currentSessionId == sessionId ? null : state.currentSessionId,
        messages: state.currentSessionId == sessionId ? [] : state.messages,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete chat');
    }
  }

  /// Rename chat session
  Future<void> renameSession(String sessionId, String newTitle) async {
    try {
      await _client.dio.patch(
        ApiConstants.chatById(sessionId),
        data: {'title': newTitle},
      );
      
      state = state.copyWith(
        sessions: state.sessions.map((s) {
          if (s.id == sessionId) {
            return ChatSession(
              id: s.id,
              title: newTitle,
              createdAt: s.createdAt,
              updatedAt: DateTime.now(),
              isPinned: s.isPinned,
              isArchived: s.isArchived,
            );
          }
          return s;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to rename chat');
    }
  }

  /// Clear current session
  void clearCurrentSession() {
    state = state.copyWith(
      currentSessionId: null,
      messages: [],
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

/// Chat provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

/// Current messages provider
final currentMessagesProvider = Provider<List<ChatMessage>>((ref) {
  return ref.watch(chatProvider).messages;
});

/// Chat sessions provider
final chatSessionsProvider = Provider<List<ChatSession>>((ref) {
  return ref.watch(chatProvider).sessions;
});

/// Is streaming provider
final isStreamingProvider = Provider<bool>((ref) {
  return ref.watch(chatProvider).isStreaming;
});

/// Chat loading provider
final isChatLoadingProvider = Provider<bool>((ref) {
  return ref.watch(chatProvider).isLoading;
});

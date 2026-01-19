import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/dio_client.dart';
import '../../../core/services/sse_client.dart';
import 'model_provider.dart';

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
  
  // Scraping/fetch state for ChatGPT-style UI
  final bool isThinking;
  final bool isSearching;
  final bool isScraping;
  final List<String> scrapingSources;
  final List<Map<String, dynamic>> headlines;
  final String? researchMode; // null = normal, 'web_search', 'deep_research', 'shopping'
  
  // Quota state for usage limits
  final bool quotaExceeded;
  final String? quotaMessage;
  final int? quotaResetHours;

  const ChatState({
    this.sessions = const [],
    this.currentSessionId,
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.error,
    this.isThinking = false,
    this.isSearching = false,
    this.isScraping = false,
    this.scrapingSources = const [],
    this.headlines = const [],
    this.researchMode,
    this.quotaExceeded = false,
    this.quotaMessage,
    this.quotaResetHours,
  });

  ChatState copyWith({
    List<ChatSession>? sessions,
    String? currentSessionId,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? error,
    bool? isThinking,
    bool? isSearching,
    bool? isScraping,
    List<String>? scrapingSources,
    List<Map<String, dynamic>>? headlines,
    String? researchMode,
    bool? quotaExceeded,
    String? quotaMessage,
    int? quotaResetHours,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
      isThinking: isThinking ?? this.isThinking,
      isSearching: isSearching ?? this.isSearching,
      isScraping: isScraping ?? this.isScraping,
      scrapingSources: scrapingSources ?? this.scrapingSources,
      headlines: headlines ?? this.headlines,
      researchMode: researchMode ?? this.researchMode,
      quotaExceeded: quotaExceeded ?? this.quotaExceeded,
      quotaMessage: quotaMessage ?? this.quotaMessage,
      quotaResetHours: quotaResetHours ?? this.quotaResetHours,
    );
  }
}

/// Chat notifier for state management
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;

  ChatNotifier(this.ref) : super(const ChatState()) {
    loadSessions();
  }

  final _client = dioClient;
  StreamSubscription? _streamSubscription;
  CancelToken? _cancelToken;
  
  // Token batching for smoother streaming (ChatGPT-style)
  final StringBuffer _tokenBuffer = StringBuffer();
  Timer? _updateTimer;
  DateTime? _streamStartTime;

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

  /// Set research mode (web_search, deep_research, shopping, or null for normal)
  void setResearchMode(String? mode) {
    state = state.copyWith(researchMode: mode);
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
        // Backend returns List<MessageResponse> directly, not wrapped in 'messages'
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['messages'] ?? []);
        final messages = data.map((json) => ChatMessage.fromJson(json)).toList();
        
        state = state.copyWith(
          messages: messages,
          isLoading: false,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        state = state.copyWith(
          isLoading: false, 
          error: 'Chat not found',
          currentSessionId: null,
          messages: [],
        );
      } else {
        // print('Failed to load messages: $e');
        state = state.copyWith(isLoading: false, error: 'Failed to load messages');
      }
    } catch (e) {
      // print('Failed to load messages: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to load messages');
    }
  }

  /// Transcribe audio file using backend API
  Future<String?> transcribeAudio(String path) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path),
      });

      final response = await _client.dio.post(
        '/media/audio/transcribe',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['text'] as String?;
      }
    } catch (e) {
      // print('Transcription error: $e');
      // Don't set error state here to avoid disrupting chat
    }
    return null;
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
    
    // Track stream start time for first-token performance measurement
    _streamStartTime = DateTime.now();
    _tokenBuffer.clear();
    _isFirstToken = true;
    
    try {
      // Get session ID or create new one
      String? sessionId = state.currentSessionId;
      if (sessionId == null || sessionId == 'sample-session') {
        sessionId = await createSession();
        if (sessionId == null) {
          throw Exception('Failed to create chat session');
        }
      }

      // Get selected model
      final modelId = ref.read(modelProvider).selectedModel;
      
      // Get auth token for SSE client
      const storage = FlutterSecureStorage();
      final authToken = await storage.read(key: StorageKeys.authToken);
      
      // Build full URL
      final url = '${ApiConstants.apiUrl}${ApiConstants.chatStream(sessionId)}';
      
      // print('Starting SSE stream to: $url'); // Debug
      
      // Use SSE client for proper streaming (works on web)
      await for (final event in sseClient.stream(
        url: url,
        body: {
          'content': content,
          'model': modelId,
          if (state.researchMode != null) 'research_mode': state.researchMode,
        },
        authToken: authToken,
      )) {
        // print('SSE event: ${event.event}'); // Debug
        
        switch (event.event) {
          case 'done':
            _finalizeStreamingMessage();
            return;
            
          case 'error':
            state = state.copyWith(
              error: event.data['error']?.toString() ?? 'Unknown error',
              isStreaming: false,
              isThinking: false,
              isSearching: false,
              isScraping: false,
            );
            _finalizeStreamingMessage();
            return;
            
          case 'quota_exceeded':
            // Show quota message above text box like ChatGPT
            state = state.copyWith(
              quotaExceeded: true,
              quotaMessage: event.data['message']?.toString() ?? 'Daily limit reached. Come back tomorrow.',
              quotaResetHours: event.data['reset_in_hours'] as int?,
              isStreaming: false,
              isThinking: false,
            );
            _removeLastMessage(); // Remove the placeholder AI message
            return;
            
          case 'token':
            final tokenContent = event.data['content']?.toString() ?? '';
            if (tokenContent.isNotEmpty) {
              _appendToStreamingMessage(tokenContent);
            }
            break;
            
          case 'thinking_started':
            state = state.copyWith(
              isThinking: true,
              isSearching: false,
              isScraping: false,
            );
            break;
            
          case 'search_started':
            state = state.copyWith(
              isThinking: false,
              isSearching: true,
              isScraping: false,
            );
            break;
            
          case 'scrape_started':
            final sources = (event.data['sources'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ?? [];
            state = state.copyWith(
              isSearching: false,
              isScraping: true,
              scrapingSources: sources,
            );
            break;
            
          case 'scrape_completed':
            final headlines = (event.data['headlines'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ?? [];
            state = state.copyWith(
              isScraping: false,
              headlines: headlines,
            );
            break;
            
          case 'answer_stream_started':
            state = state.copyWith(
              isThinking: false,
              isSearching: false,
              isScraping: false,
            );
            break;
            
          case 'answer_completed':
            _finalizeStreamingMessage();
            state = state.copyWith(
              isThinking: false,
              isSearching: false,
              isScraping: false,
              scrapingSources: [],
              headlines: [],
            );
            break;
            
          default:
            // Handle legacy format or unknown events
            final chunkContent = event.data['content']?.toString() ?? '';
            if (chunkContent.isNotEmpty) {
              _appendToStreamingMessage(chunkContent);
            }
        }
      }
      
      _finalizeStreamingMessage();
    } catch (e) {
      // print('Streaming error: $e');
      state = state.copyWith(
        isStreaming: false,
        error: 'Failed to send message: $e',
      );
      _removeLastMessage();
    }
  }

  void _appendToStreamingMessage(String content) {
    if (state.messages.isEmpty || content.isEmpty) return;
    
    // Log first token timing for performance tracking
    if (_streamStartTime != null && _isFirstToken) {
      final elapsed = DateTime.now().difference(_streamStartTime!).inMilliseconds;
      // print('First token received in ${elapsed}ms');
      _isFirstToken = false;
    }
    
    // Immediate update for ChatGPT-style smooth streaming
    // No buffering, no debounce - update UI for every token
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
  
  void _flushTokenBuffer() {
    // No longer needed - kept for compatibility
  }
  
  // Track first token for timing
  bool _isFirstToken = true;

  /// Clear quota exceeded message
  void clearQuotaMessage() {
    state = state.copyWith(
      quotaExceeded: false,
      quotaMessage: null,
      quotaResetHours: null,
    );
  }
  
  /// Cancel ongoing search/streaming
  void cancelSearch() {
    sseClient.cancel();
    state = state.copyWith(
      isStreaming: false,
      isThinking: false,
      isSearching: false,
      isScraping: false,
      scrapingSources: [],
    );
    // Remove the streaming message if present
    if (state.messages.isNotEmpty && state.messages.last.isStreaming) {
      _removeLastMessage();
    }
  }

  /// Handle new event-based streaming format for ChatGPT-style UI
  // void _handleStreamEvent(Map<String, dynamic> json) {
  //   final event = json['event'] as String;
    
  //   switch (event) {
  //     case 'thinking_started':
  //       state = state.copyWith(
  //         isThinking: true,
  //         isSearching: false,
  //         isScraping: false,
  //       );
  //       break;
        
  //     case 'search_started':
  //       state = state.copyWith(
  //         isThinking: false,
  //         isSearching: true,
  //         isScraping: false,
  //       );
  //       break;
        
  //     case 'scrape_started':
  //       final sources = (json['sources'] as List<dynamic>?)
  //           ?.map((e) => e.toString())
  //           .toList() ?? [];
  //       state = state.copyWith(
  //         isSearching: false,
  //         isScraping: true,
  //         scrapingSources: sources,
  //       );
  //       break;
        
  //     case 'source_scraped':
  //       // Individual source completed - could add to a "completed" list
  //       // For now, just log it
  //       // print('Source scraped: ${json['title']}');
  //       break;
        
  //     case 'scrape_completed':
  //       final headlines = (json['headlines'] as List<dynamic>?)
  //           ?.map((e) => Map<String, dynamic>.from(e as Map))
  //           .toList() ?? [];
  //       state = state.copyWith(
  //         isScraping: false,
  //         headlines: headlines,
  //       );
  //       break;
        
  //     case 'scrape_error':
  //       // print('Scrape error: ${json['error']}');
  //       state = state.copyWith(
  //         isSearching: false,
  //         isScraping: false,
  //       );
  //       break;
        
  //     case 'scrape_fallback':
  //       // Web scraping failed, falling back to direct LLM
  //       // print('Scrape fallback: ${json['reason']}');
  //       state = state.copyWith(
  //         isSearching: false,
  //         isScraping: false,
  //         scrapingSources: [],
  //       );
  //       break;
        
  //     case 'answer_stream_started':
  //       state = state.copyWith(
  //         isThinking: false,
  //         isSearching: false,
  //         isScraping: false,
  //       );
  //       break;
        
  //     case 'token':
  //       final content = json['content']?.toString() ?? '';
  //       if (content.isNotEmpty) {
  //         _appendToStreamingMessage(content);
  //       }
  //       break;
        
  //     case 'fallback_notice':
  //       // print('Using fallback model: ${json['fallback_model']}');
  //       break;
        
  //     case 'answer_completed':
  //       _finalizeStreamingMessage();
  //       state = state.copyWith(
  //         isThinking: false,
  //         isSearching: false,
  //         isScraping: false,
  //         scrapingSources: [],
  //         headlines: [],
  //       );
  //       break;
        
  //     case 'error':
  //       state = state.copyWith(
  //         error: json['error']?.toString() ?? 'Unknown error',
  //         isStreaming: false,
  //         isThinking: false,
  //         isSearching: false,
  //         isScraping: false,
  //       );
  //       _finalizeStreamingMessage();
  //       break;
  //   }
  // }

  void _finalizeStreamingMessage() {
    // Flush any remaining tokens in buffer
    _updateTimer?.cancel();
    _flushTokenBuffer();
    _streamStartTime = null;
    
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

  /// Toggle pin status of a session
  Future<void> togglePinSession(String sessionId) async {
    try {
      final session = state.sessions.firstWhere((s) => s.id == sessionId);
      final newPinnedStatus = !session.isPinned;
      
      await _client.dio.patch(
        ApiConstants.chatById(sessionId),
        data: {'is_pinned': newPinnedStatus},
      );
      
      state = state.copyWith(
        sessions: state.sessions.map((s) {
          if (s.id == sessionId) {
            return ChatSession(
              id: s.id,
              title: s.title,
              createdAt: s.createdAt,
              updatedAt: DateTime.now(),
              isPinned: newPinnedStatus,
              isArchived: s.isArchived,
            );
          }
          return s;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle pin status');
    }
  }

  /// Toggle archive status of a session
  Future<void> toggleArchiveSession(String sessionId) async {
    try {
      final session = state.sessions.firstWhere((s) => s.id == sessionId);
      final newArchivedStatus = !session.isArchived;
      
      await _client.dio.patch(
        ApiConstants.chatById(sessionId),
        data: {'is_archived': newArchivedStatus},
      );
      
      state = state.copyWith(
        sessions: state.sessions.map((s) {
          if (s.id == sessionId) {
            return ChatSession(
              id: s.id,
              title: s.title,
              createdAt: s.createdAt,
              updatedAt: DateTime.now(),
              isPinned: s.isPinned,
              isArchived: newArchivedStatus,
            );
          }
          return s;
        }).toList(),
      );
      
      // If archived, navigate away from the chat
      if (newArchivedStatus && state.currentSessionId == sessionId) {
        clearCurrentSession();
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle archive status');
    }
  }

  /// Clear current session
  void clearCurrentSession() {
    state = state.copyWith(
      currentSessionId: null,
      messages: [],
    );
  }

  /// Cancel current streaming response
  void cancelStream() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('User cancelled generation');
    }
    _cancelToken = null;
    
    if (state.isStreaming) {
      _finalizeStreamingMessage();
      state = state.copyWith(isStreaming: false);
    }
  }


  @override
  void dispose() {
    _streamSubscription?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }
}

/// Chat provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
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

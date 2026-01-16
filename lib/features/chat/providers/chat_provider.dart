import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/dio_client.dart';
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
    );
  }
}

/// Chat notifier for state management
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;

  ChatNotifier(this.ref) : super(const ChatState()) {
    loadSessions();
    // Load sample messages for UI testing - REMOVE THIS IN PRODUCTION
    _loadSampleMessagesForTesting();
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
    
    // Track stream start time for first-token performance measurement
    _streamStartTime = DateTime.now();
    _tokenBuffer.clear();
    
    try {
      // Get session ID or create new one
      // Also create new if current session is the fake sample-session
      String? sessionId = state.currentSessionId;
      if (sessionId == null || sessionId == 'sample-session') {
        sessionId = await createSession();
        if (sessionId == null) {
          throw Exception('Failed to create chat session');
        }
      }

      // Get selected model
      final modelId = ref.read(modelProvider).selectedModel;
      
      // Stream the response
      _cancelToken = CancelToken();
      final response = await _client.dio.post(
        ApiConstants.chatStream(sessionId),
        data: {
          'content': content,
          'model': modelId,  // Backend expects 'model', not 'model_id'
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
        cancelToken: _cancelToken,
      );
      
      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';
      
      print('Starting stream processing...'); // Debug
      
      // Explicitly cast to Stream<List<int>> to satisfy Utf8Decoder
      final Stream<List<int>> byteStream = response.data.stream.cast<List<int>>();
      
      await for (final line in byteStream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
            
        print('Received line: $line'); // Debug
        
        if (line.isEmpty) continue;
        
        if (line.startsWith('data:')) {
          // Handle 'data: ' and 'data:'
          var data = line.substring(5);
          if (data.startsWith(' ')) data = data.substring(1);
          
          if (data == '[DONE]') {
            // Streaming complete
            print('Stream complete [DONE]');
            _finalizeStreamingMessage();
            return;
          }
          
          try {
            final json = jsonDecode(data);
            
            // Handle new event-based format from backend
            final event = json['event'];
            if (event != null) {
              _handleStreamEvent(json);
              continue;
            }
            
            // Legacy format handling
            // Check for specific chunk format from backend
            if (json['type'] == 'error') {
              print('Stream error received: ${json['error']}');
              state = state.copyWith(
                error: json['error'],
                isStreaming: false,
                isThinking: false,
                isSearching: false,
                isScraping: false,
              );
              _finalizeStreamingMessage();
              return;
            }

            if (json['type'] == 'chunk') {
              final content = json['content']?.toString() ?? '';
              if (content.isNotEmpty) {
                _appendToStreamingMessage(content);
              }
            } else {
              // Fallback for other formats
              final chunkContent = json['content'] ?? json['chunk'] ?? '';
              if (chunkContent.toString().isNotEmpty) {
                _appendToStreamingMessage(chunkContent.toString());
              }
            }
          } catch (e) {
            print('JSON parse error: $e');
            // Not valid JSON, might be raw text
            _appendToStreamingMessage(data);
          }
        }
      }
      
      _finalizeStreamingMessage();
    } catch (e) {
      print('Streaming error: $e');
      state = state.copyWith(
        isStreaming: false,
        error: 'Failed to send message: $e',
      );
      _removeLastMessage();
    }
  }

  void _appendToStreamingMessage(String content) {
    if (state.messages.isEmpty) return;
    
    // Add to buffer instead of immediate state update
    _tokenBuffer.write(content);
    
    // Log first token timing for performance tracking
    if (_streamStartTime != null && _tokenBuffer.length == content.length) {
      final elapsed = DateTime.now().difference(_streamStartTime!).inMilliseconds;
      print('First token received in ${elapsed}ms');
    }
    
    // Debounce updates at 30ms intervals for smooth streaming
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(milliseconds: 30), _flushTokenBuffer);
  }
  
  void _flushTokenBuffer() {
    if (_tokenBuffer.isEmpty || state.messages.isEmpty) return;
    
    final messages = List<ChatMessage>.from(state.messages);
    final lastIndex = messages.length - 1;
    final lastMessage = messages[lastIndex];
    
    if (lastMessage.isStreaming) {
      messages[lastIndex] = lastMessage.copyWith(
        content: lastMessage.content + _tokenBuffer.toString(),
      );
      _tokenBuffer.clear();
      state = state.copyWith(messages: messages);
    }
  }

  /// Handle new event-based streaming format for ChatGPT-style UI
  void _handleStreamEvent(Map<String, dynamic> json) {
    final event = json['event'] as String;
    
    switch (event) {
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
        final sources = (json['sources'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        state = state.copyWith(
          isSearching: false,
          isScraping: true,
          scrapingSources: sources,
        );
        break;
        
      case 'source_scraped':
        // Individual source completed - could add to a "completed" list
        // For now, just log it
        print('Source scraped: ${json['title']}');
        break;
        
      case 'scrape_completed':
        final headlines = (json['headlines'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ?? [];
        state = state.copyWith(
          isScraping: false,
          headlines: headlines,
        );
        break;
        
      case 'scrape_error':
        print('Scrape error: ${json['error']}');
        state = state.copyWith(
          isSearching: false,
          isScraping: false,
        );
        break;
        
      case 'answer_stream_started':
        state = state.copyWith(
          isThinking: false,
          isSearching: false,
          isScraping: false,
        );
        break;
        
      case 'token':
        final content = json['content']?.toString() ?? '';
        if (content.isNotEmpty) {
          _appendToStreamingMessage(content);
        }
        break;
        
      case 'fallback_notice':
        print('Using fallback model: ${json['fallback_model']}');
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
        
      case 'error':
        state = state.copyWith(
          error: json['error']?.toString() ?? 'Unknown error',
          isStreaming: false,
          isThinking: false,
          isSearching: false,
          isScraping: false,
        );
        _finalizeStreamingMessage();
        break;
    }
  }

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

  /// SAMPLE MESSAGES FOR UI TESTING - REMOVE IN PRODUCTION
  void _loadSampleMessagesForTesting() {
    final sampleMessages = [
      // User asks for code
      ChatMessage(
        id: '1',
        role: 'user',
        content: 'Write a Python function to find the sum of an array',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      // AI responds with code
      ChatMessage(
        id: '2',
        role: 'assistant',
        content: '''Here are **simple Python codes** to find the sum of an array 👇

## 1️⃣ Using a loop (easy to understand)

```python
arr = [10, 20, 30, 40, 50]
total = 0

for i in arr:
    total += i

print("Sum of array:", total)
```

## 2️⃣ Using built-in function `sum()` (shortest way)

```python
arr = [10, 20, 30, 40, 50]
print("Sum of array:", sum(arr))
```

## 3️⃣ Taking array elements from user

```python
n = int(input("Enter number of elements: "))
arr = []

for i in range(n):
    element = int(input(f"Enter element {i+1}: "))
    arr.append(element)

print("Sum of array:", sum(arr))
```

All three methods will give you the correct sum! The `sum()` function is the most Pythonic way. 🐍''',
        timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
      ),
      // User asks a simple question
      ChatMessage(
        id: '3',
        role: 'user',
        content: 'What is the capital of France?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      // AI responds with simple text
      ChatMessage(
        id: '4',
        role: 'assistant',
        content: 'The capital of France is **Paris**. It\'s known as the "City of Light" and is famous for the Eiffel Tower, the Louvre Museum, and its rich history and culture.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
      ),
      // User asks for image generation
      ChatMessage(
        id: '5',
        role: 'user',
        content: 'Create an image: A futuristic city with flying cars at sunset',
        timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
      ),
      // AI responds about image
      ChatMessage(
        id: '6',
        role: 'assistant',
        content: '''I\'ve created a stunning image of a **futuristic city** for you! 🌆

The image features:
- Towering glass skyscrapers with holographic billboards
- Flying vehicles zipping between buildings
- A beautiful orange and purple sunset sky
- Neon lights reflecting off the sleek architecture

*Image generation complete!*

Would you like me to modify anything or create a different scene?''',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      // User asks about JavaScript
      ChatMessage(
        id: '7',
        role: 'user',
        content: 'Show me how to reverse a string in JavaScript',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      // AI responds with JS code
      ChatMessage(
        id: '8',
        role: 'assistant',
        content: '''Here are **3 different ways** to reverse a string in JavaScript:

## Method 1: Using built-in methods (easiest)

```javascript
const str = "Hello World";
const reversed = str.split('').reverse().join('');
console.log(reversed); // "dlroW olleH"
```

## Method 2: Using a for loop

```javascript
function reverseString(str) {
    let reversed = '';
    for (let i = str.length - 1; i >= 0; i--) {
        reversed += str[i];
    }
    return reversed;
}

console.log(reverseString("Hello")); // "olleH"
```

## Method 3: Using recursion

```javascript
function reverseRecursive(str) {
    if (str === '') return '';
    return reverseRecursive(str.substr(1)) + str[0];
}

console.log(reverseRecursive("JavaScript")); // "tpircSavaJ"
```

The first method is most commonly used in practice! ✨''',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ];

    state = state.copyWith(
      messages: sampleMessages,
      currentSessionId: 'sample-session',
    );
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

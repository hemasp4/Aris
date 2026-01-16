/// API configuration constants
/// Supports: Windows (localhost), Android Emulator (10.0.2.2), Ngrok tunnels
class ApiConstants {
  ApiConstants._();

  // Base URL - Using localhost for same-machine development
  // For mobile/cross-platform: use ngrok URL
  // For web on same machine: use localhost
  static String _baseUrl = 'http://localhost:8000';
  
  static String get baseUrl => _baseUrl;
  static String get apiVersion => '/api/v1';
  
  /// Set custom base URL (for Ngrok or remote access)
  static void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
  
  /// Get full API URL
  static String get apiUrl => '$_baseUrl$apiVersion';
  
  /// Get WebSocket URL
  static String get wsUrl => apiUrl.replaceFirst('http', 'ws');
  
  /// Get media URL for serving uploaded files
  static String get mediaUrl => '$_baseUrl/media';
  
  /// Build media file URL
  static String getMediaFileUrl(String filename) => '$mediaUrl/$filename';
  
  // ==================== Auth Endpoints ====================
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';
  static const String googleAuth = '/auth/google';
  
  // ==================== Chat Endpoints ====================
  static const String chats = '/chats';
  
  // Dynamic chat endpoints
  static String chatById(String chatId) => '/chats/$chatId';
  static String chatMessages(String chatId) => '/chats/$chatId/messages';
  static String chatStream(String chatId) => '/chats/$chatId/messages/stream';
  
  // Message endpoints
  static String deleteMessage(String msgId) => '/chats/messages/$msgId';
  static String undoDelete(String msgId) => '/chats/messages/$msgId/undo-delete';
  
  // ==================== Models Endpoints ====================
  static const String models = '/models';
  static const String modelsLightweight = '/models/lightweight';
  static const String modelsStatus = '/models/status';
  
  // ==================== Media & Gemini Endpoints ====================
  static const String mediaStatus = '/media/status';
  static const String mediaUpload = '/media/upload';
  static const String mediaAnalyze = '/media/analyze/image';
  static const String mediaOcr = '/media/ocr';
  
  // Audio endpoints
  static const String audioTranscribe = '/media/audio/transcribe';
  static const String audioStream = '/media/audio/stream'; // WebSocket
  
  // ==================== Scraping Endpoints ====================
  static const String scrapeUrl = '/scrape/url';
  static const String scrapeUrls = '/scrape/urls'; // Multiple URLs (max 10)
  static const String scrapeSearch = '/scrape/search';
  
  // ==================== Settings Endpoints ====================
  static const String settings = '/settings';
  static const String profile = '/settings/profile';
}

/// Storage keys for Hive and Flutter Secure Storage
class StorageKeys {
  StorageKeys._();
  
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userSettings = 'user_settings';
  static const String chatCache = 'chat_cache';
  static const String themeMode = 'theme_mode';
  static const String baseUrl = 'api_base_url';
  
  // User data for persistent login (like localStorage)
  static const String userData = 'user_data';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
}

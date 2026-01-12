import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';

/// HTTP client service using Dio with authentication interceptors
/// Supports dynamic base URL for Ngrok/Android emulator access
class DioClient {
  static DioClient? _instance;
  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  DioClient._internal() {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Required to bypass ngrok's browser warning page
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_loggingInterceptor());
  }

  factory DioClient() {
    _instance ??= DioClient._internal();
    return _instance!;
  }

  Dio get dio => _dio;

  /// Update base URL (for Ngrok or different host)
  void updateBaseUrl(String newBaseUrl) {
    ApiConstants.setBaseUrl(newBaseUrl);
    _initDio();
  }

  /// Load custom base URL from storage
  Future<void> loadStoredBaseUrl() async {
    final storedUrl = await _secureStorage.read(key: StorageKeys.baseUrl);
    if (storedUrl != null && storedUrl.isNotEmpty) {
      updateBaseUrl(storedUrl);
    }
  }

  /// Store and apply custom base URL
  Future<void> setAndStoreBaseUrl(String url) async {
    await _secureStorage.write(key: StorageKeys.baseUrl, value: url);
    updateBaseUrl(url);
  }

  /// Auth interceptor - adds token to requests and handles 401
  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Don't add token to auth endpoints
        if (!options.path.contains('/auth/')) {
          final token = await _secureStorage.read(key: StorageKeys.authToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            final opts = error.requestOptions;
            final token = await _secureStorage.read(key: StorageKeys.authToken);
            opts.headers['Authorization'] = 'Bearer $token';
            
            try {
              final response = await _dio.fetch(opts);
              handler.resolve(response);
              return;
            } catch (e) {
              handler.next(error);
              return;
            }
          }
        }
        handler.next(error);
      },
    );
  }

  /// Logging interceptor for debugging
  InterceptorsWrapper _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🌐 ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('❌ ${error.response?.statusCode} ${error.requestOptions.path}: ${error.message}');
        handler.next(error);
      },
    );
  }

  /// Refresh the access token using refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: StorageKeys.refreshToken);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${ApiConstants.apiUrl}${ApiConstants.refreshToken}',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final newToken = response.data['access_token'];
        final newRefresh = response.data['refresh_token'];
        
        await _secureStorage.write(key: StorageKeys.authToken, value: newToken);
        if (newRefresh != null) {
          await _secureStorage.write(key: StorageKeys.refreshToken, value: newRefresh);
        }
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
    return false;
  }

  /// Clear stored tokens
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: StorageKeys.authToken);
    await _secureStorage.delete(key: StorageKeys.refreshToken);
    await _secureStorage.delete(key: StorageKeys.userId);
  }

  /// Store auth tokens
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    await _secureStorage.write(key: StorageKeys.authToken, value: accessToken);
    await _secureStorage.write(key: StorageKeys.refreshToken, value: refreshToken);
    if (userId != null) {
      await _secureStorage.write(key: StorageKeys.userId, value: userId);
    }
  }

  /// Check if user has stored tokens
  Future<bool> hasValidToken() async {
    final token = await _secureStorage.read(key: StorageKeys.authToken);
    return token != null && token.isNotEmpty;
  }
}

/// Global Dio client instance
final dioClient = DioClient();

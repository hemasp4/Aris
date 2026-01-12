import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/api_constants.dart';
import 'dio_client.dart';

/// User model
class User {
  final String id;
  final String username;
  final String? email;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    this.email,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id'] ?? json['user_id'] ?? '').toString(),
      username: (json['username'] ?? json['name'] ?? json['display_name'] ?? 'User').toString(),
      email: json['email']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
    );
  }
}

/// Authentication result
class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  AuthResult({
    required this.success,
    this.user,
    this.error,
  });
}

/// Authentication service - handles login, register, logout, biometrics
class AuthService {
  final DioClient _client = dioClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Lazy-loaded Google Sign-In (requires client ID to be configured)
  GoogleSignIn? _googleSignIn;
  GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn(
      scopes: ['email', 'profile'],
    );
    return _googleSignIn!;
  }

  // ==================== Password Auth ====================

  /// Login with username and password
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Store tokens
        await _client.storeTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          userId: data['user']?['id'],
        );

        final user = User.fromJson(data['user']);
        // Save user data locally for persistent login
        await saveUserToLocal(user);

        return AuthResult(
          success: true,
          user: user,
        );
      }
      
      return AuthResult(
        success: false,
        error: 'Login failed',
      );
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Login failed';
      return AuthResult(success: false, error: message);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Register new user
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        
        // Store tokens if returned
        if (data['access_token'] != null) {
          await _client.storeTokens(
            accessToken: data['access_token'],
            refreshToken: data['refresh_token'] ?? '',
            userId: data['user']?['id'],
          );
        }

        final user = data['user'] != null ? User.fromJson(data['user']) : null;
        // Save user data locally for persistent login
        if (user != null) {
          await saveUserToLocal(user);
        }

        return AuthResult(
          success: true,
          user: user,
        );
      }
      
      return AuthResult(
        success: false,
        error: 'Registration failed',
      );
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Registration failed';
      return AuthResult(success: false, error: message);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Logout and clear tokens
  Future<void> logout() async {
    try {
      await _client.dio.post(ApiConstants.logout);
    } catch (e) {
      // Ignore errors, just clear local tokens
    }
    await _client.clearTokens();
    await clearLocalUser(); // Clear cached user data
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _client.hasValidToken();
  }

  /// Get current user info - tries local cache first, then network
  Future<User?> getCurrentUser() async {
    // First try to load from local storage (instant)
    final cachedUser = await loadUserFromLocal();
    if (cachedUser != null) {
      // Optionally refresh from server in background
      _refreshUserFromServer();
      return cachedUser;
    }
    
    // If no cached user, try to get from server
    return await _fetchUserFromServer();
  }
  
  /// Fetch user from server and cache locally
  Future<User?> _fetchUserFromServer() async {
    try {
      final response = await _client.dio.get(ApiConstants.me);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final user = User.fromJson(data);
          // Cache user data locally
          await saveUserToLocal(user);
          return user;
        }
      }
    } catch (e) {
      print('_fetchUserFromServer error: $e');
    }
    return null;
  }
  
  /// Refresh user data from server (background)
  Future<void> _refreshUserFromServer() async {
    try {
      final user = await _fetchUserFromServer();
      if (user != null) {
        await saveUserToLocal(user);
      }
    } catch (e) {
      // Ignore - we already have cached data
    }
  }

  // ==================== Local Storage (like localStorage) ====================
  
  /// Save user data to local storage for persistent login
  Future<void> saveUserToLocal(User user) async {
    await _secureStorage.write(key: StorageKeys.userId, value: user.id);
    await _secureStorage.write(key: StorageKeys.userName, value: user.username);
    if (user.email != null) {
      await _secureStorage.write(key: StorageKeys.userEmail, value: user.email!);
    }
    // Store as JSON for complete data
    final userData = '{"id":"${user.id}","username":"${user.username}","email":"${user.email ?? ""}"}';
    await _secureStorage.write(key: StorageKeys.userData, value: userData);
  }
  
  /// Load user data from local storage
  Future<User?> loadUserFromLocal() async {
    try {
      final userId = await _secureStorage.read(key: StorageKeys.userId);
      final userName = await _secureStorage.read(key: StorageKeys.userName);
      
      if (userId != null && userName != null) {
        final userEmail = await _secureStorage.read(key: StorageKeys.userEmail);
        return User(
          id: userId,
          username: userName,
          email: userEmail,
        );
      }
    } catch (e) {
      print('loadUserFromLocal error: $e');
    }
    return null;
  }
  
  /// Clear locally stored user data
  Future<void> clearLocalUser() async {
    await _secureStorage.delete(key: StorageKeys.userId);
    await _secureStorage.delete(key: StorageKeys.userName);
    await _secureStorage.delete(key: StorageKeys.userEmail);
    await _secureStorage.delete(key: StorageKeys.userData);
  }

  // ==================== Google Sign-In ====================

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return AuthResult(success: false, error: 'Sign-in cancelled');
      }

      // Get auth details from Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Send access token to backend for verification
      final response = await _client.dio.post(
        ApiConstants.googleAuth,
        data: {
          'id_token': googleAuth.idToken,
          'access_token': googleAuth.accessToken,
          'email': googleUser.email,
          'display_name': googleUser.displayName,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('Google Auth Response Data: $data'); // Debug print
        print('Data type: ${data.runtimeType}'); // Debug print

        if (data is! Map<String, dynamic>) {
          return AuthResult(success: false, error: 'Invalid response format: ${data.runtimeType}');
        }
        
        // Store tokens
        await _client.storeTokens(
          accessToken: data['access_token']?.toString() ?? '',
          refreshToken: data['refresh_token']?.toString() ?? '',
          userId: data['user']?['id']?.toString() ?? data['user_id']?.toString(),
        );

        // Parse user - handle different response formats
        User? user;
        if (data['user'] != null && data['user'] is Map<String, dynamic>) {
          user = User.fromJson(data['user'] as Map<String, dynamic>);
        } else {
          // Create user from individual fields if available
          user = User(
            id: data['user']?['id']?.toString() ?? data['user_id']?.toString() ?? '',
            username: data['user']?['username']?.toString() ?? data['username']?.toString() ?? googleUser.displayName ?? 'User',
            email: data['user']?['email']?.toString() ?? data['email']?.toString() ?? googleUser.email,
            createdAt: DateTime.now(),
          );
        }

        // Save user data locally for persistent login
        if (user != null) {
          await saveUserToLocal(user);
        }

        return AuthResult(
          success: true,
          user: user,
        );
      }
      
      return AuthResult(success: false, error: 'Google sign-in failed');
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      String message = 'Google sign-in failed';
      if (detail is String) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty) {
        message = detail.first?['msg']?.toString() ?? 'Validation error';
      }
      return AuthResult(success: false, error: message);
    } catch (e) {
      print('Google sign-in error: $e');
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
    } catch (e) {
      print('Google sign-out error: $e');
    }
  }

  // ==================== Biometric Auth ====================

  /// Check if biometrics are available
  Future<bool> isBiometricsAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to access Aris',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      print('Biometric auth error: $e');
      return false;
    }
  }

  /// Enable biometric login for current user
  Future<void> enableBiometricLogin() async {
    await _secureStorage.write(key: 'biometric_enabled', value: 'true');
  }

  /// Disable biometric login
  Future<void> disableBiometricLogin() async {
    await _secureStorage.delete(key: 'biometric_enabled');
  }

  /// Check if biometric login is enabled
  Future<bool> isBiometricLoginEnabled() async {
    final value = await _secureStorage.read(key: 'biometric_enabled');
    return value == 'true';
  }
}

/// Global auth service instance
final authService = AuthService();

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/dio_client.dart';

/// Google Sign-In service for OAuth authentication
/// Supports both Android and Windows/Web platforms
class GoogleAuthService {
  // ============================================================
  // UPDATE THESE CLIENT IDs AFTER CREATING THEM IN GOOGLE CLOUD
  // ============================================================
  
  /// Web Client ID - Used for Windows Desktop & Web
  /// Create at: Google Cloud Console > APIs & Services > Credentials > OAuth client ID > Web application
  static const String webClientId = '436531869168-fbrmoqasran5l2oda4sjddj86e017li4.apps.googleusercontent.com';
  
  /// Android Client ID - Used for Android app
  /// Create at: Google Cloud Console > APIs & Services > Credentials > OAuth client ID > Android
  /// Requires: Package name (com.example.aris_chatbot) + SHA-1 fingerprint
  static const String androidClientId = '436531869168-8vugk0hntb88a15od9rv32fmu6nakjcs.apps.googleusercontent.com';
  
  // ============================================================
  
  late final GoogleSignIn _googleSignIn;
  final DioClient _client = DioClient();

  GoogleAuthService() {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      // Use Web Client ID for serverClientId (required for backend verification)
      serverClientId: webClientId,
      // On Android, also specify the client ID
      clientId: _isAndroid ? androidClientId : null,
    );
  }

  /// Check if running on Android
  bool get _isAndroid {
    try {
      return !kIsWeb && Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }

  /// Sign in with Google
  Future<GoogleSignInResult> signIn() async {
    try {
      // Trigger Google sign-in flow
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      
      if (account == null) {
        return GoogleSignInResult(
          success: false,
          error: 'Sign-in cancelled by user',
        );
      }

      // Get auth details
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        return GoogleSignInResult(
          success: false,
          error: 'Failed to get ID token',
        );
      }

      // Send token to backend for verification
      final response = await _client.dio.post('/auth/google', data: {
        'id_token': idToken,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Store tokens
        await _client.storeTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
        );

        return GoogleSignInResult(
          success: true,
          email: account.email,
          displayName: account.displayName,
          photoUrl: account.photoUrl,
        );
      }

      return GoogleSignInResult(
        success: false,
        error: 'Backend authentication failed',
      );
    } catch (e) {
      return GoogleSignInResult(
        success: false,
        error: 'Sign-in error: $e',
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _client.clearTokens();
  }

  /// Check if already signed in
  Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  /// Silent sign in (restore previous session)
  Future<GoogleSignInResult> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        final auth = await account.authentication;
        if (auth.idToken != null) {
          return GoogleSignInResult(
            success: true,
            email: account.email,
            displayName: account.displayName,
            photoUrl: account.photoUrl,
          );
        }
      }
    } catch (e) {
      // Silent sign-in failed, user needs to sign in manually
    }
    return GoogleSignInResult(success: false);
  }

  /// Get current user info
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}

/// Result of Google sign-in attempt
class GoogleSignInResult {
  final bool success;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? error;

  GoogleSignInResult({
    required this.success,
    this.email,
    this.displayName,
    this.photoUrl,
    this.error,
  });
}

/// Global Google auth service instance
final googleAuthService = GoogleAuthService();

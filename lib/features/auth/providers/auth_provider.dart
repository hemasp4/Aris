import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';

/// Auth state enum
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Auth state model
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// Check if user is authenticated on startup
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    final isLoggedIn = await authService.isLoggedIn();
    
    if (isLoggedIn) {
      final user = await authService.getCurrentUser();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
        return;
      }
    }
    
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }

  /// Login with username and password
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    
    final result = await authService.login(
      username: username,
      password: password,
    );
    
    if (result.success && result.user != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
      );
      return true;
    }
    
    state = state.copyWith(
      status: AuthStatus.error,
      error: result.error,
    );
    return false;
  }

  /// Register new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    
    final result = await authService.register(
      username: username,
      email: email,
      password: password,
    );
    
    if (result.success) {
      // If user is returned, they're auto-logged in
      if (result.user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: result.user,
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
      return true;
    }
    
    state = state.copyWith(
      status: AuthStatus.error,
      error: result.error,
    );
    return false;
  }

  /// Logout
  Future<void> logout() async {
    await authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    final success = await authService.authenticateWithBiometrics();
    if (success) {
      // User already has stored tokens, verify them
      final user = await authService.getCurrentUser();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
        return true;
      }
    }
    return false;
  }

  /// Login with Google
  Future<bool> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    
    final result = await authService.signInWithGoogle();
    
    if (result.success && result.user != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
      );
      return true;
    }
    
    // If user cancelled, just go back to unauthenticated without showing error
    if (result.error?.toLowerCase().contains('cancel') == true) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: null);
      return false;
    }
    
    // Only show error for actual failures
    state = state.copyWith(
      status: AuthStatus.error,
      error: result.error,
    );
    return false;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.status == AuthStatus.authenticated;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Auth loading provider
final isAuthLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.status == AuthStatus.loading;
});

/// Auth error provider
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});

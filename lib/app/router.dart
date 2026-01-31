import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/chat/presentation/screens/shared_chat_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/speech_settings_screen.dart';
import '../features/settings/presentation/screens/data_controls_screen.dart';
import '../features/settings/presentation/screens/security_settings_screen.dart';
import '../features/settings/presentation/screens/general_settings_screen.dart';
import '../features/settings/presentation/screens/personalization_screen.dart';
import '../features/settings/presentation/screens/about_screen.dart';
import '../features/vault/presentation/screens/vault_screen.dart';
import '../features/insights/presentation/screens/scheduled_insights_screen.dart';
import '../features/auth/providers/auth_provider.dart';

/// Key for router refresh
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router provider that reacts to auth state
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/chat',
    refreshListenable: _RouterRefreshNotifier(ref),
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/chat/:chatId',
        name: 'chatDetail',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/speech',
        name: 'speechSettings',
        builder: (context, state) => const SpeechSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/data-controls',
        name: 'dataControlsSettings',
        builder: (context, state) => const DataControlsScreen(),
      ),
      GoRoute(
        path: '/settings/security',
        name: 'securitySettings',
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: '/settings/general',
        name: 'generalSettings',
        builder: (context, state) => const GeneralSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/personalization',
        name: 'personalizationSettings',
        builder: (context, state) => const PersonalizationScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        name: 'aboutSettings',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/vault',
        name: 'vault',
        builder: (context, state) => const VaultScreen(),
      ),
      GoRoute(
        path: '/insights',
        name: 'insights',
        builder: (context, state) => const ScheduledInsightsScreen(),
      ),
      // Shared chat route (no auth required)
      GoRoute(
        path: '/shared/:shareId',
        name: 'sharedChat',
        builder: (context, state) {
          final shareId = state.pathParameters['shareId']!;
          return SharedChatScreen(shareId: shareId);
        },
      ),
    ],
    redirect: (context, state) {
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoading = authState.status == AuthStatus.loading ||
          authState.status == AuthStatus.initial;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isSharedRoute = state.matchedLocation.startsWith('/shared/');

      // Allow shared routes without auth
      if (isSharedRoute) {
        return null;
      }

      // During loading/initial state:
      // - If on auth route, stay there (don't redirect to chat)
      // - If trying to access protected routes, redirect to login
      if (isLoading) {
        if (isAuthRoute) {
          // Stay on login/register during OAuth flow
          return null;
        }
        // Redirect to login if trying to access protected routes during initial load
        return '/login';
      }

      // Redirect to login if not authenticated and not on auth page
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // Redirect to chat if authenticated and on auth page
      if (isAuthenticated && isAuthRoute) {
        return '/chat';
      }

      return null;
    },
  );
});

/// Notifier to trigger router refresh on auth changes
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

/// Legacy router for backward compatibility
/// Use routerProvider with ref.watch instead
final appRouter = GoRouter(
  initialLocation: '/chat',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/chat/:chatId',
      name: 'chatDetail',
      builder: (context, state) {
        final chatId = state.pathParameters['chatId']!;
        return ChatScreen(chatId: chatId);
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/speech',
      name: 'speechSettings',
      builder: (context, state) => const SpeechSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/data-controls',
      name: 'dataControlsSettings',
      builder: (context, state) => const DataControlsScreen(),
    ),
    GoRoute(
      path: '/settings/security',
      name: 'securitySettings',
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
    GoRoute(
      path: '/settings/general',
      name: 'generalSettings',
      builder: (context, state) => const GeneralSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/personalization',
      name: 'personalizationSettings',
      builder: (context, state) => const PersonalizationScreen(),
    ),
    GoRoute(
      path: '/settings/about',
      name: 'aboutSettings',
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/vault',
      name: 'vault',
      builder: (context, state) => const VaultScreen(),
    ),
    GoRoute(
      path: '/insights',
      name: 'insights',
      builder: (context, state) => const ScheduledInsightsScreen(),
    ),
  ],
);

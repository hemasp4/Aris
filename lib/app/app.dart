import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/settings/providers/settings_provider.dart';
import 'router.dart';

/// Main application widget with Riverpod router and theme integration
class ArisChatbotApp extends ConsumerWidget {
  const ArisChatbotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp.router(
      title: 'Aris Chatbot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Apply font size scaling
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(settings.fontSize),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}

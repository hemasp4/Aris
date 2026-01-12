import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/settings_model.dart';
import '../services/settings_service.dart';

/// Settings state notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    await settingsService.init();
    state = settingsService.getSettings();
  }
  
  /// Update a setting and persist
  Future<void> updateSetting<T>(String key, T value) async {
    state = await settingsService.updateSetting(key, value);
  }
  
  /// Batch update multiple settings
  Future<void> updateSettings(Map<String, dynamic> updates) async {
    AppSettings current = state;
    
    for (final entry in updates.entries) {
      current = await settingsService.updateSetting(entry.key, entry.value);
    }
    
    state = current;
  }
  
  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    state = await settingsService.resetSettings();
  }
  
  /// Get theme mode as Flutter ThemeMode
  ThemeMode get themeMode {
    switch (state.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      default:
        value = 'system';
    }
    await updateSetting('themeMode', value);
  }
}

/// Main settings provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

/// Theme mode provider
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  switch (settings.themeMode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
});

/// Font size provider
final fontSizeProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).fontSize;
});

/// Default model provider
final defaultModelProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).defaultModel;
});

/// Temperature provider
final temperatureProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).temperature;
});

/// Stream responses provider
final streamResponsesProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).streamResponses;
});

/// Show timestamps provider
final showTimestampsProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).showTimestamps;
});

/// Enable markdown provider
final enableMarkdownProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).enableMarkdown;
});

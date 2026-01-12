import 'package:hive_flutter/hive_flutter.dart';

import '../models/settings_model.dart';

/// Settings service - handles persistence of app settings using Hive
class SettingsService {
  static const String _boxName = 'app_settings';
  static const String _settingsKey = 'settings';
  
  Box<AppSettings>? _box;
  
  /// Initialize the settings service
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    _box = await Hive.openBox<AppSettings>(_boxName);
  }
  
  /// Get current settings or create defaults
  AppSettings getSettings() {
    return _box?.get(_settingsKey) ?? AppSettings();
  }
  
  /// Save settings
  Future<void> saveSettings(AppSettings settings) async {
    await _box?.put(_settingsKey, settings);
  }
  
  /// Update a single setting
  Future<AppSettings> updateSetting<T>(String key, T value) async {
    final current = getSettings();
    AppSettings updated;
    
    switch (key) {
      // Appearance
      case 'themeMode':
        updated = current.copyWith(themeMode: value as String);
        break;
      case 'accentColor':
        updated = current.copyWith(accentColor: value as String);
        break;
      case 'fontSize':
        updated = current.copyWith(fontSize: value as double);
        break;
      case 'compactMode':
        updated = current.copyWith(compactMode: value as bool);
        break;
      case 'showAvatars':
        updated = current.copyWith(showAvatars: value as bool);
        break;
      case 'fontFamily':
        updated = current.copyWith(fontFamily: value as String);
        break;
        
      // Chat Behavior
      case 'sendOnEnter':
        updated = current.copyWith(sendOnEnter: value as bool);
        break;
      case 'showTimestamps':
        updated = current.copyWith(showTimestamps: value as bool);
        break;
      case 'enableMarkdown':
        updated = current.copyWith(enableMarkdown: value as bool);
        break;
      case 'enableCodeHighlighting':
        updated = current.copyWith(enableCodeHighlighting: value as bool);
        break;
      case 'streamResponses':
        updated = current.copyWith(streamResponses: value as bool);
        break;
      case 'showTypingIndicator':
        updated = current.copyWith(showTypingIndicator: value as bool);
        break;
      case 'maxContextMessages':
        updated = current.copyWith(maxContextMessages: value as int);
        break;
        
      // AI Model
      case 'defaultModel':
        updated = current.copyWith(defaultModel: value as String);
        break;
      case 'temperature':
        updated = current.copyWith(temperature: value as double);
        break;
      case 'maxTokens':
        updated = current.copyWith(maxTokens: value as int);
        break;
      case 'systemPrompt':
        updated = current.copyWith(systemPrompt: value as String);
        break;
      case 'favoriteModels':
        updated = current.copyWith(favoriteModels: value as List<String>);
        break;
        
      // Security
      case 'biometricEnabled':
        updated = current.copyWith(biometricEnabled: value as bool);
        break;
      case 'autoLockEnabled':
        updated = current.copyWith(autoLockEnabled: value as bool);
        break;
      case 'autoLockTimeout':
        updated = current.copyWith(autoLockTimeout: value as int);
        break;
      case 'requireAuthOnLaunch':
        updated = current.copyWith(requireAuthOnLaunch: value as bool);
        break;
        
      // Privacy
      case 'saveHistory':
        updated = current.copyWith(saveHistory: value as bool);
        break;
      case 'shareChatData':
        updated = current.copyWith(shareChatData: value as bool);
        break;
      case 'historyRetentionDays':
        updated = current.copyWith(historyRetentionDays: value as int);
        break;
        
      // Notifications
      case 'notificationsEnabled':
        updated = current.copyWith(notificationsEnabled: value as bool);
        break;
      case 'soundEnabled':
        updated = current.copyWith(soundEnabled: value as bool);
        break;
      case 'vibrationEnabled':
        updated = current.copyWith(vibrationEnabled: value as bool);
        break;
        
      // Data & Storage
      case 'autoSaveChats':
        updated = current.copyWith(autoSaveChats: value as bool);
        break;
      case 'exportFormat':
        updated = current.copyWith(exportFormat: value as String);
        break;
      case 'cacheImages':
        updated = current.copyWith(cacheImages: value as bool);
        break;
        
      // Accessibility
      case 'reduceMotion':
        updated = current.copyWith(reduceMotion: value as bool);
        break;
      case 'highContrast':
        updated = current.copyWith(highContrast: value as bool);
        break;
      case 'screenReaderOptimized':
        updated = current.copyWith(screenReaderOptimized: value as bool);
        break;
        
      // Advanced
      case 'apiEndpoint':
        updated = current.copyWith(apiEndpoint: value as String);
        break;
      case 'requestTimeout':
        updated = current.copyWith(requestTimeout: value as int);
        break;
      case 'debugMode':
        updated = current.copyWith(debugMode: value as bool);
        break;
      case 'language':
        updated = current.copyWith(language: value as String);
        break;
        
      default:
        updated = current;
    }
    
    await saveSettings(updated);
    return updated;
  }
  
  /// Reset all settings to defaults
  Future<AppSettings> resetSettings() async {
    final defaults = AppSettings();
    await saveSettings(defaults);
    return defaults;
  }
  
  /// Export settings as JSON
  Map<String, dynamic> exportSettings() {
    return getSettings().toJson();
  }
  
  /// Clear all data
  Future<void> clearAll() async {
    await _box?.clear();
  }
}

/// Global settings service instance
final settingsService = SettingsService();

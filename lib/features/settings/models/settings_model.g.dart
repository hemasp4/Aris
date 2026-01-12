// GENERATED CODE - DO NOT MODIFY BY HAND
// This file is manually created to avoid build_runner dependency

part of 'settings_model.dart';

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 0;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      themeMode: fields[0] as String? ?? 'system',
      accentColor: fields[1] as String? ?? '#4F46E5',
      fontSize: fields[2] as double? ?? 1.0,
      compactMode: fields[3] as bool? ?? false,
      showAvatars: fields[4] as bool? ?? true,
      fontFamily: fields[5] as String? ?? 'Inter',
      sendOnEnter: fields[10] as bool? ?? true,
      showTimestamps: fields[11] as bool? ?? true,
      enableMarkdown: fields[12] as bool? ?? true,
      enableCodeHighlighting: fields[13] as bool? ?? true,
      streamResponses: fields[14] as bool? ?? true,
      showTypingIndicator: fields[15] as bool? ?? true,
      maxContextMessages: fields[16] as int? ?? 20,
      defaultModel: fields[20] as String? ?? 'llama3.2',
      temperature: fields[21] as double? ?? 0.7,
      maxTokens: fields[22] as int? ?? 0,
      systemPrompt: fields[23] as String? ?? '',
      favoriteModels: (fields[24] as List?)?.cast<String>() ?? [],
      biometricEnabled: fields[30] as bool? ?? false,
      autoLockEnabled: fields[31] as bool? ?? true,
      autoLockTimeout: fields[32] as int? ?? 5,
      requireAuthOnLaunch: fields[33] as bool? ?? false,
      saveHistory: fields[40] as bool? ?? true,
      shareChatData: fields[41] as bool? ?? false,
      historyRetentionDays: fields[42] as int? ?? 0,
      notificationsEnabled: fields[50] as bool? ?? true,
      soundEnabled: fields[51] as bool? ?? true,
      vibrationEnabled: fields[52] as bool? ?? true,
      autoSaveChats: fields[60] as bool? ?? true,
      exportFormat: fields[61] as String? ?? 'markdown',
      cacheImages: fields[62] as bool? ?? true,
      reduceMotion: fields[70] as bool? ?? false,
      highContrast: fields[71] as bool? ?? false,
      screenReaderOptimized: fields[72] as bool? ?? false,
      apiEndpoint: fields[80] as String? ?? 'http://localhost:8000',
      requestTimeout: fields[81] as int? ?? 30,
      debugMode: fields[82] as bool? ?? false,
      language: fields[83] as String? ?? 'en',
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(38)
      ..writeByte(0)..write(obj.themeMode)
      ..writeByte(1)..write(obj.accentColor)
      ..writeByte(2)..write(obj.fontSize)
      ..writeByte(3)..write(obj.compactMode)
      ..writeByte(4)..write(obj.showAvatars)
      ..writeByte(5)..write(obj.fontFamily)
      ..writeByte(10)..write(obj.sendOnEnter)
      ..writeByte(11)..write(obj.showTimestamps)
      ..writeByte(12)..write(obj.enableMarkdown)
      ..writeByte(13)..write(obj.enableCodeHighlighting)
      ..writeByte(14)..write(obj.streamResponses)
      ..writeByte(15)..write(obj.showTypingIndicator)
      ..writeByte(16)..write(obj.maxContextMessages)
      ..writeByte(20)..write(obj.defaultModel)
      ..writeByte(21)..write(obj.temperature)
      ..writeByte(22)..write(obj.maxTokens)
      ..writeByte(23)..write(obj.systemPrompt)
      ..writeByte(24)..write(obj.favoriteModels)
      ..writeByte(30)..write(obj.biometricEnabled)
      ..writeByte(31)..write(obj.autoLockEnabled)
      ..writeByte(32)..write(obj.autoLockTimeout)
      ..writeByte(33)..write(obj.requireAuthOnLaunch)
      ..writeByte(40)..write(obj.saveHistory)
      ..writeByte(41)..write(obj.shareChatData)
      ..writeByte(42)..write(obj.historyRetentionDays)
      ..writeByte(50)..write(obj.notificationsEnabled)
      ..writeByte(51)..write(obj.soundEnabled)
      ..writeByte(52)..write(obj.vibrationEnabled)
      ..writeByte(60)..write(obj.autoSaveChats)
      ..writeByte(61)..write(obj.exportFormat)
      ..writeByte(62)..write(obj.cacheImages)
      ..writeByte(70)..write(obj.reduceMotion)
      ..writeByte(71)..write(obj.highContrast)
      ..writeByte(72)..write(obj.screenReaderOptimized)
      ..writeByte(80)..write(obj.apiEndpoint)
      ..writeByte(81)..write(obj.requestTimeout)
      ..writeByte(82)..write(obj.debugMode)
      ..writeByte(83)..write(obj.language);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

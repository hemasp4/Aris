import 'package:hive/hive.dart';

part 'settings_model.g.dart';

/// App settings model with Hive persistence
@HiveType(typeId: 0)
class AppSettings extends HiveObject {
  // ==================== Appearance ====================
  @HiveField(0)
  String themeMode; // 'system', 'light', 'dark'

  @HiveField(1)
  String accentColor; // hex color

  @HiveField(2)
  double fontSize; // 0.8 - 1.4

  @HiveField(3)
  bool compactMode;

  @HiveField(4)
  bool showAvatars;

  @HiveField(5)
  String fontFamily; // 'Inter', 'Roboto', 'System'

  // ==================== Chat Behavior ====================
  @HiveField(10)
  bool sendOnEnter;

  @HiveField(11)
  bool showTimestamps;

  @HiveField(12)
  bool enableMarkdown;

  @HiveField(13)
  bool enableCodeHighlighting;

  @HiveField(14)
  bool streamResponses;

  @HiveField(15)
  bool showTypingIndicator;

  @HiveField(16)
  int maxContextMessages; // 0 = unlimited

  // ==================== AI Model ====================
  @HiveField(20)
  String defaultModel;

  @HiveField(21)
  double temperature; // 0.0 - 2.0

  @HiveField(22)
  int maxTokens; // 0 = model default

  @HiveField(23)
  String systemPrompt;

  @HiveField(24)
  List<String> favoriteModels;

  // ==================== Security ====================
  @HiveField(30)
  bool biometricEnabled;

  @HiveField(31)
  bool autoLockEnabled;

  @HiveField(32)
  int autoLockTimeout; // minutes

  @HiveField(33)
  bool requireAuthOnLaunch;

  // ==================== Privacy ====================
  @HiveField(40)
  bool saveHistory;

  @HiveField(41)
  bool shareChatData; // for analytics

  @HiveField(42)
  int historyRetentionDays; // 0 = forever

  // ==================== Notifications ====================
  @HiveField(50)
  bool notificationsEnabled;

  @HiveField(51)
  bool soundEnabled;

  @HiveField(52)
  bool vibrationEnabled;

  // ==================== Data & Storage ====================
  @HiveField(60)
  bool autoSaveChats;

  @HiveField(61)
  String exportFormat; // 'json', 'markdown', 'txt'

  @HiveField(62)
  bool cacheImages;

  // ==================== Accessibility ====================
  @HiveField(70)
  bool reduceMotion;

  @HiveField(71)
  bool highContrast;

  @HiveField(72)
  bool screenReaderOptimized;

  // ==================== Advanced ====================
  @HiveField(80)
  String apiEndpoint;

  @HiveField(81)
  int requestTimeout; // seconds

  @HiveField(82)
  bool debugMode;

  @HiveField(83)
  String language; // 'en', 'es', etc.

  AppSettings({
    this.themeMode = 'system',
    this.accentColor = '#4F46E5',
    this.fontSize = 1.0,
    this.compactMode = false,
    this.showAvatars = true,
    this.fontFamily = 'Inter',
    this.sendOnEnter = true,
    this.showTimestamps = true,
    this.enableMarkdown = true,
    this.enableCodeHighlighting = true,
    this.streamResponses = true,
    this.showTypingIndicator = true,
    this.maxContextMessages = 20,
    this.defaultModel = 'llama3.2',
    this.temperature = 0.7,
    this.maxTokens = 0,
    this.systemPrompt = '',
    this.favoriteModels = const [],
    this.biometricEnabled = false,
    this.autoLockEnabled = true,
    this.autoLockTimeout = 5,
    this.requireAuthOnLaunch = false,
    this.saveHistory = true,
    this.shareChatData = false,
    this.historyRetentionDays = 0,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.autoSaveChats = true,
    this.exportFormat = 'markdown',
    this.cacheImages = true,
    this.reduceMotion = false,
    this.highContrast = false,
    this.screenReaderOptimized = false,
    this.apiEndpoint = 'http://localhost:8000',
    this.requestTimeout = 30,
    this.debugMode = false,
    this.language = 'en',
  });

  /// Create a copy with updated values
  AppSettings copyWith({
    String? themeMode,
    String? accentColor,
    double? fontSize,
    bool? compactMode,
    bool? showAvatars,
    String? fontFamily,
    bool? sendOnEnter,
    bool? showTimestamps,
    bool? enableMarkdown,
    bool? enableCodeHighlighting,
    bool? streamResponses,
    bool? showTypingIndicator,
    int? maxContextMessages,
    String? defaultModel,
    double? temperature,
    int? maxTokens,
    String? systemPrompt,
    List<String>? favoriteModels,
    bool? biometricEnabled,
    bool? autoLockEnabled,
    int? autoLockTimeout,
    bool? requireAuthOnLaunch,
    bool? saveHistory,
    bool? shareChatData,
    int? historyRetentionDays,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? autoSaveChats,
    String? exportFormat,
    bool? cacheImages,
    bool? reduceMotion,
    bool? highContrast,
    bool? screenReaderOptimized,
    String? apiEndpoint,
    int? requestTimeout,
    bool? debugMode,
    String? language,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      fontSize: fontSize ?? this.fontSize,
      compactMode: compactMode ?? this.compactMode,
      showAvatars: showAvatars ?? this.showAvatars,
      fontFamily: fontFamily ?? this.fontFamily,
      sendOnEnter: sendOnEnter ?? this.sendOnEnter,
      showTimestamps: showTimestamps ?? this.showTimestamps,
      enableMarkdown: enableMarkdown ?? this.enableMarkdown,
      enableCodeHighlighting: enableCodeHighlighting ?? this.enableCodeHighlighting,
      streamResponses: streamResponses ?? this.streamResponses,
      showTypingIndicator: showTypingIndicator ?? this.showTypingIndicator,
      maxContextMessages: maxContextMessages ?? this.maxContextMessages,
      defaultModel: defaultModel ?? this.defaultModel,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      favoriteModels: favoriteModels ?? this.favoriteModels,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      requireAuthOnLaunch: requireAuthOnLaunch ?? this.requireAuthOnLaunch,
      saveHistory: saveHistory ?? this.saveHistory,
      shareChatData: shareChatData ?? this.shareChatData,
      historyRetentionDays: historyRetentionDays ?? this.historyRetentionDays,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      autoSaveChats: autoSaveChats ?? this.autoSaveChats,
      exportFormat: exportFormat ?? this.exportFormat,
      cacheImages: cacheImages ?? this.cacheImages,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
      screenReaderOptimized: screenReaderOptimized ?? this.screenReaderOptimized,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      debugMode: debugMode ?? this.debugMode,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode,
    'accentColor': accentColor,
    'fontSize': fontSize,
    'compactMode': compactMode,
    'showAvatars': showAvatars,
    'fontFamily': fontFamily,
    'sendOnEnter': sendOnEnter,
    'showTimestamps': showTimestamps,
    'enableMarkdown': enableMarkdown,
    'enableCodeHighlighting': enableCodeHighlighting,
    'streamResponses': streamResponses,
    'showTypingIndicator': showTypingIndicator,
    'maxContextMessages': maxContextMessages,
    'defaultModel': defaultModel,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'systemPrompt': systemPrompt,
    'favoriteModels': favoriteModels,
    'biometricEnabled': biometricEnabled,
    'autoLockEnabled': autoLockEnabled,
    'autoLockTimeout': autoLockTimeout,
    'requireAuthOnLaunch': requireAuthOnLaunch,
    'saveHistory': saveHistory,
    'shareChatData': shareChatData,
    'historyRetentionDays': historyRetentionDays,
    'notificationsEnabled': notificationsEnabled,
    'soundEnabled': soundEnabled,
    'vibrationEnabled': vibrationEnabled,
    'autoSaveChats': autoSaveChats,
    'exportFormat': exportFormat,
    'cacheImages': cacheImages,
    'reduceMotion': reduceMotion,
    'highContrast': highContrast,
    'screenReaderOptimized': screenReaderOptimized,
    'apiEndpoint': apiEndpoint,
    'requestTimeout': requestTimeout,
    'debugMode': debugMode,
    'language': language,
  };
}

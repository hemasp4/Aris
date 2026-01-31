import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/services/dio_client.dart';
import 'features/settings/models/settings_model.dart';
import 'features/settings/services/settings_service.dart';
import 'features/chat/models/chat_adapters.dart';
import 'features/chat/providers/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register Hive adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ChatSessionAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(ChatMessageAdapter());
  }
  
  // Initialize settings service
  await settingsService.init();
  
  // Open Hive Chat Boxes
  await Hive.openBox<ChatSession>('sessions');
  await Hive.openBox<ChatMessage>('messages'); // We'll open specific message boxes lazily or use one big one? 
  // Better: One box per chat or one big box? 
  // For 'messages', we usually key them by ID. But we need to query by chatID.
  // Actually, 'messages' box might be generic. Let's open 'chat_cache' box.
  await Hive.openBox('chat_cache'); // For metadata or other needs
  
  // Load stored server URL (for ngrok/custom backend)
  await dioClient.loadStoredBaseUrl();
  
  // Run the app with Riverpod
  runApp(
    const ProviderScope(
      child: ArisChatbotApp(),
    ),
  );
}

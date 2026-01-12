import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'features/settings/models/settings_model.dart';
import 'features/settings/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register Hive adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }
  
  // Initialize settings service
  await settingsService.init();
  
  // Run the app with Riverpod
  runApp(
    const ProviderScope(
      child: ArisChatbotApp(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import '../core/database/app_database.dart';
import '../core/services/app_preferences.dart';
import '../core/services/api_service.dart';
import '../core/services/sync_service.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    await AppDatabase.instance.database;
    final preferences = await AppPreferences.getInstance();

    // Restore auth token if exists
    final token = preferences.token;
    if (token != null) {
      ApiService.instance.setToken(token);
    }

    runApp(
      const ProviderScope(
        child: DevConnectApp(),
      ),
    );

    // Pull latest data from backend after UI is rendered (offline-first, non-blocking)
    // ignore: unused_result
    SyncService().pullAll();
  }
}

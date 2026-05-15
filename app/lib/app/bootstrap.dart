import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app.dart';
import '../core/database/app_database.dart';
import '../core/services/app_preferences.dart';
import '../core/services/api_service.dart';
import '../core/services/sync_service.dart';
import '../core/services/push_notification_service.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    _configureDatabaseFactory();
    await AppDatabase.instance.database;
    final preferences = await AppPreferences.getInstance();
    await PushNotificationService.instance.initialize();

    // Restore auth token if exists
    final token = preferences.token;
    if (token != null) {
      ApiService.instance.setToken(token);
    }

    runApp(const ProviderScope(child: DevConnectApp()));

    // Pull latest data from backend after UI is rendered (offline-first, non-blocking)
    // ignore: unused_result
    SyncService().pullAll();
  }

  static void _configureDatabaseFactory() {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }
}

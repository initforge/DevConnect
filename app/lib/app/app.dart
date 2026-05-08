import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devconnect/core/riverpod/providers.dart';
import 'package:devconnect/core/theme/app_theme.dart';
import 'package:devconnect/routing/app_router.dart';

class DevConnectApp extends ConsumerWidget {
  const DevConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'DevConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}

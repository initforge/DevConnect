import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/comment_repository.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../services/ai_service.dart';
import '../services/api_service.dart';
import '../services/app_preferences.dart';

part 'providers.g.dart';

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.light;

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeModeNotifierProvider);
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(Locale(AppPreferences.instance.languageCode));

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await AppPreferences.instance.setLanguageCode(locale.languageCode);
  }
}

final appLocaleProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

final apiServiceProvider = Provider<ApiService>((ref) => ApiService.instance);

final appPreferencesProvider = Provider<AppPreferences>(
  (ref) => AppPreferences.instance,
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(),
);

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(userRepository: ref.watch(userRepositoryProvider)),
);

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(),
);

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepository(),
);

final jobRepositoryProvider = Provider<JobRepository>((ref) => JobRepository());

final aiServiceProvider = Provider<AiService>((ref) => AiService.instance);

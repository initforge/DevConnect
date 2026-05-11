/// DevConnect — App Constants
class AppConstants {
  AppConstants._();

  // App Info
  static const appName = 'DevConnect';
  static const appVersion = '1.0.0';

  // API Configuration. Override per target with --dart-define.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8081',
  );

  // Connection timeouts
  static const Duration apiConnectTimeout = Duration(seconds: 30);
  static const Duration apiReceiveTimeout = Duration(seconds: 30);
  static const Duration wsReconnectBaseDelay = Duration(seconds: 1);
  static const Duration wsReconnectMaxDelay = Duration(seconds: 30);
  static const Duration wsHeartbeatInterval = Duration(seconds: 30);

  // Pagination
  static const defaultPageSize = 20;
  static const maxPageSize = 100;

  // Cache TTL
  static const feedCacheTTL = Duration(minutes: 5);
  static const profileCacheTTL = Duration(minutes: 10);
  static const notificationsCacheTTL = Duration(minutes: 2);

  // Validation
  static const minPasswordLength = 8;
  static const maxPostLength = 50000;
  static const maxCommentLength = 5000;
  static const maxBioLength = 500;
  static const maxImageSize = 5 * 1024 * 1024; // 5MB
  static const maxVideoSize = 50 * 1024 * 1024; // 50MB

  // Animation Durations
  static const animFast = Duration(milliseconds: 150);
  static const animNormal = Duration(milliseconds: 250);
  static const animSlow = Duration(milliseconds: 350);

  // Debounce
  static const searchDebounce = Duration(milliseconds: 300);
  static const typingDebounce = Duration(seconds: 2);

  // Auth Endpoints (used by AuthService)
  static const String apiAuthLogin = '/auth/login';
  static const String apiAuthRegister = '/auth/register';
  static const String apiAuthRefresh = '/auth/refresh';
  static const String apiAuthLogout = '/auth/logout';
}

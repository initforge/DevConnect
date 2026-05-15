import 'package:flutter/foundation.dart';

/// Push notification service scaffold.
///
/// Full FCM integration requires Firebase project setup.
/// See plan/feature-02-push-notifications-fcm.md for implementation steps.
///
/// TODO: Add firebase_core + firebase_messaging to pubspec.yaml
/// TODO: Configure google-services.json (Android) + GoogleService-Info.plist (iOS)
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;

  /// Initialize push notifications.
  /// Currently a no-op until Firebase is configured.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (kDebugMode) {
      debugPrint(
        '[PushNotificationService] Scaffold only — Firebase not configured',
      );
    }
  }

  /// Register FCM token with backend.
  /// No-op until Firebase is configured.
  Future<void> registerToken(String userId) async {
    if (kDebugMode) {
      debugPrint(
        '[PushNotificationService] registerToken($userId) — scaffold only',
      );
    }
  }

  /// Handle foreground notification.
  void onMessage(Map<String, dynamic> data) {
    if (kDebugMode) {
      debugPrint('[PushNotificationService] onMessage: $data');
    }
  }
}

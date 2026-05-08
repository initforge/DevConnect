import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devconnect/core/services/app_preferences.dart';

void main() {
  late AppPreferences preferences;

  setUp(() async {
    // Set up mock shared preferences
    SharedPreferences.setMockInitialValues({});
    preferences = await AppPreferences.getInstance();
  });

  group('AppPreferences - Token Management', () {
    test('saveToken() and getToken() work correctly', () async {
      await preferences.saveToken('test_auth_token');
      expect(preferences.token, 'test_auth_token');
    });

    test('clearToken() removes the token', () async {
      await preferences.saveToken('test_token');
      await preferences.clearToken();
      expect(preferences.token, isNull);
    });

    test('token returns null when not set', () {
      expect(preferences.token, isNull);
    });

    test('token persists across multiple getInstance calls', () async {
      await preferences.saveToken('persistent_token');
      final prefs2 = await AppPreferences.getInstance();
      expect(prefs2.token, 'persistent_token');
    });
  });

  group('AppPreferences - User Data', () {
    test('saveUser() and getUser() work correctly', () async {
      final userData = {
        'id': 'u1',
        'username': 'testuser',
        'displayName': 'Test User',
        'email': 'test@test.com',
      };
      await preferences.saveUser(userData);
      
      final retrieved = preferences.user;
      expect(retrieved, isNotNull);
      expect(retrieved!['id'], 'u1');
      expect(retrieved['username'], 'testuser');
      expect(retrieved['displayName'], 'Test User');
      expect(retrieved['email'], 'test@test.com');
    });

    test('clearUser() removes user data', () async {
      final userData = {'id': 'u1', 'username': 'test'};
      await preferences.saveUser(userData);
      await preferences.clearUser();
      expect(preferences.user, isNull);
    });

    test('user returns null when not set', () {
      expect(preferences.user, isNull);
    });

    test('user data handles complex nested objects', () async {
      final userData = {
        'id': 'u1',
        'metadata': {
          'created': '2024-01-01',
          'roles': ['admin', 'user'],
        },
      };
      await preferences.saveUser(userData);
      final retrieved = preferences.user;
      
      expect(retrieved!['id'], 'u1');
      expect(retrieved['metadata'], isA<Map>());
      expect(retrieved['metadata']['roles'], ['admin', 'user']);
    });
  });

  group('AppPreferences - clearAuth()', () {
    test('clearAuth() removes both token and user', () async {
      await preferences.saveToken('test_token');
      await preferences.saveUser({'id': 'u1'});
      
      await preferences.clearAuth();
      
      expect(preferences.token, isNull);
      expect(preferences.user, isNull);
    });
  });

  group('AppPreferences - Settings', () {
    test('darkMode defaults to false', () {
      expect(preferences.darkMode, false);
    });

    test('darkMode can be set and retrieved', () async {
      await preferences.setDarkMode(true);
      expect(preferences.darkMode, true);
      
      await preferences.setDarkMode(false);
      expect(preferences.darkMode, false);
    });

    test('pushNotif defaults to true', () {
      expect(preferences.pushNotif, true);
    });

    test('pushNotif can be toggled', () async {
      await preferences.setPushNotif(false);
      expect(preferences.pushNotif, false);
    });

    test('emailNotif defaults to true', () {
      expect(preferences.emailNotif, true);
    });

    test('emailNotif can be toggled', () async {
      await preferences.setEmailNotif(false);
      expect(preferences.emailNotif, false);
    });

    test('soundEnabled defaults to true', () {
      expect(preferences.soundEnabled, true);
    });

    test('soundEnabled can be toggled', () async {
      await preferences.setSoundEnabled(false);
      expect(preferences.soundEnabled, false);
    });

    test('privateProfile defaults to false', () {
      expect(preferences.privateProfile, false);
    });

    test('privateProfile can be toggled', () async {
      await preferences.setPrivateProfile(true);
      expect(preferences.privateProfile, true);
    });
  });

  group('AppPreferences - Onboarding', () {
    test('onboardingCompleted defaults to false', () {
      expect(preferences.onboardingCompleted, false);
    });

    test('onboardingCompleted can be set to true', () async {
      await preferences.setOnboardingCompleted(true);
      expect(preferences.onboardingCompleted, true);
    });

    test('onboardingCompleted persists across instances', () async {
      await preferences.setOnboardingCompleted(true);
      final prefs2 = await AppPreferences.getInstance();
      expect(prefs2.onboardingCompleted, true);
    });

    test('onboardingData returns null when not set', () {
      expect(preferences.onboardingData, isNull);
    });

    test('saveOnboardingData() stores languages, frameworks, topics', () async {
      await preferences.saveOnboardingData(
        languages: ['Dart', 'Python'],
        frameworks: ['Flutter', 'FastAPI'],
        topics: ['Mobile', 'Backend'],
      );
      
      final data = preferences.onboardingData;
      expect(data, isNotNull);
      expect(data!['languages'], ['Dart', 'Python']);
      expect(data['frameworks'], ['Flutter', 'FastAPI']);
      expect(data['topics'], ['Mobile', 'Backend']);
    });

    test('onboardingData persists across instances', () async {
      await preferences.saveOnboardingData(
        languages: ['JavaScript'],
        frameworks: ['React'],
        topics: ['Frontend'],
      );
      
      final prefs2 = await AppPreferences.getInstance();
      final data = prefs2.onboardingData;
      expect(data!['languages'], ['JavaScript']);
    });

    test('clearOnboarding() removes onboarding data', () async {
      await preferences.setOnboardingCompleted(true);
      await preferences.saveOnboardingData(
        languages: ['Test'],
        frameworks: [],
        topics: [],
      );
      
      await preferences.clearOnboarding();
      
      expect(preferences.onboardingCompleted, false);
      expect(preferences.onboardingData, isNull);
    });
  });

  group('AppPreferences - getInstance()', () {
    test('getInstance() returns same instance on subsequent calls', () async {
      final instance1 = await AppPreferences.getInstance();
      final instance2 = await AppPreferences.getInstance();
      expect(identical(instance1, instance2), isTrue);
    });

    test('getInstance() can be called multiple times', () async {
      await AppPreferences.getInstance();
      await AppPreferences.getInstance();
      await AppPreferences.getInstance();
      // Should not throw
    });
  });

  group('AppPreferences - Edge Cases', () {
    test('handles empty user data', () async {
      await preferences.saveUser({});
      expect(preferences.user, {});
    });

    test('handles user data with special characters', () async {
      final userData = {
        'name': 'Test User <script>alert("xss")</script>',
        'bio': 'Developer with "quotes" and \'apostrophes\'',
      };
      await preferences.saveUser(userData);
      final retrieved = preferences.user;
      
      expect(retrieved!['name'], contains('Test User'));
    });

    test('handles onboarding data with empty lists', () async {
      await preferences.saveOnboardingData(
        languages: [],
        frameworks: [],
        topics: [],
      );
      
      final data = preferences.onboardingData;
      expect(data!['languages'], isEmpty);
      expect(data['frameworks'], isEmpty);
      expect(data['topics'], isEmpty);
    });
  });
}

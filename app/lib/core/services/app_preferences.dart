import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._(this._prefs);

  static AppPreferences? _instance;
  final SharedPreferences _prefs;

  static AppPreferences get instance {
    if (_instance == null) {
      throw StateError(
        'AppPreferences not initialized. Call getInstance() first.',
      );
    }
    return _instance!;
  }

  static const _darkModeKey = 'settings.darkMode';
  static const _pushNotifKey = 'settings.pushNotif';
  static const _emailNotifKey = 'settings.emailNotif';
  static const _soundEnabledKey = 'settings.soundEnabled';
  static const _privateProfileKey = 'settings.privateProfile';
  static const _onlineStatusKey = 'settings.onlineStatus';
  static const _messagePermissionKey = 'settings.messagePermission';
  static const _quietHoursKey = 'settings.quietHours';
  static const _languageCodeKey = 'settings.languageCode';
  static const _recentSearchesKey = 'search.recentQueries';
  static const _teamInviteStateKey = 'notifications.teamInviteState';
  static const _tokenKey = 'auth.token';
  static const _refreshTokenKey = 'auth.refreshToken';
  static const _userKey = 'auth.user';
  static const _onboardingCompletedKey = 'onboarding.completed';
  static const _onboardingDataKey = 'onboarding.data';

  static Future<AppPreferences> getInstance() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = AppPreferences._(prefs);
    return _instance!;
  }

  bool get darkMode => _prefs.getBool(_darkModeKey) ?? false;
  bool get pushNotif => _prefs.getBool(_pushNotifKey) ?? true;
  bool get emailNotif => _prefs.getBool(_emailNotifKey) ?? true;
  bool get soundEnabled => _prefs.getBool(_soundEnabledKey) ?? true;
  bool get privateProfile => _prefs.getBool(_privateProfileKey) ?? false;
  bool get onlineStatus => _prefs.getBool(_onlineStatusKey) ?? true;
  String get messagePermission =>
      _prefs.getString(_messagePermissionKey) ?? 'Everyone';
  String get quietHours => _prefs.getString(_quietHoursKey) ?? '10 PM - 8 AM';
  String get languageCode => _prefs.getString(_languageCodeKey) ?? 'en';
  List<String> get recentSearches =>
      _prefs.getStringList(_recentSearchesKey) ?? const [];
  String? get teamInviteState => _prefs.getString(_teamInviteStateKey);

  Future<void> setDarkMode(bool value) => _prefs.setBool(_darkModeKey, value);
  Future<void> setPushNotif(bool value) => _prefs.setBool(_pushNotifKey, value);
  Future<void> setEmailNotif(bool value) =>
      _prefs.setBool(_emailNotifKey, value);
  Future<void> setSoundEnabled(bool value) =>
      _prefs.setBool(_soundEnabledKey, value);
  Future<void> setPrivateProfile(bool value) =>
      _prefs.setBool(_privateProfileKey, value);
  Future<void> setOnlineStatus(bool value) =>
      _prefs.setBool(_onlineStatusKey, value);
  Future<void> setMessagePermission(String value) =>
      _prefs.setString(_messagePermissionKey, value);
  Future<void> setQuietHours(String value) =>
      _prefs.setString(_quietHoursKey, value);
  Future<void> setLanguageCode(String value) =>
      _prefs.setString(_languageCodeKey, value);
  Future<void> setTeamInviteState(String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs.remove(_teamInviteStateKey);
      return;
    }
    await _prefs.setString(_teamInviteStateKey, value);
  }

  Future<void> saveRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final next =
        [
          trimmed,
          ...recentSearches.where(
            (item) => item.toLowerCase() != trimmed.toLowerCase(),
          ),
        ].take(8).toList();

    await _prefs.setStringList(_recentSearchesKey, next);
  }

  Future<void> clearRecentSearches() => _prefs.remove(_recentSearchesKey);

  // Auth token
  String? get token => _prefs.getString(_tokenKey);
  Future<void> saveToken(String token) => _prefs.setString(_tokenKey, token);
  Future<void> clearToken() => _prefs.remove(_tokenKey);

  // Refresh token
  String? get refreshToken => _prefs.getString(_refreshTokenKey);
  Future<void> saveRefreshToken(String token) =>
      _prefs.setString(_refreshTokenKey, token);
  Future<void> clearRefreshToken() => _prefs.remove(_refreshTokenKey);

  // User data
  Map<String, dynamic>? get user {
    final data = _prefs.getString(_userKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  String? get userId => user?['id']?.toString();

  Future<void> saveUser(Map<String, dynamic> userData) =>
      _prefs.setString(_userKey, jsonEncode(userData));
  Future<void> clearUser() => _prefs.remove(_userKey);

  // Clear all auth data
  Future<void> clearAuth() async {
    await clearToken();
    await clearRefreshToken();
    await clearUser();
  }

  // Onboarding completion flag
  bool get onboardingCompleted =>
      _prefs.getBool(_onboardingCompletedKey) ?? false;
  Future<void> setOnboardingCompleted(bool value) =>
      _prefs.setBool(_onboardingCompletedKey, value);

  // Onboarding data (languages, frameworks, topics)
  Map<String, List<String>>? get onboardingData {
    final data = _prefs.getString(_onboardingDataKey);
    if (data == null) return null;
    final decoded = jsonDecode(data) as Map<String, dynamic>;
    return {
      for (final key in decoded.keys)
        key: List<String>.from(decoded[key] as List),
    };
  }

  Future<void> saveOnboardingData({
    required List<String> languages,
    required List<String> frameworks,
    required List<String> topics,
  }) async {
    final data = jsonEncode({
      'languages': languages,
      'frameworks': frameworks,
      'topics': topics,
    });
    await _prefs.setString(_onboardingDataKey, data);
  }

  Future<void> clearOnboarding() async {
    await _prefs.remove(_onboardingCompletedKey);
    await _prefs.remove(_onboardingDataKey);
  }

  // Draft persistence
  Future<void> setDraft(String key, String value) async {
    await _prefs.setString('draft_$key', value);
  }

  String? getDraft(String key) => _prefs.getString('draft_$key');

  Future<void> clearDraft(String key) async {
    await _prefs.remove('draft_$key');
  }
}

import 'package:flutter/material.dart';

import '../services/app_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController(this._preferences);

  final AppPreferences _preferences;

  bool _darkMode = false;
  bool _pushNotif = true;
  bool _emailNotif = true;
  bool _soundEnabled = true;
  bool _privateProfile = false;

  bool get darkMode => _darkMode;
  bool get pushNotif => _pushNotif;
  bool get emailNotif => _emailNotif;
  bool get soundEnabled => _soundEnabled;
  bool get privateProfile => _privateProfile;
  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    _darkMode = _preferences.darkMode;
    _pushNotif = _preferences.pushNotif;
    _emailNotif = _preferences.emailNotif;
    _soundEnabled = _preferences.soundEnabled;
    _privateProfile = _preferences.privateProfile;
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    await _preferences.setDarkMode(value);
  }

  Future<void> setPushNotif(bool value) async {
    _pushNotif = value;
    notifyListeners();
    await _preferences.setPushNotif(value);
  }

  Future<void> setEmailNotif(bool value) async {
    _emailNotif = value;
    notifyListeners();
    await _preferences.setEmailNotif(value);
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    await _preferences.setSoundEnabled(value);
  }

  Future<void> setPrivateProfile(bool value) async {
    _privateProfile = value;
    notifyListeners();
    await _preferences.setPrivateProfile(value);
  }
}

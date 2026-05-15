import 'package:flutter/material.dart';

import '../services/app_preferences.dart';
import 'strings_en.dart';
import 'strings_vi.dart';

class AppStrings {
  AppStrings(this.languageCode);

  final String languageCode;

  static AppStrings of(BuildContext context) {
    return AppStrings(Localizations.localeOf(context).languageCode);
  }

  static AppStrings current() {
    try {
      return AppStrings(AppPreferences.instance.languageCode);
    } catch (_) {
      return AppStrings('en');
    }
  }

  bool get isVietnamese => languageCode == 'vi';

  String t(String key) {
    final values = isVietnamese ? _vi : _en;
    return values[key] ?? _en[key] ?? key;
  }

  String nav(String id) => t('nav.$id');
  String group(String id) => t('group.$id');
  String feed(String id) => t('feed.$id');

  static const Map<String, String> _en = stringsEn;

  static const Map<String, String> _vi = stringsVi;
}

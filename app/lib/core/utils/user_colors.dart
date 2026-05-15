import 'package:flutter/material.dart';

class UserColors {
  UserColors._();

  static const _palette = [
    Color(0xFF5B53F6), // purple
    Color(0xFF2563EB), // blue
    Color(0xFF10B981), // green
    Color(0xFFF59E0B), // orange
    Color(0xFFEC4899), // pink
    Color(0xFF14B8A6), // teal
    Color(0xFF6366F1), // indigo
    Color(0xFFF43F5E), // rose
  ];

  static Color colorForUserId(String userId) {
    final hash = userId.codeUnits.fold(0, (prev, c) => prev + c);
    return _palette[hash.abs() % _palette.length];
  }

  static String hexFromColor(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/core/utils/user_colors.dart';

void main() {
  group('UserColors.colorForUserId', () {
    test('same userId always returns same color (deterministic)', () {
      const userId = 'user-abc-123';
      final color1 = UserColors.colorForUserId(userId);
      final color2 = UserColors.colorForUserId(userId);
      expect(color1, equals(color2));
    });

    test('different userIds can return different colors', () {
      final colors = <Color>{};
      final ids = [
        'user-001',
        'user-002',
        'user-003',
        'user-004',
        'user-005',
        'user-006',
        'user-007',
        'user-008',
      ];
      for (final id in ids) {
        colors.add(UserColors.colorForUserId(id));
      }
      // With 8 distinct IDs and 8 palette entries, expect at least 2 distinct colors
      expect(colors.length, greaterThan(1));
    });

    test('returns a color from the palette (not arbitrary)', () {
      const palette = [
        Color(0xFF5B53F6),
        Color(0xFF2563EB),
        Color(0xFF10B981),
        Color(0xFFF59E0B),
        Color(0xFFEC4899),
        Color(0xFF14B8A6),
        Color(0xFF6366F1),
        Color(0xFFF43F5E),
      ];
      final color = UserColors.colorForUserId('some-user-id');
      expect(palette.contains(color), isTrue);
    });

    test('empty userId does not throw', () {
      expect(() => UserColors.colorForUserId(''), returnsNormally);
    });
  });

  group('UserColors.hexFromColor', () {
    test('converts Color to uppercase hex string with # prefix', () {
      const color = Color(0xFF5B53F6);
      expect(UserColors.hexFromColor(color), equals('#5B53F6'));
    });

    test('converts blue color correctly', () {
      const color = Color(0xFF2563EB);
      expect(UserColors.hexFromColor(color), equals('#2563EB'));
    });

    test('roundtrip: colorForUserId → hexFromColor produces valid hex', () {
      final color = UserColors.colorForUserId('test-user');
      final hex = UserColors.hexFromColor(color);
      expect(hex, startsWith('#'));
      expect(hex.length, equals(7));
    });
  });
}

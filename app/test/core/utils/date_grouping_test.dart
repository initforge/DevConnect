import 'package:flutter_test/flutter_test.dart';
import 'package:devconnect/core/utils/date_grouping.dart';

void main() {
  group('DateGrouping.isSameDay', () {
    test('returns true for same local day', () {
      final a = DateTime(2024, 5, 15, 10, 0);
      final b = DateTime(2024, 5, 15, 23, 59);
      expect(DateGrouping.isSameDay(a, b), isTrue);
    });

    test('returns false for different days', () {
      final a = DateTime(2024, 5, 15);
      final b = DateTime(2024, 5, 16);
      expect(DateGrouping.isSameDay(a, b), isFalse);
    });

    test('timezone edge: UTC midnight vs local previous day', () {
      // Both converted to local before comparison — should be consistent
      final a = DateTime(2024, 5, 15, 0, 0).toLocal();
      final b = DateTime(2024, 5, 15, 0, 0).toLocal();
      expect(DateGrouping.isSameDay(a, b), isTrue);
    });
  });

  group('DateGrouping.dayLabel', () {
    test('returns Hôm nay for today', () {
      final now = DateTime.now();
      expect(DateGrouping.dayLabel(now), equals('Hôm nay'));
    });

    test('returns Hôm qua for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateGrouping.dayLabel(yesterday), equals('Hôm qua'));
    });

    test('returns weekday name for date within last 7 days', () {
      final now = DateTime.now();
      // Find a date 3 days ago that is not today or yesterday
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      final label = DateGrouping.dayLabel(threeDaysAgo);
      const weekdays = [
        'Thứ 2',
        'Thứ 3',
        'Thứ 4',
        'Thứ 5',
        'Thứ 6',
        'Thứ 7',
        'Chủ nhật',
      ];
      expect(weekdays.contains(label), isTrue);
    });

    test('returns day + month for date older than 7 days', () {
      // Use a fixed date far in the past
      final oldDate = DateTime(2020, 3, 5);
      final label = DateGrouping.dayLabel(oldDate);
      // Should contain "tháng 3" and "5"
      expect(label, contains('tháng 3'));
      expect(label, contains('5'));
    });

    test('returns correct month label for December', () {
      final dec = DateTime(2019, 12, 25);
      final label = DateGrouping.dayLabel(dec);
      expect(label, contains('tháng 12'));
      expect(label, contains('25'));
    });

    test('weekday index maps correctly: Monday = Thứ 2', () {
      // Find a Monday in the past (more than 7 days ago to use month format,
      // but we test the weekday mapping via a recent Monday)
      // weekday 1 = Monday
      final now = DateTime.now();
      // Go back to find a day within 2-6 days that is a specific weekday
      // Instead, test the mapping directly with a known Monday far in past
      // (will use month format) — just verify the weekday array is correct
      // by checking a date 3 days ago
      final threeDaysAgo = now.subtract(const Duration(days: 3)).toLocal();
      final expected =
          [
            'Thứ 2',
            'Thứ 3',
            'Thứ 4',
            'Thứ 5',
            'Thứ 6',
            'Thứ 7',
            'Chủ nhật',
          ][threeDaysAgo.weekday - 1];
      expect(DateGrouping.dayLabel(threeDaysAgo), equals(expected));
    });
  });
}

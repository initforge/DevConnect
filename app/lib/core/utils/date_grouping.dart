class DateGrouping {
  DateGrouping._();

  static bool isSameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  static String dayLabel(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    if (isSameDay(local, now)) return 'Hôm nay';
    final yesterday = now.subtract(const Duration(days: 1));
    if (isSameDay(local, yesterday)) return 'Hôm qua';
    final diff = now.difference(local).inDays;
    if (diff < 7) {
      const days = [
        'Thứ 2',
        'Thứ 3',
        'Thứ 4',
        'Thứ 5',
        'Thứ 6',
        'Thứ 7',
        'Chủ nhật',
      ];
      return days[local.weekday - 1];
    }
    const months = [
      'tháng 1',
      'tháng 2',
      'tháng 3',
      'tháng 4',
      'tháng 5',
      'tháng 6',
      'tháng 7',
      'tháng 8',
      'tháng 9',
      'tháng 10',
      'tháng 11',
      'tháng 12',
    ];
    return '${local.day} ${months[local.month - 1]}';
  }
}

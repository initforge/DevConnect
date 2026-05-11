part of 'analytics_screen.dart';

const _AnalyticsViewData _showcaseViewData = _AnalyticsViewData(
  metrics: [
    _AnalyticsMetric(label: 'VIEWS', value: '1,250', delta: '+12%'),
    _AnalyticsMetric(label: 'LIKES', value: '340', delta: '+8%'),
    _AnalyticsMetric(label: 'COMMENTS', value: '89', delta: '+5%'),
    _AnalyticsMetric(label: 'FOLLOWERS', value: '+15', delta: '+3%'),
  ],
  chartValue: '8.4K',
  topItems: [
    _AnalyticsRankedItem(
      title: 'Building Scalable Microservices',
      value: '2.4k',
    ),
    _AnalyticsRankedItem(
      title: 'TypeScript Tips for Senior Devs',
      value: '1.8k',
    ),
    _AnalyticsRankedItem(
      title: 'Why I Switched to Neovim in 2026',
      value: '1.2k',
    ),
  ],
  audience: [
    _AnalyticsAudienceItem(label: 'React', percent: 0.32),
    _AnalyticsAudienceItem(label: 'Python', percent: 0.28),
    _AnalyticsAudienceItem(label: 'TypeScript', percent: 0.24),
  ],
);

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TinyMetric extends StatelessWidget {
  const _TinyMetric({
    required this.label,
    required this.value,
    required this.delta,
  });

  final String label;
  final String value;
  final String delta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            delta,
            style: const TextStyle(fontSize: 11, color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

class _RankedAnalyticsRow extends StatelessWidget {
  const _RankedAnalyticsRow({
    required this.rank,
    required this.title,
    required this.value,
  });

  final String rank;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Row(
        children: [
          Text(
            rank,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderBar extends StatelessWidget {
  const _ReaderBar({required this.label, required this.percent});

  final String label;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: percent.clamp(0, 1),
                backgroundColor: const Color(0xFFE5E7F0),
                color: const Color(0xFF5B53F6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(percent * 100).toInt()}%',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final points = <double>[0.42, 0.58, 0.5, 0.72, 0.6, 0.84, 0.76];
    final linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 3
          ..color = const Color(0xFF5B53F6);
    final fillPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x335B53F6), Color(0x005B53F6)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final guidePaint =
        Paint()
          ..color = const Color(0xFFE8EAF2)
          ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = size.height / 4 * i + 10;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width / (points.length - 1) * i;
      final y = size.height - (size.height - 22) * points[i];
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF5B53F6);
    for (var i = 0; i < points.length; i++) {
      final x = size.width / (points.length - 1) * i;
      final y = size.height - (size.height - 22) * points[i];
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

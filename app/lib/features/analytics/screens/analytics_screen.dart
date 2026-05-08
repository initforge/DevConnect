import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê'), actions: [
        SegmentedButton<String>(segments: const [
          ButtonSegment(value: '7d', label: Text('7 ngày')),
          ButtonSegment(value: '30d', label: Text('30 ngày')),
        ], selected: const {'7d'}, onSelectionChanged: (_) {},
          style: ButtonStyle(textStyle: WidgetStatePropertyAll(const TextStyle(fontSize: 12)))),
        const SizedBox(width: 8),
      ]),
      body: FutureBuilder<dynamic>(
        future: ApiService.instance.getAny('/api/analytics'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text('Không thể tải dữ liệu analytics', style: TextStyle(color: AppColors.textSecondary)),
              ]),
            );
          }
          final data = snapshot.data as Map<String, dynamic>;
          return SingleChildScrollView(padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildSummaryCards(data),
              const SizedBox(height: 24),
              _buildChart(),
              const SizedBox(height: 24),
              _buildTopPosts(data),
              const SizedBox(height: 24),
              _buildReaderStats(data),
            ]));
        },
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> data) {
    return Column(children: [
      Row(children: [
        Expanded(child: _StatCard(icon: Icons.people, label: 'Người dùng', value: _formatNumber(data['totalUsers'] ?? 0), change: '', positive: true)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.article, label: 'Bài viết', value: _formatNumber(data['totalPosts'] ?? 0), change: '', positive: true)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _StatCard(icon: Icons.folder, label: 'Dự án', value: _formatNumber(data['totalProjects'] ?? 0), change: '', positive: true)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.work, label: 'Việc làm', value: _formatNumber(data['totalJobs'] ?? 0), change: '', positive: true)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _StatCard(icon: Icons.trending_up, label: 'Active 7 ngày', value: _formatNumber(data['activeUsersThisWeek'] ?? 0), change: '', positive: true)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.visibility, label: 'Lượt xem', value: _formatNumber(data['totalViews'] ?? 0), change: '', positive: true)),
      ]),
    ]);
  }

  String _formatNumber(dynamic num) {
    if (num is int) return num.toString();
    if (num is double) return num.toInt().toString();
    return '0';
  }

  Widget _buildChart() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Lượt xem theo ngày', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: CustomPaint(painter: _ChartPainter(), child: const SizedBox.expand())),
    ]);
  }

  Widget _buildTopPosts(Map<String, dynamic> data) {
    final posts = (data['topPosts'] as List? ?? []);
    if (posts.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Bài viết nổi bật', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      ...posts.take(3).map((p) => Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Expanded(child: Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${p['views']} views', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            Text('${p['likes']} ❤️', style: const TextStyle(fontSize: 11, color: AppColors.error)),
          ]),
        ]),
      )),
    ]);
  }

  Widget _buildReaderStats(Map<String, dynamic> data) {
    final stats = data['readerStats'] as List? ?? [];
    if (stats.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Độc giả của bạn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      ...stats.map((s) => _readerStat(s['label']?.toString() ?? '', (s['pct'] as double?) ?? 0.0)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon; final String label; final String value; final String change; final bool positive;
  const _StatCard({required this.icon, required this.label, required this.value, required this.change, required this.positive});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 18, color: AppColors.primary), const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(
            color: (positive ? AppColors.success : AppColors.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(change, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: positive ? AppColors.success : AppColors.error)))]),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
      ]));
  }
}

Widget _readerStat(String label, double pct) {
  return Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: pct, backgroundColor: AppColors.surfaceAlt, color: AppColors.primary, minHeight: 8))),
      const SizedBox(width: 8),
      Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ]));
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = AppColors.primary;
    final fillPaint = Paint()..style = PaintingStyle.fill
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final points = [0.6, 0.4, 0.7, 0.5, 0.8, 0.65, 0.9];
    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = size.width / (points.length - 1) * i;
      final y = size.height * (1 - points[i]) + 16;
      if (i == 0) { path.moveTo(x, y); fillPath.moveTo(x, size.height); fillPath.lineTo(x, y); }
      else { path.lineTo(x, y); fillPath.lineTo(x, y); }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    final dotPaint = Paint()..color = AppColors.primary..style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i++) {
      final x = size.width / (points.length - 1) * i;
      final y = size.height * (1 - points[i]) + 16;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = Colors.white..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

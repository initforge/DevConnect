import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScreenshotLabScreen extends StatelessWidget {
  const ScreenshotLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_ShotRoute>[
      const _ShotRoute('Trang chủ feed', '/home'),
      const _ShotRoute('Khám phá', '/explore'),
      const _ShotRoute('Thông báo', '/notifications'),
      const _ShotRoute('Hồ sơ', '/profile'),
      const _ShotRoute('Tạo bài viết', '/create-post'),
      const _ShotRoute('Chi tiết bài viết', '/post/p1'),
      const _ShotRoute('Danh sách chat', '/chat'),
      const _ShotRoute('Chat chi tiết', '/chat/conv1'),
      const _ShotRoute('Sàn dự án', '/projects'),
      const _ShotRoute('Bảng việc làm', '/jobs'),
      const _ShotRoute('Bảng xếp hạng', '/leaderboard'),
      const _ShotRoute('Analytics', '/analytics'),
      const _ShotRoute('Playground', '/playground'),
      const _ShotRoute('Live Code', '/live-code'),

      const _ShotRoute('Cài đặt', '/settings'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Screenshot Lab'), centerTitle: true),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () => context.push(item.route),
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShotRoute {
  final String label;
  final String route;

  const _ShotRoute(this.label, this.route);
}

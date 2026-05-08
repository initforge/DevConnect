import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/user_repository.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _repository = UserRepository();
  late Future<List<dynamic>> _loader;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  void _loadFeeds() {
    _loader = _repository.getTopUsers(limit: 20);
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    _loadFeeds();
    if (!mounted) return;
    setState(() {});
    await _loader;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bảng xếp hạng')),
      body: FutureBuilder<List<dynamic>>(
        future: _loader,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const ErrorState(
                    message: 'Đã xảy ra lỗi khi tải bảng xếp hạng.\nVui lòng thử lại.',
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data ?? const [];

          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.leaderboard_outlined,
              title: 'Chưa có dữ liệu',
              subtitle: 'Bảng xếp hạng đang trống.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (_, index) {
                final user = users[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '#${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      UserAvatar(name: user.displayName, size: 40, isOnline: user.isOnline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('@${user.username}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                      Text(
                        '${user.reputation} XP',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

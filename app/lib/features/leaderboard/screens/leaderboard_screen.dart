import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/routes.dart';
import '../../../core/models/models.dart';
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
  late Future<List<User>> _loader;

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
      backgroundColor: const Color(0xFFF7F8FC),
      bottomNavigationBar: AppBottomNavBar(
        items: [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            route: AppRoutes.home,
          ),
          AppBottomNavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: 'Explore',
            route: AppRoutes.explore,
          ),
          AppBottomNavItem(
            icon: Icons.leaderboard_outlined,
            selectedIcon: Icons.leaderboard,
            label: 'Leaderboard',
            route: AppRoutes.leaderboard,
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            route: AppRoutes.profile,
          ),
        ],
        selectedIndex: 2,
        currentRoute: AppRoutes.leaderboard,
        centerCreate: true,
      ),
      appBar: AppBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<User>>(
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.28),
                  ErrorState(
                    message: 'Unable to load leaderboard.\nPull to try again.',
                    onRetry: _refresh,
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data ?? const <User>[];
          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.leaderboard_outlined,
              title: 'No ranking data',
              subtitle: 'Leaderboard will appear once activity is recorded.',
            );
          }

          final topThree = users.take(3).toList();
          final rest = users.skip(3).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
              children: [
                const _LeaderboardHero(),
                const SizedBox(height: 14),
                _Podium(topThree: topThree),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE8EAF2)),
                  ),
                  child: Column(
                    children:
                        rest
                            .asMap()
                            .entries
                            .map(
                              (entry) => _RankRow(
                                rank: entry.key + 4,
                                user: entry.value,
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LeaderboardHero extends StatelessWidget {
  const _LeaderboardHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B53F6), Color(0xFF21B5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week’s most valuable builders',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Rankings combine reputation, engagement, and consistency across the community.',
            style: TextStyle(color: Color(0xD8FFFFFF), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.topThree});

  final List<User> topThree;

  @override
  Widget build(BuildContext context) {
    final second = topThree.length > 1 ? topThree[1] : null;
    final first = topThree.isNotEmpty ? topThree[0] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumSlot(
              user: second,
              rank: 2,
              height: 132,
              color: const Color(0xFFE9EEF7),
            ),
          ),
          Expanded(
            child: _PodiumSlot(
              user: first,
              rank: 1,
              height: 170,
              color: const Color(0xFFFFE8A3),
              highlight: true,
            ),
          ),
          Expanded(
            child: _PodiumSlot(
              user: third,
              rank: 3,
              height: 116,
              color: const Color(0xFFF1DDD4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.user,
    required this.rank,
    required this.height,
    required this.color,
    this.highlight = false,
  });

  final User? user;
  final int rank;
  final double height;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (highlight)
          const Icon(Icons.workspace_premium, color: AppColors.warning),
        UserAvatar(
          name: user!.displayName,
          size: highlight ? 62 : 54,
          isOnline: user!.isOnline,
        ),
        const SizedBox(height: 10),
        Text(
          user!.displayName.split(' ').first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          '${user!.reputation} XP',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          alignment: Alignment.center,
          child: Text(
            '#$rank',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.user});

  final int rank;
  final User user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            UserAvatar(
              name: user.displayName,
              size: 40,
              isOnline: user.isOnline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${user.reputation} XP',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B53F6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

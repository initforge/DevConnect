import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/models/leaderboard.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/decorative_widgets.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/leaderboard_repository.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _repository = LeaderboardRepository();
  late Future<List<LeaderboardEntry>> _loader;
  Map<String, dynamic>? _scoringWeights;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
    _loadScoringWeights();
  }

  void _loadFeeds() {
    _loader = _repository.getLeaderboard(limit: 50);
  }

  Future<void> _loadScoringWeights() async {
    try {
      final data = await ApiService.instance.getObject('/leaderboard/scoring');
      if (mounted) setState(() => _scoringWeights = data);
    } catch (_) {}
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
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.06),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: Text(
          AppStrings.of(context).t('leaderboard.title'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<LeaderboardEntry>>(
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
                    message: AppStrings.of(context).t('leaderboard.unableLoad'),
                    onRetry: _refresh,
                  ),
                ],
              ),
            );
          }

          final entries = snapshot.data ?? const <LeaderboardEntry>[];
          if (entries.isEmpty) {
            return EmptyState(
              icon: Icons.leaderboard_outlined,
              title: AppStrings.of(context).t('leaderboard.noData'),
              subtitle: AppStrings.of(context).t('leaderboard.noDataSubtitle'),
            );
          }

          final topThree = entries.take(3).toList();
          final rest = entries.skip(3).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: DecorativeBackground(
              child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.getContentMaxWidth(context),
                ),
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
                                .map(
                                  (entry) => _RankRow(
                                    entry: entry,
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    if (_scoringWeights != null) ...[
                      const SizedBox(height: 16),
                      _ScoringBreakdown(data: _scoringWeights!),
                    ],
                  ],
                ),
              ),
            ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.of(context).t('leaderboard.heroTitle'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.of(context).t('leaderboard.heroSubtitle'),
            style: const TextStyle(color: Color(0xD8FFFFFF), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.topThree});

  final List<LeaderboardEntry> topThree;

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
              entry: second,
              rank: 2,
              height: 132,
              color: const Color(0xFFE9EEF7),
            ),
          ),
          Expanded(
            child: _PodiumSlot(
              entry: first,
              rank: 1,
              height: 170,
              color: const Color(0xFFFFE8A3),
              highlight: true,
            ),
          ),
          Expanded(
            child: _PodiumSlot(
              entry: third,
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
    required this.entry,
    required this.rank,
    required this.height,
    required this.color,
    this.highlight = false,
  });

  final LeaderboardEntry? entry;
  final int rank;
  final double height;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (highlight)
          const Icon(Icons.workspace_premium, color: AppColors.warning),
        UserAvatar(
          name: entry!.user.displayName,
          size: highlight ? 62 : 54,
          isOnline: entry!.user.isOnline,
        ),
        const SizedBox(height: 10),
        Text(
          entry!.user.displayName.split(' ').first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          '${entry!.points} XP',
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
  const _RankRow({required this.entry});

  final LeaderboardEntry entry;

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
                '#${entry.rank}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            UserAvatar(
              name: entry.user.displayName,
              size: 40,
              isOnline: entry.user.isOnline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.user.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '@${entry.user.username}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (entry.rankChange > 0)
              const Icon(Icons.arrow_upward, size: 14, color: Colors.green),
            if (entry.rankChange < 0)
              const Icon(Icons.arrow_downward, size: 14, color: Colors.red),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${entry.points} XP',
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

class _ScoringBreakdown extends StatelessWidget {
  const _ScoringBreakdown({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final formula = data['formula'] as String? ?? '';
    final weights = (data['weights'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.functions, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                AppStrings.of(context).t('leaderboard.howScores'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              formula,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5B53F6),
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EAF2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F0FF),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 44, child: Text(AppStrings.of(context).t('leaderboard.colWeight'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF5B53F6)))),
                      Expanded(child: Text(AppStrings.of(context).t('leaderboard.colMetric'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF5B53F6)))),
                      SizedBox(width: 140, child: Text(AppStrings.of(context).t('leaderboard.colDesc'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF5B53F6)))),
                    ],
                  ),
                ),
                // Table rows
                ...weights.asMap().entries.map((entry) {
                  final w = entry.value;
                  final isEven = entry.key.isEven;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : const Color(0xFFF9FAFC),
                      border: const Border(top: BorderSide(color: Color(0xFFEEF0F5), width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F0FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '×${w['weight']}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5B53F6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            w['metric'] as String? ?? '',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: Text(
                            w['description'] as String? ?? '',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

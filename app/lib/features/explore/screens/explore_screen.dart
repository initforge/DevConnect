import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/decorative_widgets.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/user_repository.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _userRepository = UserRepository();
  final _postRepository = PostRepository();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object?>>(
      future: Future.wait<Object?>([
        _userRepository.getTopUsers(limit: 6),
        _postRepository.getTrendingPosts(limit: 2),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: _ExploreSkeleton());
        }

        final users = snapshot.data?[0] as List? ?? const [];
        final posts = snapshot.data?[1] as List? ?? const [];

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            titleSpacing: 10,
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
            title: const Text(
              'Explore',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFF3F4F8),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.go(AppRoutes.notifications),
                    icon: const Icon(Icons.notifications_none, size: 16),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(62),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap:
                            () => context.push('${AppRoutes.search}?q=flutter'),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                                size: 18,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.of(
                                  context,
                                ).t('explore.searchPlaceholder'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: () => context.push(AppRoutes.search),
                        icon: const Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: DecorativeBackground(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.getContentMaxWidth(context),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final labels = [
                              '#React',
                              '#AI',
                              '#TypeScript',
                              '#Infra',
                              '#Cloud',
                            ];
                            final colors = [
                              const Color(0xFFE8EEFF),
                              const Color(0xFFF5EAFE),
                              const Color(0xFFE8FBF6),
                              const Color(0xFFFFF0E8),
                              const Color(0xFFFDE8EC),
                            ];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colors[index],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                labels[index],
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: AppStrings.of(context).t('explore.aiPicks'),
                        action: AppStrings.of(context).t('explore.seeAll'),
                        onTap:
                            () => context.push('${AppRoutes.search}?q=flutter'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 166,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: posts.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, index) {
                            final post = posts[index];
                            final cardWidth =
                                ResponsiveUtils.isDesktop(context)
                                    ? 160.0
                                    : 138.0;
                            return InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap:
                                  () => context.push(
                                    '${AppRoutes.postBase}/${post.id}',
                                  ),
                              child: Container(
                                width: cardWidth,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 84,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors:
                                              index.isEven
                                                  ? [
                                                    const Color(0xFF101726),
                                                    const Color(0xFF182D4B),
                                                  ]
                                                  : [
                                                    const Color(0xFF0E1B34),
                                                    const Color(0xFF124E7E),
                                                  ],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        index.isEven
                                            ? Icons.code
                                            : Icons.auto_awesome,
                                        color: Colors.white.withValues(
                                          alpha: 0.88,
                                        ),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      post.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        AppStrings.of(context).t('explore.topDevelopers'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 125,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: users.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, index) {
                            final user = users[index];
                            final tileWidth =
                                ResponsiveUtils.isDesktop(context)
                                    ? 92.0
                                    : 82.0;
                            return Container(
                              width: tileWidth,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Column(
                                children: [
                                  UserAvatar(
                                    name: user.displayName,
                                    size: 40,
                                    isOnline: true,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    user.displayName.split(' ').first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    height: 20,
                                    child: OutlinedButton(
                                      onPressed:
                                          () => context.push(
                                            '${AppRoutes.userBase}/${user.id}',
                                          ),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        side: const BorderSide(
                                          color: AppColors.primary,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Follow',
                                        style: TextStyle(fontSize: 9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        AppStrings.of(context).t('explore.popularTopics'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TopicsGrid(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopicsGrid extends StatelessWidget {
  const _TopicsGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = ResponsiveUtils.isDesktop(context);
        final full = constraints.maxWidth;
        final half = (full - 12) / 2;
        final third = (full - 24) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: wide ? (third * 2) + 12 : full,
              height: 132,
              child: const _TopicCard(
                title: 'Web Dev',
                subtitle: '1.2k posts today',
                icon: Icons.web,
              ),
            ),
            SizedBox(
              width: wide ? third : half,
              height: 132,
              child: const _TopicCard(
                title: 'AI & ML',
                subtitle: '244 posts today',
                icon: Icons.psychology_alt_outlined,
              ),
            ),
            SizedBox(
              width: wide ? third : half,
              height: 116,
              child: const _TopicCard(
                title: 'Mobile Apps',
                subtitle: '412 posts today',
                icon: Icons.phone_iphone,
              ),
            ),
            SizedBox(
              width: wide ? (third * 2) + 12 : full,
              height: 116,
              child: const _TopicCard(
                title: 'System Design',
                subtitle: '856 posts today',
                icon: Icons.architecture,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action, this.onTap});

  final String title;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
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

class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      children: [
        Row(
          children: List.generate(
            5,
            (_) => const Padding(
              padding: EdgeInsets.only(right: 8),
              child: ShimmerBox(width: 70, height: 34, borderRadius: 16),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const ShimmerBox(width: 120, height: 16),
        const SizedBox(height: 12),
        Row(
          children: const [
            ShimmerBox(width: 138, height: 166, borderRadius: 18),
            SizedBox(width: 12),
            ShimmerBox(width: 138, height: 166, borderRadius: 18),
          ],
        ),
        const SizedBox(height: 22),
        const ShimmerBox(width: 160, height: 16),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(right: 10),
              child: ShimmerBox(width: 82, height: 125, borderRadius: 18),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const ShimmerBox(width: 140, height: 16),
        const SizedBox(height: 12),
        const ShimmerBox(width: double.infinity, height: 132, borderRadius: 18),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: ShimmerBox(width: 100, height: 116, borderRadius: 18),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ShimmerBox(width: 100, height: 116, borderRadius: 18),
            ),
          ],
        ),
      ],
    );
  }
}

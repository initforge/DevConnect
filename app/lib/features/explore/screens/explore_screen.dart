import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final users = snapshot.data?[0] as List? ?? const [];
        final posts = snapshot.data?[1] as List? ?? const [];

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            titleSpacing: 10,
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
                            color: const Color(0xFFF4F6FA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.search,
                                size: 18,
                                color: AppColors.textTertiary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Search posts, devs, projects...',
                                style: TextStyle(
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
                        color: const Color(0xFF4F46E5),
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
          body: SingleChildScrollView(
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
                        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                  title: 'AI Picks for You',
                  action: 'See all',
                  onTap: () => context.push('${AppRoutes.search}?q=flutter'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 166,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, index) {
                      final post = posts[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap:
                            () => context.push(
                              '${AppRoutes.postBase}/${post.id}',
                            ),
                        child: Container(
                          width: 138,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE7EAF2)),
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
                                  color: Colors.white.withValues(alpha: 0.88),
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
                const Text(
                  'Top Developers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 102,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, index) {
                      final user = users[index];
                      return Container(
                        width: 82,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE7EAF2)),
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
                                    color: Color(0xFF4F46E5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
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
                const Text(
                  'Popular Topics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: const [
                    _TopicCard(
                      title: 'Web Dev',
                      subtitle: '1.2k posts today',
                      icon: Icons.web,
                    ),
                    _TopicCard(
                      title: 'System Design',
                      subtitle: '856 posts today',
                      icon: Icons.architecture,
                    ),
                    _TopicCard(
                      title: 'Mobile Apps',
                      subtitle: '412 posts today',
                      icon: Icons.phone_iphone,
                    ),
                    _TopicCard(
                      title: 'AI & ML',
                      subtitle: '244 posts today',
                      icon: Icons.psychology_alt_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
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
              color: Color(0xFF4F46E5),
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
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
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

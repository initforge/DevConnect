import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_seed_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/project_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../feed/widgets/post_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _userRepository = UserRepository();
  final _postRepository = PostRepository();
  final _projectRepository = ProjectRepository();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<dynamic>? _searchResults;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchQuery = '';
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });
    try {
      // Search all: users, posts, projects
      final results = await Future.wait([
        _userRepository.searchUsers(query),
        _postRepository.getForYouPosts(limit: 10),
        _projectRepository.getProjects(limit: 10),
      ]);
      final users = results[0] as List;
      // Filter posts by query in title/content
      final posts = (results[1] as List).where((p) =>
        p.title.toLowerCase().contains(query.toLowerCase()) ||
        p.content.toLowerCase().contains(query.toLowerCase()) ||
        (p.tags as List).any((t) => t.toLowerCase().contains(query.toLowerCase()))
      ).toList();
      // Filter projects by query
      final projects = (results[2] as List).where((p) =>
        p.title.toLowerCase().contains(query.toLowerCase()) ||
        p.description.toLowerCase().contains(query.toLowerCase()) ||
        (p.techStack as List).any((t) => t.toLowerCase().contains(query.toLowerCase()))
      ).toList();
      setState(() {
        _searchResults = [...users, ...posts, ...projects];
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object?>>(
      future: Future.wait<Object?>([
        _userRepository.getTopUsers(limit: 6),
        _postRepository.getTrendingPosts(),
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
          appBar: AppBar(
            title: const Text('Khám phá'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm bài viết, người dùng, dự án...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _performSearch,
                ),
              ),
            ),
          ),
          body: _searchQuery.isNotEmpty
              ? _buildSearchResults()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Xu hướng',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: AppSeedConstants.trendingTags.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            return TechChip(
                              label: '#${AppSeedConstants.trendingTags[index]}',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Truy cập nhanh',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/projects'),
                              child: const Text('Xem tất cả'),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: const [
                            _QuickAccessCard(
                              icon: Icons.groups_2_outlined,
                              title: 'Sàn dự án',
                              subtitle: 'Tìm đội, tham gia dự án',
                              route: '/projects',
                            ),
                            _QuickAccessCard(
                              icon: Icons.work_outline,
                              title: 'Việc làm',
                              subtitle: 'Theo dõi vị trí phù hợp',
                              route: '/jobs',
                            ),
                            _QuickAccessCard(
                              icon: Icons.emoji_events_outlined,
                              title: 'Xếp hạng',
                              subtitle: 'Uy tín và đóng góp',
                              route: '/leaderboard',
                            ),
                            _QuickAccessCard(
                              icon: Icons.analytics_outlined,
                              title: 'Analytics',
                              subtitle: 'Chỉ số và dashboard',
                              route: '/analytics',
                            ),
                            _QuickAccessCard(
                              icon: Icons.terminal_outlined,
                              title: 'Playground',
                              subtitle: 'Không gian thử nghiệm',
                              route: '/playground',
                            ),
                            _QuickAccessCard(
                              icon: Icons.handshake_outlined,
                              title: 'Mentorship',
                              subtitle: 'Kết nối mentor',
                              route: '/mentorship',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Lập trình viên nổi bật',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, index) {
                            final user = users[index];
                            return GestureDetector(
                              onTap: () => context.push('/user/${user.id}'),
                              child: Container(
                                width: 120,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    UserAvatar(
                                      name: user.displayName,
                                      size: 44,
                                      isOnline: user.isOnline,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      user.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${user.reputation} XP',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Bài viết phổ biến',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (posts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 32),
                          child: EmptySearchResults(),
                        )
                      else
                        ...posts.map<Widget>(
                          (post) => PostCard(
                            post: post,
                            onTap: () => context.push('/post/${post.id}'),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults == null || _searchResults!.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_outlined,
        title: 'Không tìm thấy kết quả',
        subtitle: 'Thử từ khóa khác',
      );
    }

    // Separate results by type
    final users = _searchResults!.where((r) => r.id.toString().startsWith('u')).toList();
    final posts = _searchResults!.where((r) => r.id.toString().startsWith('p')).toList();
    final projects = _searchResults!.where((r) => r.id.toString().startsWith('proj')).toList();

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (users.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Người dùng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        ...users.map((user) => ListTile(
          leading: UserAvatar(name: user.displayName, size: 40),
          title: Text(user.displayName),
          subtitle: Text('@${user.username} · ${user.reputation} XP'),
          onTap: () => context.push('/user/${user.id}'),
        )),
        const SizedBox(height: 16),
      ],
      if (posts.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Bài viết', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        ...posts.map((post) => PostCard(
          post: post,
          onTap: () => context.push('/post/${post.id}'),
        )),
        const SizedBox(height: 16),
      ],
      if (projects.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Dự án', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        ...projects.map((project) => ListTile(
          leading: UserAvatar(name: project.owner.displayName, size: 40),
          title: Text(project.title),
          subtitle: Text(project.owner.displayName),
          onTap: () => context.push('/projects'),
        )),
      ],
    ]);
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 44) / 2;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push(route),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

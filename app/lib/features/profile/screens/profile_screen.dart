import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../feed/widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userRepository = UserRepository();
  final _postRepository = PostRepository();
  final _chatRepository = ChatRepository();
  bool _isFollowing = false;
  bool _isFollowingLoading = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileData>(
      future: _loadProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snapshot.data;
        if (profile == null || profile.user == null) {
          return const Scaffold(
            body: EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Không tìm thấy người dùng',
            ),
          );
        }

        final user = profile.user!;

        return Scaffold(
          body: DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder:
                  (context, _) => [
                    SliverAppBar(
                      expandedHeight: 340,
                      pinned: true,
                      title: Text(user.displayName),
                      actions: [
                        if (profile.isMe)
                          IconButton(
                            onPressed: () => context.push('/settings'),
                            icon: const Icon(Icons.settings_outlined),
                            tooltip: 'Cài đặt',
                          ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildHeader(context, user, profile.isMe),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarDelegate(
                        const TabBar(
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textTertiary,
                          indicatorColor: AppColors.primary,
                          indicatorSize: TabBarIndicatorSize.label,
                          tabs: [
                            Tab(text: 'Bài viết'),
                            Tab(text: 'Repos'),
                            Tab(text: 'Giới thiệu'),
                          ],
                        ),
                      ),
                    ),
                  ],
              body: TabBarView(
                children: [
                  ListView(
                    padding: EdgeInsets.zero,
                    children:
                        profile.posts
                            .map<Widget>(
                              (post) => PostCard(
                                post: post,
                                onTap: () => context.push('/post/${post.id}'),
                              ),
                            )
                            .toList(),
                  ),
                  _buildRepos(),
                  _buildAbout(user),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<_ProfileData> _loadProfile() async {
    final currentUser = await _userRepository.getCurrentUser();
    final user =
        widget.userId == null
            ? currentUser
            : await _userRepository.getUserById(widget.userId!);
    final posts =
        user == null
            ? <Post>[]
            : await _postRepository.getPostsByAuthor(user.id);

    if (user != null && !mounted) {
      setState(() => _isFollowing = user.isFollowedByMe);
    }

    return _ProfileData(
      user: user,
      posts: posts,
      isMe: currentUser != null && user != null && currentUser.id == user.id,
    );
  }

  Future<void> _handleFollow(User user) async {
    if (_isFollowingLoading) return;
    HapticFeedback.lightImpact();
    final prevState = _isFollowing;
    setState(() {
      _isFollowingLoading = true;
      _isFollowing = !_isFollowing;
    });
    try {
      await _userRepository.toggleFollow(user.id);
    } catch (e) {
      if (mounted) {
        setState(() => _isFollowing = prevState);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật trạng thái theo dõi')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFollowingLoading = false);
    }
  }

  Future<void> _handleMessage(User user) async {
    HapticFeedback.lightImpact();
    try {
      final conversations = await _chatRepository.getConversations();
      final existing = conversations.where((c) => c.otherUser.id == user.id).toList();
      if (existing.isNotEmpty) {
        if (mounted) context.push('/chat/${existing.first.id}');
      } else {
        final convId = 'conv_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
        if (mounted) context.push('/chat/$convId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở cuộc trò chuyện')),
        );
      }
    }
  }

  Widget _buildHeader(BuildContext context, User user, bool isMe) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
          child: Column(
            children: [
              UserAvatar(
                name: user.displayName,
                size: 72,
                isOnline: user.isOnline,
              ),
              const SizedBox(height: 12),
              Text(
                user.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '@${user.username}',
                style: const TextStyle(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
              if (user.bio != null) ...[
                const SizedBox(height: 8),
                Text(
                  user.bio!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 32,
                runSpacing: 12,
                children: [
                  _Stat('Bài viết', user.postCount),
                  _Stat('Theo dõi', user.followerCount),
                  _Stat('Đang theo dõi', user.followingCount),
                ],
              ),
              const SizedBox(height: 12),
              if (!isMe)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: _isFollowingLoading
                          ? null
                          : () => _handleFollow(user),
                      child: _isFollowingLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isFollowing ? 'Đã theo dõi' : 'Theo dõi'),
                    ),
                    OutlinedButton(
                      onPressed: () => _handleMessage(user),
                      child: const Text('Nhắn tin'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepos() {
    return FutureBuilder<dynamic>(
      future: _loadRepos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final repos = snapshot.data as List? ?? [];
        if (repos.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.folder_outlined, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text('Chưa có repository nào', style: TextStyle(color: AppColors.textSecondary)),
            ]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: repos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final repo = repos[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          repo['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  if (repo['description'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      repo['description'],
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> _loadRepos() async {
    final user = widget.userId == null
        ? await _userRepository.getCurrentUser()
        : await _userRepository.getUserById(widget.userId!);
    if (user == null) return [];
    try {
      final data = await ApiService.instance.getAny('/api/users/${user.id}/repos');
      return data is List ? data : [];
    } catch (_) {
      return [];
    }
  }

  Widget _buildAbout(User user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Kỹ năng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              user.skills
                  .map<Widget>((skill) => TechChip(label: skill))
                  .toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Thống kê',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _InfoRow(
          Icons.emoji_events,
          '${user.reputation} XP',
          'Điểm danh tiếng',
        ),
        _InfoRow(
          Icons.calendar_today,
          'Tham gia ${user.createdAt.year}',
          'Ngày tham gia',
        ),
        if (user.isMentor)
          _InfoRow(Icons.school, 'Mentor', 'Sẵn sàng hướng dẫn'),
      ],
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.user,
    required this.posts,
    required this.isMe,
  });

  final User? user;
  final List<Post> posts;
  final bool isMe;
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

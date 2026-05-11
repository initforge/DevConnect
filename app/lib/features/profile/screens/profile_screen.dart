import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../feed/widgets/post_card.dart';

part 'profile_widgets.dart';

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

        final data = snapshot.data;
        if (data == null || data.user == null) {
          return const Scaffold(
            body: EmptyState(
              icon: Icons.person_off_outlined,
              title: 'User not found',
            ),
          );
        }

        final user = data.user!;
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: const Color(0xFFFCFCFF),
            body: NestedScrollView(
              headerSliverBuilder:
                  (context, _) => [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 520,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.white,
                      leading: IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0x33FFFFFF),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      actions: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed:
                                data.isMe
                                    ? () => context.push(AppRoutes.settings)
                                    : () {},
                            icon: const Icon(
                              Icons.more_horiz,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildHero(context, user, data.isMe),
                      ),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(44),
                        child: Container(
                          color: Colors.white,
                          child: const TabBar(
                            labelColor: Color(0xFF4F46E5),
                            unselectedLabelColor: AppColors.textTertiary,
                            indicatorColor: Color(0xFF4F46E5),
                            indicatorSize: TabBarIndicatorSize.label,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            tabs: [
                              Tab(text: 'Posts'),
                              Tab(text: 'Projects'),
                              Tab(text: 'About'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
              body: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 100),
                    children:
                        data.posts
                            .map<Widget>(
                              (post) => PostCard(
                                post: post,
                                onTap: () => context.push('${AppRoutes.postBase}/${post.id}'),
                              ),
                            )
                            .toList(),
                  ),
                  _buildProjectsMock(user),
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

    if (user != null) {
      _isFollowing = user.isFollowedByMe;
    }

    return _ProfileData(
      user: user,
      posts: posts,
      isMe:
          user != null &&
          ((currentUser != null && currentUser.id == user.id) ||
              (currentUser == null && widget.userId == user.id)),
    );
  }

  Future<void> _handleFollow(User user) async {
    if (_isFollowingLoading) return;
    HapticFeedback.lightImpact();
    final prev = _isFollowing;
    setState(() {
      _isFollowingLoading = true;
      _isFollowing = !_isFollowing;
    });

    try {
      await _userRepository.toggleFollow(user.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFollowing = prev);
    } finally {
      if (mounted) setState(() => _isFollowingLoading = false);
    }
  }

  Future<void> _handleMessage(User user) async {
    final conversations = await _chatRepository.getConversations();
    final existing =
        conversations.where((c) => c.otherUser.id == user.id).toList();
    if (!mounted) return;
    if (existing.isNotEmpty) {
      context.push('${AppRoutes.chatBase}/${existing.first.id}');
      return;
    }
    context.push(
      '${AppRoutes.chatBase}/conv_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Widget _buildHero(BuildContext context, User user, bool isMe) {
    return Column(
      children: [
        Container(
          height: 180,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7A74FF), Color(0xFFE46EA7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.white,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 24,
                  top: -34,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: UserAvatar(
                      name: user.displayName,
                      size: 68,
                      isOnline: user.isOnline,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.bio ??
                            'Senior Engineer at Vercel. Building the web, TypeScript & modern systems.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatBlock(
                            value: '${user.followerCount}',
                            label: 'FOLLOWERS',
                          ),
                          _StatBlock(
                            value: '${user.followingCount}',
                            label: 'FOLLOWING',
                          ),
                          _StatBlock(
                            value: '${user.postCount}',
                            label: 'POSTS',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (!isMe)
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            onPressed:
                                _isFollowingLoading
                                    ? null
                                    : () => _handleFollow(user),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(21),
                              ),
                            ),
                            child:
                                _isFollowingLoading
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(
                                      _isFollowing ? 'Following' : 'Follow',
                                    ),
                          ),
                        ),
                      if (!isMe) const SizedBox(height: 12),
                      if (!isMe)
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () => _handleMessage(user),
                            child: const Text(
                              'Message',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE8EAF2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.code, size: 16),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'GitHub Connected',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Synced 3h ago',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: List.generate(28, (index) {
                                final active = index % 4 != 0;
                                return Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color:
                                        active
                                            ? const Color(
                                              0xFF6D63FF,
                                            ).withValues(
                                              alpha: 0.35 + (index % 3) * 0.2,
                                            )
                                            : const Color(0xFFF0F2F7),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectsMock(User user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EAF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Featured Project',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                '${user.displayName.split(' ').first} DevConnect Studio',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Productized community tooling, knowledge sharing and collaboration for developers.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    user.skills.take(4).map((e) => TechChip(label: e)).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<List<dynamic>> _loadRepos() async {
    final user =
        widget.userId == null
            ? await _userRepository.getCurrentUser()
            : await _userRepository.getUserById(widget.userId!);
    if (user == null) return [];
    try {
      final data = await ApiService.instance.getAny(
        '/api/users/${user.id}/repos',
      );
      return data is List ? data : [];
    } catch (_) {
      return [];
    }
  }

  Widget _buildAbout(User user) {
    return FutureBuilder<List<dynamic>>(
      future: _loadRepos(),
      builder: (context, snapshot) {
        final repos = snapshot.data ?? const [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Skills',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  user.skills.map((skill) => TechChip(label: skill)).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Repos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...repos
                .take(3)
                .map(
                  (repo) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8EAF2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repo['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        if (repo['description'] != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            repo['description'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            _AboutInfo(
              icon: Icons.emoji_events_outlined,
              title: '${user.reputation} XP',
              subtitle: 'Reputation',
            ),
            _AboutInfo(
              icon: Icons.calendar_today_outlined,
              title: 'Joined ${user.createdAt.year}',
              subtitle: 'Member since',
            ),
            if (user.isMentor)
              const _AboutInfo(
                icon: Icons.school_outlined,
                title: 'Mentor',
                subtitle: 'Available for guidance',
              ),
          ],
        );
      },
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

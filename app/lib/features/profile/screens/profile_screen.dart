import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/state/profile_refresh_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/project_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../feed/widgets/post_card.dart';
import 'profile_widgets.dart';

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
  final _projectRepository = ProjectRepository();

  bool _isFollowing = false;
  bool _isFollowingLoading = false;
  bool _isSyncingGithub = false;
  late Future<_ProfileData> _loader;

  @override
  void initState() {
    super.initState();
    _loader = _loadProfile();
    ProfileRefreshBus.instance.addListener(_refreshProfile);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loader = _loadProfile();
    }
  }

  @override
  void dispose() {
    ProfileRefreshBus.instance.removeListener(_refreshProfile);
    super.dispose();
  }

  void _refreshProfile() {
    if (!mounted) return;
    setState(() => _loader = _loadProfile());
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _loader = _loadProfile());
    await _loader;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileData>(
      future: _loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: _ProfileSkeleton());
        }

        final data = snapshot.data;
        final strings = AppStrings.of(context);
        if (data == null || data.user == null) {
          return Scaffold(
            body: EmptyState(
              icon: Icons.person_off_outlined,
              title: strings.t('profile.userNotFound'),
            ),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: NestedScrollView(
              headerSliverBuilder:
                  (context, _) => [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 520,
                      backgroundColor: Theme.of(context).colorScheme.surface,
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
                        background: _buildHero(context, data),
                      ),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(44),
                        child: Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: TabBar(
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textTertiary,
                            indicatorColor: AppColors.primary,
                            indicatorSize: TabBarIndicatorSize.label,
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            tabs: [
                              Tab(text: strings.t('profile.posts')),
                              Tab(text: strings.t('profile.projects')),
                              Tab(text: strings.t('profile.about')),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
              body: RefreshIndicator(
                onRefresh: _refresh,
                child: ResponsiveBuilder(
                  mobile: (_) => TabBarView(children: _buildProfileTabs(data)),
                  tablet: (_) => TabBarView(children: _buildProfileTabs(data)),
                  desktop: (_) => TabBarView(children: _buildProfileTabs(data)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildProfileTabs(_ProfileData data) {
    final user = data.user!;
    if (!data.isMe && data.isPrivateProfile) {
      return [
        _buildPrivateProfileState(),
        _buildPrivateProfileState(),
        _buildPrivateProfileState(),
      ];
    }

    return [
      _buildCenteredPostsList(context, data.posts, isMe: data.isMe),
      _buildCenteredProjects(context, user, isMe: data.isMe),
      _buildCenteredAbout(
        context,
        user,
        isMe: data.isMe,
        githubConnected: data.githubConnected,
      ),
    ];
  }

  Widget _buildPrivateProfileState() {
    final strings = AppStrings.of(context);
    return Center(
      child: EmptyState(
        icon: Icons.lock_outline,
        title: strings.t('profile.privateLockedTitle'),
        subtitle: strings.t('profile.privateLockedBody'),
      ),
    );
  }

  Widget _buildCenteredPostsList(
    BuildContext context,
    List<Post> posts, {
    bool isMe = false,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 100),
          children:
              posts
                  .map<Widget>(
                    (post) => Stack(
                      children: [
                        PostCard(
                          post: post,
                          onTap:
                              () => context.push(
                                '${AppRoutes.postBase}/${post.id}',
                              ),
                        ),
                        if (isMe)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditPostDialog(post);
                                } else if (value == 'delete') {
                                  _confirmDeletePost(post);
                                }
                              },
                              itemBuilder:
                                  (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppStrings.of(
                                              context,
                                            ).t('common.edit'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.delete_outline,
                                            size: 16,
                                            color: AppColors.error,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppStrings.of(
                                              context,
                                            ).t('common.delete'),
                                            style: const TextStyle(
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                            ),
                          ),
                      ],
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Future<void> _showEditPostDialog(Post post) async {
    final titleCtrl = TextEditingController(text: post.title);
    final contentCtrl = TextEditingController(text: post.content);
    final saved = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(AppStrings.of(context).t('common.edit')),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(AppStrings.of(context).t('common.cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(AppStrings.of(context).t('common.save')),
              ),
            ],
          ),
    );
    if (saved != true) return;
    try {
      await _postRepository.updatePost(
        postId: post.id,
        title: titleCtrl.text.trim(),
        content: contentCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _loader = _loadProfile());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post updated')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).t('common.error'))),
      );
    }
  }

  Future<void> _confirmDeletePost(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(AppStrings.of(context).t('common.delete')),
            content: Text(AppStrings.of(context).t('feed.deletePostConfirm')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(AppStrings.of(context).t('common.cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  AppStrings.of(context).t('common.delete'),
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await _postRepository.deletePost(post.id);
      if (!mounted) return;
      setState(() => _loader = _loadProfile());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).t('feed.postDeleted'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).t('common.error'))),
      );
    }
  }

  Widget _buildCenteredProjects(
    BuildContext context,
    User user, {
    bool isMe = false,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: _buildProjectsSection(user, isMe: isMe),
      ),
    );
  }

  Widget _buildCenteredAbout(
    BuildContext context,
    User user, {
    bool isMe = false,
    bool githubConnected = false,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: _buildAbout(user, isMe: isMe, githubConnected: githubConnected),
      ),
    );
  }

  Future<_ProfileData> _loadProfile() async {
    final currentUser = await _userRepository.getCurrentUser();
    var user =
        widget.userId == null
            ? currentUser
            : await _userRepository.getUserById(widget.userId!);

    if (user != null) {
      _isFollowing = user.isFollowedByMe;
    }

    bool isPrivateProfile = false;
    bool githubConnected = false;
    final isMe =
        user != null &&
        ((currentUser != null && currentUser.id == user.id) ||
            (currentUser == null && widget.userId == user.id));
    if (user != null) {
      try {
        final settings = await ApiService.instance.getObject(
          isMe ? '/users/me/settings' : '/users/${user.id}/public-settings',
        );
        isPrivateProfile = settings['privateProfile'] == true;
        githubConnected = settings['githubConnected'] == true;
        final onlineStatus = settings['onlineStatus'];
        if (onlineStatus is bool) {
          user = user.copyWith(isOnline: onlineStatus);
        }
      } catch (_) {}
    }

    final posts =
        user == null || (!isMe && isPrivateProfile)
            ? <Post>[]
            : await _postRepository.getPostsByAuthor(user.id);

    List<dynamic> contributions = [];
    if (user != null && githubConnected && !(!isMe && isPrivateProfile)) {
      try {
        final res = await ApiService.instance.getAny(
          '/users/${user.id}/github-contributions',
        );
        if (res is List) contributions = res;
      } catch (_) {}
    }

    return _ProfileData(
      user: user,
      posts: posts,
      isMe: isMe,
      isPrivateProfile: isPrivateProfile,
      githubConnected: githubConnected,
      contributions: contributions,
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
    try {
      final result = await ApiService.instance.post('/chat/conversations', {
        'otherUserId': user.id,
      });
      if (!mounted) return;
      final conversationId = result['id']?.toString();
      if (conversationId != null && conversationId.isNotEmpty) {
        context.push('${AppRoutes.chatBase}/$conversationId');
      }
    } catch (_) {
      // Fallback: try to find existing conversation
      final conversations = await _chatRepository.getConversations();
      final existing =
          conversations.where((c) => c.otherUser.id == user.id).toList();
      if (!mounted) return;
      if (existing.isNotEmpty) {
        context.push('${AppRoutes.chatBase}/${existing.first.id}');
      }
    }
  }

  Future<void> _syncGithub(User user) async {
    if (_isSyncingGithub) return;
    setState(() => _isSyncingGithub = true);
    try {
      await ApiService.instance.post('/users/${user.id}/github-sync', {});
      if (!mounted) return;
      setState(() => _loader = _loadProfile());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.current().t('profile.gitHubSynced'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.current().t('profile.unableSyncGithub')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSyncingGithub = false);
    }
  }

  Widget _buildHero(BuildContext context, _ProfileData data) {
    final user = data.user!;
    final isMe = data.isMe;
    final contributions = data.contributions;
    final strings = AppStrings.of(context);

    return Column(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7A74FF), Color(0xFFE46EA7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7A74FF).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                left: 30,
                bottom: -15,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                right: 50,
                top: 40,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surface,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 24,
                  top: -34,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusPill(
                            label:
                                user.isOnline
                                    ? strings.t('profile.online')
                                    : strings.t('profile.offline'),
                            color:
                                user.isOnline
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                          ),
                          if (isMe)
                            _StatusPill(
                              label:
                                  data.isPrivateProfile
                                      ? strings.t('common.privateProfile')
                                      : strings.t('common.publicProfile'),
                              color:
                                  data.isPrivateProfile
                                      ? AppColors.warning
                                      : AppColors.success,
                            ),
                        ],
                      ),
                      if (isMe) ...[const SizedBox(height: 8)],
                      Text(
                        user.bio ?? strings.t('profile.noBio'),
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
                          ProfileStatBlock(
                            value: '${user.followerCount}',
                            label: strings.t('profile.followers').toUpperCase(),
                          ),
                          ProfileStatBlock(
                            value: '${user.followingCount}',
                            label: strings.t('profile.following').toUpperCase(),
                          ),
                          ProfileStatBlock(
                            value: '${user.postCount}',
                            label: strings.t('profile.posts').toUpperCase(),
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
                              backgroundColor: AppColors.primary,
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
                                      _isFollowing
                                          ? strings.t('common.following')
                                          : strings.t('common.follow'),
                                    ),
                          ),
                        ),
                      if (!isMe) const SizedBox(height: 12),
                      if (!isMe)
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () => _handleMessage(user),
                            child: Text(
                              strings.t('common.message'),
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(14),
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
                            Row(
                              children: [
                                const Icon(Icons.code, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    data.githubConnected
                                        ? strings.t('profile.gitHubConnected')
                                        : strings.t('profile.gitHubNotLinked'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (isMe)
                                  IconButton(
                                    tooltip: strings.t('common.syncGithub'),
                                    onPressed:
                                        _isSyncingGithub ||
                                                !data.githubConnected
                                            ? null
                                            : () => _syncGithub(user),
                                    icon:
                                        _isSyncingGithub
                                            ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : const Icon(
                                              Icons.sync,
                                              size: 18,
                                              color: AppColors.primary,
                                            ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      data.githubConnected
                                          ? strings.t('common.synced')
                                          : strings.t('common.notLinked'),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (data.githubConnected &&
                                contributions.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children:
                                    contributions.map<Widget>((day) {
                                      final active = day['active'] == true;
                                      final count = day['count'] as int? ?? 0;
                                      return Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color:
                                              active
                                                  ? const Color(
                                                    0xFF6D63FF,
                                                  ).withValues(
                                                    alpha:
                                                        0.35 +
                                                        (count % 3) * 0.2,
                                                  )
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              )
                            else
                              Text(
                                data.githubConnected
                                    ? strings.t('profile.noRecentContributions')
                                    : strings.t('profile.gitHubConnectHint'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
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

  Widget _buildProjectsSection(User user, {bool isMe = false}) {
    final strings = AppStrings.of(context);
    return FutureBuilder<List<Project>>(
      future: _projectRepository.getProjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final allProjects = snapshot.data ?? [];
        // Show projects the user owns or is a member of
        final myProjects =
            allProjects.where((p) => p.owner.id == user.id).toList();

        if (myProjects.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              EmptyState(
                icon: Icons.work_outline,
                title: strings.t('profile.noProjectsTitle'),
                subtitle: strings.t('profile.noProjectsBody'),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children:
              myProjects.map((project) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              project.title,
                              style: const TextStyle(
                                fontSize: 14,
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
                              color:
                                  project.status == 'LOOKING_FOR_MEMBERS'
                                      ? const Color(0xFFF3F0FF)
                                      : const Color(0xFFEFF7FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              project.status == 'LOOKING_FOR_MEMBERS'
                                  ? 'Open'
                                  : 'Active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color:
                                    project.status == 'LOOKING_FOR_MEMBERS'
                                        ? const Color(0xFF5B53F6)
                                        : const Color(0xFF2279FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        project.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children:
                            project.techStack
                                .take(4)
                                .map((t) => TechChip(label: t))
                                .toList(),
                      ),
                      if (isMe) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              '${project.memberCount}/${project.maxMembers} members',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            if (project.owner.id == user.id)
                              TextButton.icon(
                                onPressed: () => _confirmDeleteProject(project),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 14,
                                  color: AppColors.error,
                                ),
                                label: Text(
                                  strings.t('common.delete'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.error,
                                  ),
                                ),
                              )
                            else
                              TextButton.icon(
                                onPressed: () => _leaveProject(project),
                                icon: const Icon(
                                  Icons.exit_to_app,
                                  size: 14,
                                  color: AppColors.warning,
                                ),
                                label: Text(
                                  strings.t('profile.quitProject'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Future<void> _leaveProject(Project project) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(strings.t('profile.quitProject')),
            content: Text(strings.t('profile.quitProjectConfirm')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(strings.t('common.cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  strings.t('profile.quitProject'),
                  style: const TextStyle(color: AppColors.warning),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await _projectRepository.leaveProject(project.id);
      if (!mounted) return;
      setState(() => _loader = _loadProfile());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.t('common.error'))));
    }
  }

  Future<void> _confirmDeleteProject(Project project) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(strings.t('common.delete')),
            content: Text(strings.t('profile.deleteProjectConfirm')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(strings.t('common.cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  strings.t('common.delete'),
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await _projectRepository.deleteProject(project.id);
      if (!mounted) return;
      setState(() => _loader = _loadProfile());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.t('common.error'))));
    }
  }

  Future<List<dynamic>> _loadRepos() async {
    final user =
        widget.userId == null
            ? await _userRepository.getCurrentUser()
            : await _userRepository.getUserById(widget.userId!);
    if (user == null) return [];
    try {
      final data = await ApiService.instance.getAny('/users/${user.id}/repos');
      return data is List ? data : [];
    } catch (_) {
      return [];
    }
  }

  Widget _buildAbout(
    User user, {
    bool isMe = false,
    bool githubConnected = false,
  }) {
    final strings = AppStrings.of(context);
    return FutureBuilder<List<dynamic>>(
      future: githubConnected ? _loadRepos() : Future.value(<dynamic>[]),
      builder: (context, snapshot) {
        final repos = snapshot.data ?? const [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Text(
                  strings.t('common.skills'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (isMe)
                  TextButton.icon(
                    onPressed: _showEditSkillsDialog,
                    icon: const Icon(Icons.edit, size: 14),
                    label: Text(
                      strings.t('common.edit'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            user.skills.isEmpty
                ? Text(
                  isMe
                      ? strings.t('profile.addSkillsHint')
                      : strings.t('profile.noSkills'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                )
                : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      user.skills
                          .map((skill) => TechChip(label: skill))
                          .toList(),
                ),
            if (repos.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                strings.t('common.repos'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ...repos
                  .take(3)
                  .map(
                    (repo) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            repo['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
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
            ],
            const SizedBox(height: 8),
            ProfileAboutInfo(
              icon: Icons.emoji_events_outlined,
              title: '${user.reputation} XP',
              subtitle: strings.t('common.reputation'),
            ),
            ProfileAboutInfo(
              icon: Icons.calendar_today_outlined,
              title: 'Joined ${user.createdAt.year}',
              subtitle: strings.t('common.memberSince'),
            ),
            if (user.isMentor)
              ProfileAboutInfo(
                icon: Icons.school_outlined,
                title: strings.t('common.mentor'),
                subtitle: strings.t('common.availableForGuidance'),
              ),
          ],
        );
      },
    );
  }

  void _showEditSkillsDialog() async {
    final strings = AppStrings.of(context);
    final currentUser = await _userRepository.getCurrentUser();
    if (currentUser == null) return;
    final ctrl = TextEditingController(text: currentUser.skills.join(', '));
    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(strings.t('profile.editSkills')),
            content: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'Flutter, React, TypeScript...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(strings.t('common.cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(ctrl.text),
                child: Text(strings.t('common.save')),
              ),
            ],
          ),
    );
    ctrl.dispose();
    if (result == null) return;
    final skills =
        result
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
    try {
      await ApiService.instance.patch('/users/me', {'skills': skills});
      if (!mounted) return;
      setState(() => _loader = _loadProfile());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.t('common.error'))));
    }
  }
}

class _ProfileData {
  final User? user;
  final List<Post> posts;
  final bool isMe;
  final bool isPrivateProfile;
  final bool githubConnected;
  final List<dynamic> contributions;

  _ProfileData({
    required this.user,
    required this.posts,
    required this.isMe,
    required this.isPrivateProfile,
    required this.githubConnected,
    required this.contributions,
  });
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Hero placeholder
        const ShimmerBox(width: double.infinity, height: 520),
        const SizedBox(height: 12),
        // Posts skeleton
        const PostCardSkeleton(),
        const PostCardSkeleton(),
        const PostCardSkeleton(),
      ],
    );
  }
}

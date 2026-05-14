import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/constants/routes.dart';
import '../../../core/models/models.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/state/feed_refresh_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ai_sheets.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/user_repository.dart';

part 'post_detail_widgets.dart';

const bool _kScreenshotMode = AppRuntimeConfig.screenshotMode;

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _postRepository = PostRepository();
  final _commentRepository = CommentRepository();
  final _userRepository = UserRepository();
  final _commentCtrl = TextEditingController();
  final _commentFocus = FocusNode();

  late Future<_PostDetailData> _loader;
  bool _isSendingComment = false;
  final Set<String> _expandedCommentIds = {};
  String? _replyingToCommentId;
  String? _replyingToName;

  @override
  void initState() {
    super.initState();
    _loader = _load();
  }

  @override
  void dispose() {
    _commentFocus.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<_PostDetailData> _load() async {
    final post = await _postRepository.getPostById(widget.postId);
    final comments = await _commentRepository.getCommentsForPost(widget.postId);
    return _PostDetailData(post: post, comments: comments);
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _loader = _load());
    await _loader;
  }

  Future<void> _handleLike() async {
    final currentData = await _loader;
    final post = currentData.post;
    if (post == null) return;

    final nextPost = post.copyWith(
      likeCount: post.isLikedByMe ? post.likeCount - 1 : post.likeCount + 1,
      isLikedByMe: !post.isLikedByMe,
    );

    setState(() {
      _loader = Future.value(
        _PostDetailData(post: nextPost, comments: currentData.comments),
      );
    });

    try {
      await _postRepository.toggleLike(widget.postId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loader = Future.value(currentData));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update reaction right now')),
      );
    }
  }

  Future<void> _handleBookmark() async {
    final currentData = await _loader;
    final post = currentData.post;
    if (post == null) return;

    final nextPost = post.copyWith(
      bookmarkCount:
          post.isBookmarkedByMe
              ? post.bookmarkCount - 1
              : post.bookmarkCount + 1,
      isBookmarkedByMe: !post.isBookmarkedByMe,
    );

    setState(() {
      _loader = Future.value(
        _PostDetailData(post: nextPost, comments: currentData.comments),
      );
    });

    try {
      await _postRepository.toggleBookmark(widget.postId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loader = Future.value(currentData));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save this post right now')),
      );
    }
  }

  Future<void> _addComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty || _isSendingComment) return;

    setState(() => _isSendingComment = true);
    try {
      await _commentRepository.createComment(
        postId: widget.postId,
        content: content,
        parentId: _replyingToCommentId,
      );
      _commentCtrl.clear();
      _replyingToCommentId = null;
      _replyingToName = null;
      FeedRefreshBus.instance.refresh();
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send comment right now')),
      );
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  Future<void> _handleFollow(Post post) async {
    final currentData = await _loader;
    final nextAuthor = post.author.copyWith(
      isFollowedByMe: !post.author.isFollowedByMe,
      followerCount:
          post.author.isFollowedByMe
              ? (post.author.followerCount - 1).clamp(0, 1 << 31)
              : post.author.followerCount + 1,
    );
    final nextPost = post.copyWith(author: nextAuthor);

    setState(() {
      _loader = Future.value(
        _PostDetailData(post: nextPost, comments: currentData.comments),
      );
    });

    try {
      await _userRepository.toggleFollow(post.author.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loader = Future.value(currentData));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update follow state right now'),
        ),
      );
    }
  }

  void _replyTo(Comment comment) {
    HapticFeedback.selectionClick();
    setState(() {
      _replyingToCommentId = comment.id;
      _replyingToName = comment.author.displayName;
      _expandedCommentIds.add(comment.id);
    });
    _commentFocus.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToName = null;
    });
  }

  void _toggleReplies(Comment comment) {
    setState(() {
      if (_expandedCommentIds.contains(comment.id)) {
        _expandedCommentIds.remove(comment.id);
      } else {
        _expandedCommentIds.add(comment.id);
      }
    });
  }

  Future<void> _markBestAnswer(Comment comment) async {
    try {
      await _commentRepository.markBestAnswer(
        postId: widget.postId,
        commentId: comment.id,
      );
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to mark best answer right now')),
      );
    }
  }

  Future<void> _showAiReview(Post post) {
    return showAiReviewSheet(
      context,
      reviewFuture: AiService.instance.reviewCode(
        code: _buildPostSnippet(post),
        language: 'typescript',
      ),
      title: 'AI Review',
    );
  }

  Future<void> _showAiExplain(Post post) async {
    final level = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        const levels = [
          ('beginner', 'Beginner'),
          ('intermediate', 'Intermediate'),
          ('advanced', 'Advanced'),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explain level',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ...levels.map(
                  (item) => ListTile(
                    leading: const Icon(Icons.psychology_alt_outlined),
                    title: Text(item.$2),
                    onTap: () => Navigator.of(context).pop(item.$1),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (level == null || !mounted) return;

    return showAiExplainSheet(
      context,
      explanationFuture: AiService.instance.explainCode(
        code: _buildPostSnippet(post),
        language: 'typescript',
        level: level,
      ),
      title: 'AI Explain ${level.toUpperCase()}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_kScreenshotMode) {
      return const _ShowcasePostDetailScreen();
    }

    return FutureBuilder<_PostDetailData>(
      future: _loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Post')),
            body: Center(
              child: ErrorState(
                message: 'Unable to load this post right now.',
                onRetry: _refresh,
              ),
            ),
          );
        }

        final data = snapshot.data;
        final post = data?.post;
        if (post == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Post')),
            body: const EmptyState(
              icon: Icons.article_outlined,
              title: 'Post not found',
              subtitle: 'This post may have been removed or is unavailable.',
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            title: const Text(
              'Post',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                onPressed: () => _copyLink(post),
                icon: const Icon(Icons.share_outlined),
              ),
              IconButton(
                onPressed: _handleBookmark,
                icon: Icon(
                  post.isBookmarkedByMe
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    children: [
                      _AuthorHeader(
                        post: post,
                        onFollowTap: () => _handleFollow(post),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            post.tags
                                .map((tag) => TechChip(label: tag))
                                .toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _leadParagraph(post),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.65,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _CodeSnippetCard(post: post),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showAiReview(post),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome, size: 16),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('AI Review'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showAiExplain(post),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.psychology_alt_outlined, size: 16),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Explain'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        post.content,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MetaRow(post: post),
                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: 'Comments',
                        trailing: '${data!.comments.length}',
                      ),
                      const SizedBox(height: 12),
                      if (data.comments.isEmpty)
                        const EmptyState(
                          icon: Icons.chat_bubble_outline,
                          title: 'No comments yet',
                          subtitle: 'Start the thread with a quick note.',
                        )
                      else
                        ..._buildCommentList(post, data.comments),
                    ],
                  ),
                ),
                _BottomCommentBar(
                  controller: _commentCtrl,
                  focusNode: _commentFocus,
                  post: post,
                  isSending: _isSendingComment,
                  replyingToName: _replyingToName,
                  onCancelReply: _cancelReply,
                  onLike: _handleLike,
                  onBookmark: _handleBookmark,
                  onComment: () => _commentFocus.requestFocus(),
                  onSend: _addComment,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _leadParagraph(Post post) {
    if (post.content.length < 120) return post.content;
    return '${post.content.substring(0, 120).trim()}...';
  }

  List<Widget> _buildCommentList(Post post, List<Comment> comments) {
    final currentUserId = AppPreferences.instance.userId;
    final canMarkBest =
        currentUserId != null && currentUserId == post.author.id;
    final byParent = <String?, List<Comment>>{};

    for (final comment in comments) {
      byParent.putIfAbsent(comment.parentId, () => []).add(comment);
    }

    for (final group in byParent.values) {
      group.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    final ids = comments.map((comment) => comment.id).toSet();
    final roots =
        comments
            .where(
              (comment) =>
                  comment.parentId == null || !ids.contains(comment.parentId),
            )
            .toList();
    if (roots.isEmpty) {
      return comments
          .map(
            (comment) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CommentCard(
                comment: comment,
                canMarkBest: canMarkBest && !comment.isBest,
                onReply: () => _replyTo(comment),
                onMarkBest: () => _markBestAnswer(comment),
                onUpvote: () => _commentRepository.upvoteComment(comment.id),
              ),
            ),
          )
          .toList();
    }

    List<Widget> buildBranch(Comment comment) {
      final replies = byParent[comment.id] ?? const <Comment>[];
      final expanded = _expandedCommentIds.contains(comment.id);
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _CommentCard(
            comment: comment,
            canMarkBest: canMarkBest && !comment.isBest,
            replyCount:
                replies.isNotEmpty ? replies.length : comment.replyCount,
            repliesExpanded: expanded,
            onToggleReplies:
                replies.isEmpty && comment.replyCount == 0
                    ? null
                    : () => _toggleReplies(comment),
            onReply: () => _replyTo(comment),
            onMarkBest: () => _markBestAnswer(comment),
            onUpvote: () => _commentRepository.upvoteComment(comment.id),
          ),
        ),
        if (expanded)
          for (final reply in replies) ...buildBranch(reply),
      ];
    }

    return [for (final root in roots) ...buildBranch(root)];
  }

  Future<void> _copyLink(Post post) async {
    await Clipboard.setData(
      ClipboardData(text: 'devconnect://post/${post.id}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied')));
  }
}

class _ShowcasePostDetailScreen extends StatefulWidget {
  const _ShowcasePostDetailScreen();

  @override
  State<_ShowcasePostDetailScreen> createState() =>
      _ShowcasePostDetailScreenState();
}

class _ShowcasePostDetailScreenState extends State<_ShowcasePostDetailScreen> {
  bool _bookmarked = false;
  bool _following = false;

  Future<void> _copyShowcaseLink() async {
    await Clipboard.setData(
      const ClipboardData(text: 'devconnect://post/showcase-nestjs'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text(
          'Post',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Share post',
            onPressed: _copyShowcaseLink,
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: _bookmarked ? 'Saved' : 'Save post',
            onPressed: () => setState(() => _bookmarked = !_bookmarked),
            icon: Icon(
              _bookmarked ? Icons.bookmark : Icons.bookmark_border_outlined,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        children: [
          Row(
            children: [
              const UserAvatar(name: 'Sarah Chen', size: 42, isOnline: true),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sarah Chen',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Senior Engineer @ Vercel • 2h ago',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => setState(() => _following = !_following),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      _following ? AppColors.success : AppColors.primary,
                  side: BorderSide(
                    color:
                        _following
                            ? AppColors.success.withValues(alpha: 0.45)
                            : const Color(0xFFD9D6FF),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _following ? 'Following' : 'Follow',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Building scalable backends with\nNestJS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ColoredTagChip(label: '#NestJS', color: Color(0xFF7C3AED)),
              ColoredTagChip(label: '#TypeScript', color: Color(0xFF2563EB)),
              ColoredTagChip(label: '#Backend', color: Color(0xFF5B53F6)),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            "NestJS is a powerful framework for building efficient, reliable, and scalable server-side applications. It leverages TypeScript and combines elements of OOP, Functional Programming, and Functional Reactive Programming.",
            style: TextStyle(
              fontSize: 14,
              height: 1.65,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "One of the key strengths is the dependency injection system, which allows for highly modular architectures. Let's look at a basic controller setup:",
            style: TextStyle(
              fontSize: 14,
              height: 1.65,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'TYPESCRIPT',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: const [
                        Icon(
                          Icons.copy_outlined,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "@Controller('users')\nexport class UsersController {\n  constructor(private readonly usersService: UsersService) {}\n\n  @Get()\n  findAll(): Promise<User[]> {\n    return this.usersService.findAll();\n  }\n}",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.3,
                    height: 1.55,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.favorite, size: 18, color: Color(0xFF334155)),
              SizedBox(width: 6),
              Text(
                '1.2k',
                style: TextStyle(fontSize: 12, color: Color(0xFF334155)),
              ),
              SizedBox(width: 18),
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: Color(0xFF334155),
              ),
              SizedBox(width: 6),
              Text(
                '42',
                style: TextStyle(fontSize: 12, color: Color(0xFF334155)),
              ),
              Spacer(),
              Icon(Icons.share_outlined, size: 18, color: Color(0xFF334155)),
              SizedBox(width: 16),
              Icon(
                Icons.bookmark_border_outlined,
                size: 18,
                color: Color(0xFF334155),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

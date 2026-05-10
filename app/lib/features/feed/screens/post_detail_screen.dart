import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/constants/routes.dart';
import '../../../core/models/models.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/state/feed_refresh_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ai_sheets.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/user_repository.dart';

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

  late Future<_PostDetailData> _loader;
  bool _isSendingComment = false;

  @override
  void initState() {
    super.initState();
    _loader = _load();
  }

  @override
  void dispose() {
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
      );
      _commentCtrl.clear();
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

  Future<void> _showAiExplain(Post post) {
    return showAiExplainSheet(
      context,
      explanationFuture: AiService.instance.explainCode(
        code: _buildPostSnippet(post),
        language: 'typescript',
      ),
      title: 'AI Explain',
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
          backgroundColor: Colors.white,
          appBar: AppBar(
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
                      const Divider(height: 1, color: Color(0xFFE8EAF2)),
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
                        ...data.comments.map((comment) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CommentCard(
                              comment: comment,
                              onUpvote:
                                  () => _commentRepository.upvoteComment(
                                    comment.id,
                                  ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                _BottomCommentBar(
                  controller: _commentCtrl,
                  post: post,
                  isSending: _isSendingComment,
                  onLike: _handleLike,
                  onBookmark: _handleBookmark,
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
      backgroundColor: Colors.white,
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
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE8EAF2)),
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

class _AuthorHeader extends StatelessWidget {
  const _AuthorHeader({required this.post, required this.onFollowTap});

  final Post post;
  final VoidCallback onFollowTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.push('${AppRoutes.userBase}/${post.author.id}'),
          child: UserAvatar(
            name: post.author.displayName,
            size: 46,
            isOnline: post.author.isOnline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap:
                () => context.push('${AppRoutes.userBase}/${post.author.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${post.author.username}  •  Developer  •  ${_timeAgo(post.createdAt)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        OutlinedButton(
          onPressed: onFollowTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF5B53F6),
            side: const BorderSide(color: Color(0xFFD9D6FF)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Follow',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CodeSnippetCard extends StatelessWidget {
  const _CodeSnippetCard({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final snippet = _buildSnippet(post);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'CODE BLOCK',
                style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textTertiary,
                ),
              ),
              const Spacer(),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.copy_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            snippet,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              height: 1.55,
              color: Color(0xFF6E59F7),
            ),
          ),
        ],
      ),
    );
  }

  String _buildSnippet(Post post) {
    final normalizedTitle = post.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final firstTag = post.tags.isNotEmpty ? post.tags.first : 'snippet';
    return "const ${normalizedTitle.isEmpty ? 'postDetail' : normalizedTitle} = {\n"
        "  topic: '${post.title}',\n"
        "  tag: '$firstTag',\n"
        "  status: 'ready for review',\n"
        "};";
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.visibility_outlined,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          '${post.viewCount} views',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 14),
        const Icon(
          Icons.chat_bubble_outline,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          '${post.commentCount} comments',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            trailing,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5B53F6),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentCard extends StatefulWidget {
  const _CommentCard({required this.comment, this.onUpvote});

  final Comment comment;
  final VoidCallback? onUpvote;

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  late int _upvotes;
  bool _upvoted = false;

  @override
  void initState() {
    super.initState();
    _upvotes = widget.comment.upvotes;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap:
                () => context.push(
                  '${AppRoutes.userBase}/${widget.comment.author.id}',
                ),
            child: UserAvatar(
              name: widget.comment.author.displayName,
              size: 34,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.comment.author.displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      _shortTimeAgo(widget.comment.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.comment.content,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (_upvoted) return;
                        setState(() {
                          _upvoted = true;
                          _upvotes += 1;
                        });
                        widget.onUpvote?.call();
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _upvoted ? const Color(0xFFF3F0FF) : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _upvoted
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_outlined,
                              size: 13,
                              color:
                                  _upvoted
                                      ? const Color(0xFF5B53F6)
                                      : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_upvotes',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color:
                                    _upvoted
                                        ? const Color(0xFF5B53F6)
                                        : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.comment.isBest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Best answer',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCommentBar extends StatelessWidget {
  const _BottomCommentBar({
    required this.controller,
    required this.post,
    required this.isSending,
    required this.onLike,
    required this.onBookmark,
    required this.onSend,
  });

  final TextEditingController controller;
  final Post post;
  final bool isSending;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EAF2))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PostActionBar(
              likes: post.likeCount,
              comments: post.commentCount,
              bookmarks: post.bookmarkCount,
              isLiked: post.isLikedByMe,
              isBookmarked: post.isBookmarkedByMe,
              onLike: onLike,
              onBookmark: onBookmark,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5B53F6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: isSending ? null : onSend,
                    icon:
                        isSending
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostDetailData {
  final Post? post;
  final List<Comment> comments;

  const _PostDetailData({required this.post, required this.comments});
}

extension on Post {
  Post copyWith({
    User? author,
    int? likeCount,
    int? bookmarkCount,
    bool? isLikedByMe,
    bool? isBookmarkedByMe,
  }) {
    return Post(
      id: id,
      author: author ?? this.author,
      title: title,
      content: content,
      type: type,
      tags: tags,
      imageUrl: imageUrl,
      viewCount: viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount,
      bookmarkCount: bookmarkCount ?? this.bookmarkCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isBookmarkedByMe: isBookmarkedByMe ?? this.isBookmarkedByMe,
      createdAt: createdAt,
    );
  }
}

extension on User {
  User copyWith({int? followerCount, bool? isFollowedByMe}) {
    return User(
      id: id,
      username: username,
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl,
      bio: bio,
      skills: skills,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount,
      postCount: postCount,
      reputation: reputation,
      isOnline: isOnline,
      isMentor: isMentor,
      isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
      createdAt: createdAt,
    );
  }
}

String _buildPostSnippet(Post post) {
  final normalizedTitle = post.title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final firstTag = post.tags.isNotEmpty ? post.tags.first : 'snippet';
  return "const ${normalizedTitle.isEmpty ? 'postDetail' : normalizedTitle} = {\n"
      "  topic: '${post.title}',\n"
      "  tag: '$firstTag',\n"
      "  status: 'ready for review',\n"
      "};";
}

String _timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}

String _shortTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

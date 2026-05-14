part of 'post_detail_screen.dart';

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
    final snippet = _extractCodeSnippet(post);
    if (snippet.isEmpty) return const SizedBox.shrink();
    final lines = snippet.split('\n');
    final lang = _detectLanguage(post);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2E),
            ),
            child: Row(
              children: [
                const Row(
                  children: [
                    _Dot2(Color(0xFFFF5F56)),
                    SizedBox(width: 6),
                    _Dot2(Color(0xFFFFBD2E)),
                    SizedBox(width: 6),
                    _Dot2(Color(0xFF27C93F)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF313244),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    lang.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF89B4FA),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: snippet));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied')),
                    );
                  },
                  child: const Icon(Icons.copy_outlined, size: 14, color: Color(0xFF6C7086)),
                ),
              ],
            ),
          ),
          // Code body
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: const Color(0xFF1E1E2E),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(lines.length.clamp(0, 12), (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF585B70),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          lines[i],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.5,
                            color: Color(0xFFCDD6F4),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _extractCodeSnippet(Post post) {
    // Try to extract fenced code block
    final fencedMatch = RegExp(r'```\w*\n?(.*?)```', dotAll: true).firstMatch(post.content);
    if (fencedMatch != null) return fencedMatch.group(1)?.trim() ?? '';

    // Fallback: generate a representative snippet from post metadata
    final normalizedTitle = post.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_\$'), '');
    final firstTag = post.tags.isNotEmpty ? post.tags.first : 'snippet';
    return "const ${normalizedTitle.isEmpty ? 'postDetail' : normalizedTitle} = {\n"
        "  topic: '${post.title}',\n"
        "  tag: '$firstTag',\n"
        "  status: 'ready for review',\n"
        "};";
  }

  String _detectLanguage(Post post) {
    final content = post.content.toLowerCase();
    final tags = post.tags.map((t) => t.toLowerCase()).toList();
    if (tags.contains('python') || content.contains('def ') || content.contains('import ')) return 'python';
    if (tags.contains('typescript') || tags.contains('nestjs')) return 'typescript';
    if (tags.contains('javascript') || tags.contains('react')) return 'javascript';
    if (tags.contains('dart') || tags.contains('flutter')) return 'dart';
    if (tags.contains('go') || tags.contains('golang')) return 'go';
    if (tags.contains('rust')) return 'rust';
    return 'code';
  }
}

class _Dot2 extends StatelessWidget {
  const _Dot2(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.post});

  final Post post;

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F6)),
      ),
      child: Row(
        children: [
          _MetaChip(icon: Icons.visibility_outlined, label: '${_fmt(post.viewCount)} views', color: const Color(0xFF6366F1)),
          const SizedBox(width: 16),
          _MetaChip(icon: Icons.chat_bubble_outline, label: '${_fmt(post.commentCount)} comments', color: const Color(0xFF10B981)),
          const SizedBox(width: 16),
          _MetaChip(icon: Icons.favorite_border, label: '${_fmt(post.likeCount)} likes', color: const Color(0xFFEF4444)),
          const Spacer(),
          _MetaChip(icon: Icons.bookmark_border, label: _fmt(post.bookmarkCount), color: const Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
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
  const _CommentCard({
    required this.comment,
    this.replyCount,
    this.repliesExpanded = false,
    this.canMarkBest = false,
    this.onToggleReplies,
    this.onReply,
    this.onMarkBest,
    this.onUpvote,
  });

  final Comment comment;
  final int? replyCount;
  final bool repliesExpanded;
  final bool canMarkBest;
  final VoidCallback? onToggleReplies;
  final VoidCallback? onReply;
  final VoidCallback? onMarkBest;
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
  void didUpdateWidget(covariant _CommentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment.id != widget.comment.id ||
        oldWidget.comment.upvotes != widget.comment.upvotes) {
      _upvotes = widget.comment.upvotes;
      _upvoted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double indent = (widget.comment.depth * 16.0).clamp(0.0, 96.0);

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Stack(
        children: [
          if (widget.comment.depth > 0)
            Positioned(
              left: -12,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: const Color(0xFFE8EAF2)),
            ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  widget.comment.depth > 0
                      ? Colors.white
                      : const Color(0xFFF9FAFD),
              borderRadius: BorderRadius.circular(18),
              border:
                  widget.comment.depth > 0
                      ? Border.all(color: const Color(0xFFE8EAF2))
                      : null,
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
                    size: widget.comment.depth > 0 ? 28 : 34,
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
                              style: TextStyle(
                                fontSize: widget.comment.depth > 0 ? 12 : 13,
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
                        style: TextStyle(
                          fontSize: widget.comment.depth > 0 ? 12 : 13,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (widget.comment.isBest) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Best answer',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                                    _upvoted
                                        ? const Color(0xFFF3F0FF)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _upvoted
                                        ? Icons.thumb_up
                                        : Icons.thumb_up_outlined,
                                    size: 12,
                                    color:
                                        _upvoted
                                            ? const Color(0xFF5B53F6)
                                            : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_upvotes',
                                    style: TextStyle(
                                      fontSize: 10,
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
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: widget.onReply,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.reply_outlined,
                                    size: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Reply',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (widget.canMarkBest) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: widget.onMarkBest,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Mark best',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if ((widget.replyCount ?? widget.comment.replyCount) >
                              0) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: widget.onToggleReplies,
                              borderRadius: BorderRadius.circular(999),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Text(
                                  widget.repliesExpanded
                                      ? 'Hide replies'
                                      : 'View ${widget.replyCount ?? widget.comment.replyCount} replies',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
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
          ),
        ],
      ),
    );
  }
}

class _BottomCommentBar extends StatelessWidget {
  const _BottomCommentBar({
    required this.controller,
    required this.focusNode,
    required this.post,
    required this.isSending,
    this.replyingToName,
    required this.onCancelReply,
    required this.onLike,
    required this.onBookmark,
    required this.onComment,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Post post;
  final bool isSending;
  final String? replyingToName;
  final VoidCallback onCancelReply;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onComment;
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
              onComment: onComment,
            ),
            const SizedBox(height: 10),
            if (replyingToName != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Replying to $replyingToName',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onCancelReply,
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                      focusNode: focusNode,
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

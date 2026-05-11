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

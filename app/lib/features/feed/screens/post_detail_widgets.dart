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
    final lang = _detectLanguage(post);

    return CodeBlock(code: snippet, language: lang);
  }

  String _extractCodeSnippet(Post post) =>
      TextProcessing.extractPostCodeSnippet(post);

  String _detectLanguage(Post post) => TextProcessing.detectPostLanguage(post);
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
          _MetaChip(
            icon: Icons.visibility_outlined,
            label: '${_fmt(post.viewCount)} views',
            color: const Color(0xFF6366F1),
          ),
          const SizedBox(width: 16),
          _MetaChip(
            icon: Icons.chat_bubble_outline,
            label: '${_fmt(post.commentCount)} comments',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 16),
          _MetaChip(
            icon: Icons.favorite_border,
            label: '${_fmt(post.likeCount)} likes',
            color: const Color(0xFFEF4444),
          ),
          const Spacer(),
          _MetaChip(
            icon: Icons.bookmark_border,
            label: _fmt(post.bookmarkCount),
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });
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
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
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

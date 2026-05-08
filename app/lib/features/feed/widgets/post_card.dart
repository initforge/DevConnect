import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/post_repository.dart';

// ============================================================
// POST CARD - Enhanced with animations and better UX
// ============================================================

/// Thẻ bài viết — dùng ở Feed, Profile, Explore
class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onTap;
  final int index;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.index = 0,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _liked;
  late bool _bookmarked;
  late int _likeCount;
  final _repository = PostRepository();

  @override
  void initState() {
    super.initState();
    _liked = widget.post.isLikedByMe;
    _bookmarked = widget.post.isBookmarkedByMe;
    _likeCount = widget.post.likeCount;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}p trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    return '${diff.inDays}d trước';
  }

  String _typeLabel(PostType type) {
    switch (type) {
      case PostType.article: return 'Bài viết';
      case PostType.snippet: return 'Code';
      case PostType.til: return 'TIL';
      case PostType.question: return 'Hỏi đáp';
      case PostType.project: return 'Dự án';
      case PostType.discussion: return 'Thảo luận';
    }
  }

  Color _typeColor(PostType type) {
    switch (type) {
      case PostType.article: return AppColors.primary;
      case PostType.snippet: return AppColors.accent;
      case PostType.til: return AppColors.warning;
      case PostType.question: return AppColors.aiPurple;
      case PostType.project: return AppColors.success;
      case PostType.discussion: return AppColors.textSecondary;
    }
  }

  /// Estimate reading time based on content length
  int _estimateReadingTime() {
    final wordCount = widget.post.content.split(RegExp(r'\s+')).length;
    return (wordCount / 200).ceil().clamp(1, 30);
  }

  /// Check if content contains code snippets
  bool _hasCodeSnippet() {
    return widget.post.content.contains(RegExp(r'```|```[\s\S]*?```|`[^`]+`'));
  }

  /// Format view count for display
  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return '$views';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final readingTime = _estimateReadingTime();
    final hasCode = _hasCodeSnippet();

    return AnimatedCard(
      index: widget.index,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author row with avatar and meta
              Row(children: [
                UserAvatar(
                  name: p.author.displayName,
                  imageUrl: p.author.avatarUrl,
                  size: 36,
                  isOnline: p.author.isOnline,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.author.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '@${p.author.username} · ${_timeAgo(p.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _typeColor(p.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _typeLabel(p.type),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _typeColor(p.type),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 10),

              // Title
              Text(
                p.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Content preview
              Text(
                p.content.replaceAll(RegExp(r'```[\s\S]*?```'), '[code]').replaceAll(RegExp(r'[#*`]'), ''),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Code snippet preview indicator
              if (hasCode) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurfaceAlt.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.code,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Chứa code snippet',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Tags with better styling
              if (p.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: p.tags.take(4).map((t) => ColoredTagChip(
                    label: '#$t',
                    color: AppColors.primary,
                  )).toList(),
                ),
              ],

              const SizedBox(height: 10),

              // Meta info row: reading time, views, etc.
              Row(
                children: [
                  // Reading time
                  if (p.type == PostType.article || p.type == PostType.til) ...[
                    _MetaBadge(
                      icon: Icons.schedule,
                      text: '$readingTime phút đọc',
                    ),
                    const SizedBox(width: 12),
                  ],
                  // View count
                  _MetaBadge(
                    icon: Icons.visibility_outlined,
                    text: _formatViews(p.viewCount),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Actions
              PostActionBar(
                likes: _likeCount,
                comments: p.commentCount,
                bookmarks: p.bookmarkCount,
                isLiked: _liked,
                isBookmarked: _bookmarked,
                onLike: () async {
                  HapticFeedback.lightImpact();
                  final newLiked = await _repository.toggleLike(p.id);
                  if (mounted) {
                    setState(() {
                      _liked = newLiked;
                      _likeCount += newLiked ? 1 : -1;
                    });
                  }
                },
                onBookmark: () async {
                  HapticFeedback.lightImpact();
                  final newBookmarked = await _repository.toggleBookmark(p.id);
                  if (mounted) {
                    setState(() => _bookmarked = newBookmarked);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small meta badge for post info (reading time, views, etc.)
class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    const badgeColor = AppColors.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: badgeColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: badgeColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

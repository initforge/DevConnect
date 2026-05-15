import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/post_repository.dart';

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post, this.onTap, this.index = 0});

  final Post post;
  final VoidCallback? onTap;
  final int index;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _repository = PostRepository();
  late bool _liked;
  late bool _bookmarked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.isLikedByMe;
    _bookmarked = widget.post.isBookmarkedByMe;
    _likeCount = widget.post.likeCount;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  int _estimateReadingTime() {
    final wordCount = widget.post.content.split(RegExp(r'\s+')).length;
    return (wordCount / 200).ceil().clamp(1, 30);
  }

  bool _hasCodeSnippet() {
    final text = widget.post.content;
    return text.contains(RegExp(r'```|`[^`]+`')) ||
        text.contains('const ') ||
        text.contains('function ') ||
        text.contains('class ') ||
        text.contains('import ') ||
        text.contains('def ');
  }

  String _formatViews(int views) {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K';
    return '$views';
  }

  String _authorMeta(User author) {
    final bio = author.bio?.trim();
    if (bio == null || bio.isEmpty) {
      return '@${author.username}';
    }
    final firstSentence = bio.split('.').first.trim();
    if (firstSentence.length > 34) {
      return '${firstSentence.substring(0, 34)}...';
    }
    return firstSentence;
  }

  String _previewText(String content) {
    return content
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAll(RegExp(r'[#*_`]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(
      ClipboardData(text: 'devconnect://post/${widget.post.id}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).t('feed.linkCopied'))),
    );
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.lightImpact();
    final oldBookmarked = _bookmarked;

    // Optimistic Update
    setState(() => _bookmarked = !oldBookmarked);

    try {
      final success = await _repository.toggleBookmark(widget.post.id);
      if (!mounted) return;
      if (success != _bookmarked) {
        setState(() => _bookmarked = success);
      }
    } catch (e) {
      if (!mounted) return;
      // Rollback
      setState(() => _bookmarked = oldBookmarked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).t('feed.bookmarkFailed')),
        ),
      );
    }
  }

  Future<void> _showPostActions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.link_outlined),
                title: Text(AppStrings.of(context).t('feed.copyLink')),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _copyLink();
                },
              ),
              ListTile(
                leading: Icon(
                  _bookmarked
                      ? Icons.bookmark_remove_outlined
                      : Icons.bookmark_border,
                ),
                title: Text(
                  _bookmarked
                      ? AppStrings.of(context).t('feed.removeBookmark')
                      : AppStrings.of(context).t('feed.savePost'),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _toggleBookmark();
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(AppStrings.of(context).t('feed.reportPost')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppStrings.of(context).t('feed.reportNoted'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPostDetail() {
    if (!mounted) return;
    context.push('${AppRoutes.postBase}/${widget.post.id}');
  }

  Widget _buildHighlightedText(
    String? text,
    String fallback,
    TextStyle style, {
    int maxLines = 2,
  }) {
    if (text == null || text.isEmpty) {
      return Text(
        fallback,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final List<TextSpan> spans = [];
    final regex = RegExp(r'<b>(.*?)</b>', caseSensitive: false);
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: style.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF4F46E5),
          ),
        ),
      );
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return Text.rich(
      TextSpan(children: spans, style: style),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final hasCode = _hasCodeSnippet();
    final preview = _previewText(post.content);
    final readingTime = _estimateReadingTime();

    return AnimatedCard(
      index: widget.index,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFECEFF5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A111827),
                blurRadius: 24,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Color(0x06111827),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient accent strip
              Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  gradient: LinearGradient(colors: _accentGradient(post.type)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author row
                    Row(
                      children: [
                        UserAvatar(
                          name: post.author.displayName,
                          imageUrl: post.author.avatarUrl,
                          size: 40,
                          isOnline: post.author.isOnline,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      post.author.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _typeColor(
                                        post.type,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _typeName(post.type),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: _typeColor(post.type),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_authorMeta(post.author)}  •  ${_timeAgo(post.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _showPostActions,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.more_horiz,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Title
                    _buildHighlightedText(
                      post.highlightedTitle,
                      post.title,
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Preview
                    _buildHighlightedText(
                      post.highlightedContent,
                      preview,
                      const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                      maxLines: 2,
                    ),

                    if (hasCode) ...[
                      const SizedBox(height: 12),
                      _CodePreviewSurface(content: post.content),
                    ],
                    if (post.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children:
                            post.tags
                                .take(4)
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F3FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF5B53F6),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Engagement bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _EngagementChip(
                            icon:
                                _liked ? Icons.favorite : Icons.favorite_border,
                            label: _formatViews(_likeCount),
                            color:
                                _liked
                                    ? const Color(0xFFEF4444)
                                    : AppColors.textSecondary,
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final oldLiked = _liked;
                              final oldLikeCount = _likeCount;
                              setState(() {
                                _liked = !oldLiked;
                                _likeCount += _liked ? 1 : -1;
                              });
                              try {
                                final success = await _repository.toggleLike(
                                  post.id,
                                );
                                if (!mounted) return;
                                if (success != _liked) {
                                  setState(() {
                                    _liked = success;
                                    _likeCount =
                                        oldLikeCount + (success ? 1 : -1);
                                  });
                                }
                              } catch (e) {
                                if (!mounted) return;
                                setState(() {
                                  _liked = oldLiked;
                                  _likeCount = oldLikeCount;
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          _EngagementChip(
                            icon: Icons.chat_bubble_outline,
                            label: _formatViews(post.commentCount),
                            color: AppColors.textSecondary,
                            onTap: _openPostDetail,
                          ),
                          const SizedBox(width: 16),
                          _EngagementChip(
                            icon:
                                _bookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                            label: _formatViews(post.bookmarkCount),
                            color:
                                _bookmarked
                                    ? const Color(0xFF5B53F6)
                                    : AppColors.textSecondary,
                            onTap: () async {
                              await _toggleBookmark();
                            },
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 13,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatViews(post.viewCount),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              if (post.type == PostType.article ||
                                  post.type == PostType.til) ...[
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.schedule,
                                  size: 13,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${readingTime}m',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
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
        ),
      ),
    );
  }

  List<Color> _accentGradient(PostType type) {
    switch (type) {
      case PostType.article:
        return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
      case PostType.snippet:
        return [const Color(0xFF10B981), const Color(0xFF06D6A0)];
      case PostType.til:
        return [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
      case PostType.question:
        return [const Color(0xFFEF4444), const Color(0xFFF97316)];
      default:
        return [const Color(0xFF6366F1), const Color(0xFF06B6D4)];
    }
  }

  Color _typeColor(PostType type) {
    switch (type) {
      case PostType.article:
        return const Color(0xFF6366F1);
      case PostType.snippet:
        return const Color(0xFF10B981);
      case PostType.til:
        return const Color(0xFFD97706);
      case PostType.question:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _typeName(PostType type) {
    switch (type) {
      case PostType.article:
        return 'Article';
      case PostType.snippet:
        return 'Snippet';
      case PostType.til:
        return 'TIL';
      case PostType.question:
        return 'Q&A';
      default:
        return 'Post';
    }
  }
}

class _CodePreviewSurface extends StatelessWidget {
  const _CodePreviewSurface({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final lines =
        content
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .take(6)
            .toList();

    return Container(
      height: 148,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _Dot(Color(0xFFF87171)),
              SizedBox(width: 6),
              _Dot(Color(0xFFFBBF24)),
              SizedBox(width: 6),
              _Dot(Color(0xFF34D399)),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(lines.length.clamp(4, 6), (index) {
            final line = index < lines.length ? lines[index] : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line.isEmpty ? '...' : line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            [
                              const Color(0xFF60A5FA),
                              const Color(0xFFA78BFA),
                              const Color(0xFF34D399),
                              const Color(0xFFFBBF24),
                              const Color(0xFFF472B6),
                              const Color(0xFF93C5FD),
                            ][index],
                        fontSize: 11.5,
                        height: 1.3,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EngagementChip extends StatelessWidget {
  const _EngagementChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

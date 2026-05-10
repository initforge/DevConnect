import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Post link copied')));
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.lightImpact();
    final bookmarked = await _repository.toggleBookmark(widget.post.id);
    if (!mounted) return;
    setState(() => _bookmarked = bookmarked);
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
                title: const Text('Copy link'),
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
                title: Text(_bookmarked ? 'Remove bookmark' : 'Save post'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _toggleBookmark();
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report post'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Report noted. Our moderation queue has it.',
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
        borderRadius: BorderRadius.circular(24),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE7EAF3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10111827),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(
                    name: post.author.displayName,
                    imageUrl: post.author.avatarUrl,
                    size: 38,
                    isOnline: post.author.isOnline,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
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
              const SizedBox(height: 10),
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                preview,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasCode) ...[
                const SizedBox(height: 12),
                _CodePreviewSurface(content: post.content),
              ],
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      post.tags
                          .take(3)
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F1FF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5B53F6),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (post.type == PostType.article ||
                      post.type == PostType.til) ...[
                    _MetaBadge(
                      icon: Icons.schedule,
                      text: '$readingTime min read',
                    ),
                    const SizedBox(width: 12),
                  ],
                  _MetaBadge(
                    icon: Icons.visibility_outlined,
                    text: _formatViews(post.viewCount),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PostActionBar(
                likes: _likeCount,
                comments: post.commentCount,
                bookmarks: post.bookmarkCount,
                isLiked: _liked,
                isBookmarked: _bookmarked,
                onLike: () async {
                  HapticFeedback.lightImpact();
                  final liked = await _repository.toggleLike(post.id);
                  if (!mounted) return;
                  setState(() {
                    _liked = liked;
                    _likeCount += liked ? 1 : -1;
                  });
                },
                onBookmark: () async {
                  await _toggleBookmark();
                },
              ),
            ],
          ),
        ),
      ),
    );
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

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

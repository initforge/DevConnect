import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/state/feed_refresh_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/services/api_service.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../../data/repositories/post_repository.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _postRepository = PostRepository();
  final _commentRepository = CommentRepository();
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
    setState(() {
      _loader = _load();
    });
    await _loader;
  }

  Future<void> _handleLike() async {
    final currentData = await _loader;
    if (currentData.post == null) return;

    final wasLiked = currentData.post!.isLikedByMe;
    final newLikeCount = wasLiked
        ? currentData.post!.likeCount - 1
        : currentData.post!.likeCount + 1;

    // Optimistic update
    setState(() {
      _loader = Future.value(_PostDetailData(
        post: Post(
          id: currentData.post!.id,
          author: currentData.post!.author,
          title: currentData.post!.title,
          content: currentData.post!.content,
          type: currentData.post!.type,
          tags: currentData.post!.tags,
          imageUrl: currentData.post!.imageUrl,
          viewCount: currentData.post!.viewCount,
          likeCount: newLikeCount,
          commentCount: currentData.post!.commentCount,
          bookmarkCount: currentData.post!.bookmarkCount,
          isLikedByMe: !wasLiked,
          isBookmarkedByMe: currentData.post!.isBookmarkedByMe,
          createdAt: currentData.post!.createdAt,
        ),
        comments: currentData.comments,
      ));
    });

    // API call
    try {
      await _postRepository.toggleLike(widget.postId);
    } catch (e) {
      // Rollback on error
      if (mounted) {
        setState(() {
          _loader = Future.value(currentData);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật. Vui lòng thử lại.')),
        );
      }
    }
  }

  Future<void> _handleBookmark() async {
    final currentData = await _loader;
    if (currentData.post == null) return;

    final wasBookmarked = currentData.post!.isBookmarkedByMe;

    // Optimistic update
    setState(() {
      _loader = Future.value(_PostDetailData(
        post: Post(
          id: currentData.post!.id,
          author: currentData.post!.author,
          title: currentData.post!.title,
          content: currentData.post!.content,
          type: currentData.post!.type,
          tags: currentData.post!.tags,
          imageUrl: currentData.post!.imageUrl,
          viewCount: currentData.post!.viewCount,
          likeCount: currentData.post!.likeCount,
          commentCount: currentData.post!.commentCount,
          bookmarkCount: wasBookmarked
              ? currentData.post!.bookmarkCount - 1
              : currentData.post!.bookmarkCount + 1,
          isLikedByMe: currentData.post!.isLikedByMe,
          isBookmarkedByMe: !wasBookmarked,
          createdAt: currentData.post!.createdAt,
        ),
        comments: currentData.comments,
      ));
    });

    // API call
    try {
      await _postRepository.toggleBookmark(widget.postId);
    } catch (e) {
      // Rollback
      if (mounted) {
        setState(() {
          _loader = Future.value(currentData);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật. Vui lòng thử lại.')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSendingComment = true);

    try {
      await _commentRepository.createComment(
        postId: widget.postId,
        content: content,
      );
      _commentCtrl.clear();
      FeedRefreshBus.instance.refresh();
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gửi bình luận. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingComment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PostDetailData>(
      future: _loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Đang tải...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lỗi')),
            body: Center(
              child: ErrorState(
                message: 'Đã xảy ra lỗi',
                onRetry: _refresh,
              ),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null || data.post == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Không tìm thấy')),
            body: const EmptyState(
              icon: Icons.article_outlined,
              title: 'Không tìm thấy bài viết',
              subtitle: 'Bài viết có thể đã bị xóa hoặc dữ liệu local chưa được seed.',
            ),
          );
        }

        final post = data.post!;
        final comments = data.comments;

        return Scaffold(
          appBar: AppBar(
            title: Text(post.author.displayName),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _showShareOptions(post),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, post),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 20),
                        SizedBox(width: 8),
                        Text('Sao chép liên kết'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Xóa', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPostHeader(post),
                        const SizedBox(height: 16),
                        Text(
                          post.title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: post.tags.map<Widget>((tag) => TechChip(label: tag)).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          post.content,
                          style: const TextStyle(fontSize: 15, height: 1.7, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        _buildPostStats(post),
                        const Divider(height: 32),
                        _buildCommentsSection(comments),
                      ],
                    ),
                  ),
                ),
                _buildCommentInput(post),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostHeader(Post post) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/user/${post.author.id}'),
          child: UserAvatar(
            name: post.author.displayName,
            size: 44,
            isOnline: post.author.isOnline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/user/${post.author.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.author.displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('@${post.author.username}', style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostStats(Post post) {
    return Row(
      children: [
        const Icon(Icons.visibility_outlined, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          '${post.viewCount} lượt xem',
          style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
        const SizedBox(width: 16),
        Text(
          _formatTimeAgo(post.createdAt),
          style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildCommentsSection(List<Comment> comments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bình luận (${comments.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (comments.isEmpty)
          const EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'Chưa có bình luận nào',
            subtitle: 'Hãy thêm bình luận đầu tiên cho bài viết này.',
          )
        else
          ...comments.map((comment) => _CommentTile(
            comment: comment,
            onUpvote: () => _commentRepository.upvoteComment(comment.id),
          )),
      ],
    );
  }

  Widget _buildCommentInput(Post post) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PostActionBar(
              likes: post.likeCount,
              comments: post.commentCount,
              bookmarks: post.bookmarkCount,
              isLiked: post.isLikedByMe,
              isBookmarked: post.isBookmarkedByMe,
              onLike: _handleLike,
              onBookmark: _handleBookmark,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: 'Viết bình luận...',
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSendingComment ? null : _addComment,
                  icon: _isSendingComment
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showShareOptions(Post post) {
    Clipboard.setData(ClipboardData(text: 'devconnect://post/${post.id}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép liên kết')),
    );
  }

  void _handleMenuAction(String action, Post post) {
    switch (action) {
      case 'copy':
        _showShareOptions(post);
        break;
      case 'edit':
        _showEditDialog(post);
        break;
      case 'delete':
        _showDeleteConfirm(post);
        break;
    }
  }

  void _showEditDialog(Post post) {
    final titleCtrl = TextEditingController(text: post.title);
    final contentCtrl = TextEditingController(text: post.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa bài viết'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: contentCtrl, maxLines: 5, decoration: const InputDecoration(labelText: 'Nội dung', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.instance.patch('/api/posts/${post.id}', {
                  'title': titleCtrl.text.trim(),
                  'content': contentCtrl.text.trim(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật bài viết')));
                  _refresh();
                }
              } catch (_) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể cập nhật')));
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(Post post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài viết?'),
        content: const Text('Bài viết sẽ bị xóa vĩnh viễn. Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _postRepository.deletePost(post.id);
                FeedRefreshBus.instance.refresh();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa bài viết')));
                  context.pop();
                }
              } catch (_) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xóa bài viết')));
              }
            },
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _PostDetailData {
  final Post? post;
  final List<Comment> comments;

  const _PostDetailData({required this.post, required this.comments});
}

class _CommentTile extends StatefulWidget {
  final Comment comment;
  final VoidCallback? onUpvote;

  const _CommentTile({required this.comment, this.onUpvote});

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _upvoted = false;
  int _upvotes = 0;

  @override
  void initState() {
    super.initState();
    _upvotes = widget.comment.upvotes;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/user/${widget.comment.author.id}'),
            child: UserAvatar(name: widget.comment.author.displayName, size: 32),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.comment.author.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      _formatTimeAgo(widget.comment.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(widget.comment.content, style: const TextStyle(fontSize: 14, height: 1.4)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (!_upvoted) {
                          setState(() { _upvoted = true; _upvotes++; });
                          widget.onUpvote?.call();
                        }
                      },
                      child: Row(
                        children: [
                          Icon(_upvoted ? Icons.thumb_up : Icons.thumb_up_outlined, size: 14, color: _upvoted ? AppColors.primary : AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text('$_upvotes', style: TextStyle(fontSize: 12, color: _upvoted ? AppColors.primary : AppColors.textTertiary)),
                        ],
                      ),
                    ),
                    if (widget.comment.isBest) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Best',
                          style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600),
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

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

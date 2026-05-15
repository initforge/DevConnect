import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';

class CommentCard extends StatefulWidget {
  const CommentCard({
    super.key,
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
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  late int _upvotes;
  bool _upvoted = false;

  @override
  void initState() {
    super.initState();
    _upvotes = widget.comment.upvotes;
  }

  @override
  void didUpdateWidget(covariant CommentCard oldWidget) {
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
                              child: const Row(
                                children: [
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

String _shortTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dateTime.day}/${dateTime.month}';
}

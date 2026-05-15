import 'package:flutter/material.dart';

import 'package:devconnect/core/theme/app_colors.dart';
import 'package:devconnect/core/theme/app_spacing.dart';
import 'package:devconnect/core/widgets/animations/animated_card.dart'
    show AnimatedLikeButton, AnimatedBookmarkButton, PressableScale;

// ============================================================
// ACTION BAR
// ============================================================

class PostActionBar extends StatelessWidget {
  final int likes;
  final int comments;
  final int bookmarks;
  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;

  const PostActionBar({
    super.key,
    required this.likes,
    required this.comments,
    required this.bookmarks,
    this.isLiked = false,
    this.isBookmarked = false,
    this.onLike,
    this.onComment,
    this.onBookmark,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedLikeButton(isLiked: isLiked, count: likes, onTap: onLike),
        const SizedBox(width: AppSpacing.lg),
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: _format(comments),
          onTap: onComment,
        ),
        const SizedBox(width: AppSpacing.lg),
        AnimatedBookmarkButton(
          isBookmarked: isBookmarked,
          count: bookmarks,
          onTap: onBookmark,
        ),
        const Spacer(),
        _ActionButton(icon: Icons.share_outlined, label: '', onTap: onShare),
      ],
    );
  }

  String _format(int n) => n > 999 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

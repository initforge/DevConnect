import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/routes.dart';
import '../theme/app_colors.dart';

part 'shared_widgets/bottom_nav.dart';

// ============================================================
// CONSTANTS - Design System
// ============================================================
const double kBorderRadiusSm = 8.0;
const double kBorderRadiusMd = 12.0;
const double kBorderRadiusLg = 16.0;
const double kBorderRadiusXl = 20.0;
const double kSpacingXs = 4.0;
const double kSpacingSm = 8.0;
const double kSpacingMd = 12.0;
const double kSpacingLg = 16.0;
const double kSpacingXl = 24.0;
const Duration kAnimationFast = Duration(milliseconds: 150);
const Duration kAnimationNormal = Duration(milliseconds: 300);
const Duration kAnimationSlow = Duration(milliseconds: 500);

// ============================================================
// ANIMATED WIDGETS
// ============================================================

/// Card appear animation wrapper with staggered entrance
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const AnimatedCard({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 50),
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kAnimationNormal);
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

/// Button press scale animation wrapper for tactile feedback
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kAnimationFast);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// Animated like button with bounce effect
class AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final int count;
  final VoidCallback? onTap;

  const AnimatedLikeButton({
    super.key,
    required this.isLiked,
    required this.count,
    this.onTap,
  });

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(AnimatedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked != oldWidget.isLiked && widget.isLiked) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: widget.onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Icon(
              widget.isLiked ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: widget.isLiked ? AppColors.error : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _formatCount(widget.count),
            style: TextStyle(
              fontSize: 13,
              color: widget.isLiked ? AppColors.error : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) =>
      n > 999 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

/// Animated bookmark button
class AnimatedBookmarkButton extends StatefulWidget {
  final bool isBookmarked;
  final int count;
  final VoidCallback? onTap;

  const AnimatedBookmarkButton({
    super.key,
    required this.isBookmarked,
    required this.count,
    this.onTap,
  });

  @override
  State<AnimatedBookmarkButton> createState() => _AnimatedBookmarkButtonState();
}

class _AnimatedBookmarkButtonState extends State<AnimatedBookmarkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(AnimatedBookmarkButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBookmarked != oldWidget.isBookmarked && widget.isBookmarked) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: widget.onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Icon(
              widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              size: 20,
              color:
                  widget.isBookmarked
                      ? AppColors.warning
                      : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _formatCount(widget.count),
            style: TextStyle(
              fontSize: 13,
              color:
                  widget.isBookmarked
                      ? AppColors.warning
                      : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) =>
      n > 999 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

// ============================================================
// AVATAR WIDGETS
// ============================================================

/// Avatar tròn — có viền xanh nếu online
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage:
              imageUrl != null ? CachedNetworkImageProvider(imageUrl!) : null,
          child:
              imageUrl == null
                  ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  )
                  : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// CHIPS & TAGS
// ============================================================

/// Chip công nghệ — Flutter, Python, Docker...
class TechChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const TechChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scaleFactor: 0.97,
      child: AnimatedContainer(
        duration: kAnimationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingMd,
          vertical: kSpacingSm,
        ),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(kBorderRadiusXl),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Tag chip với màu sắc tùy chỉnh
class ColoredTagChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const ColoredTagChip({
    super.key,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scaleFactor: 0.97,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(kBorderRadiusMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOADING STATES
// ============================================================

/// Loading shimmer effect with animation
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = kBorderRadiusSm,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                AppColors.surfaceAlt,
                Color(0xFFE8E8E8),
                AppColors.surfaceAlt,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loading placeholder for PostCard
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerBox(width: 40, height: 40, borderRadius: 20),
              const SizedBox(width: kSpacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 120, height: 14),
                    SizedBox(height: 6),
                    ShimmerBox(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingMd),
          const ShimmerBox(width: double.infinity, height: 18),
          const SizedBox(height: kSpacingSm),
          const ShimmerBox(width: 200, height: 18),
          const SizedBox(height: kSpacingMd),
          Row(
            children: const [
              ShimmerBox(width: 60, height: 24, borderRadius: 12),
              SizedBox(width: kSpacingSm),
              ShimmerBox(width: 70, height: 24, borderRadius: 12),
              SizedBox(width: kSpacingSm),
              ShimmerBox(width: 50, height: 24, borderRadius: 12),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY STATES
// ============================================================

/// Màn hình trống với icon, title, subtitle và optional action button
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kSpacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: kSpacingLg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: kSpacingSm),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: kSpacingLg),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Màn hình lỗi với nút thử lại
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: kSpacingLg),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: kSpacingLg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state variants for different contexts
class EmptyPostFeed extends StatelessWidget {
  final VoidCallback? onCreatePost;

  const EmptyPostFeed({super.key, this.onCreatePost});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.article_outlined,
      title: 'Chưa có bài viết nào',
      subtitle: 'Hãy là người đầu tiên chia sẻ kiến thức với cộng đồng!',
      actionLabel: onCreatePost != null ? 'Tạo bài viết' : null,
      onAction: onCreatePost,
    );
  }
}

class EmptySearchResults extends StatelessWidget {
  final String? query;

  const EmptySearchResults({super.key, this.query});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off_outlined,
      title: 'Không tìm thấy kết quả',
      subtitle:
          query != null
              ? 'Không có kết quả cho "$query"'
              : 'Thử từ khóa khác hoặc kiểm tra chính tả',
    );
  }
}

class EmptyNotifications extends StatelessWidget {
  const EmptyNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.notifications_none_outlined,
      title: 'Chưa có thông báo nào',
      subtitle:
          'Các thông báo về likes, comments và followers sẽ xuất hiện ở đây.',
    );
  }
}

class EmptyMessages extends StatelessWidget {
  final VoidCallback? onNewMessage;

  const EmptyMessages({super.key, this.onNewMessage});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.chat_bubble_outline_outlined,
      title: 'Chưa có tin nhắn nào',
      subtitle: 'Bắt đầu cuộc trò chuyện với bạn bè và đồng nghiệp!',
      actionLabel: onNewMessage != null ? 'Tin nhắn mới' : null,
      onAction: onNewMessage,
    );
  }
}

// ============================================================
// BANNERS
// ============================================================

class FuturePhaseBanner extends StatelessWidget {
  final String title;
  final String description;
  final String badge;
  final IconData icon;
  final bool showActionHint;

  const FuturePhaseBanner({
    super.key,
    required this.title,
    required this.description,
    this.badge = 'PHASE 2',
    this.icon = Icons.rocket_launch_outlined,
    this.showActionHint = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: kSpacingLg),
      padding: const EdgeInsets.all(kSpacingLg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(kBorderRadiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(kSpacingSm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(kBorderRadiusMd),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: kSpacingMd),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingMd),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (showActionHint) ...[
            const SizedBox(height: 10),
            const Text(
              'Giao diện được giữ lại để minh họa roadmap. CRUD, realtime hoặc backend sẽ được bổ sung ở giai đoạn sau.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
        const SizedBox(width: kSpacingLg),
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: _format(comments),
          onTap: onComment,
        ),
        const SizedBox(width: kSpacingLg),
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

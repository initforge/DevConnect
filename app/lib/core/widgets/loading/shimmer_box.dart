import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

// Border radius constant (local)
const double _kBorderRadiusSm = 8.0;

// ============================================================
// LOADING STATES
// ============================================================

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = _kBorderRadiusSm,
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

class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(width: 40, height: 40, borderRadius: 20),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 120, height: 14),
                    SizedBox(height: 6),
                    ShimmerBox(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          ShimmerBox(width: double.infinity, height: 18),
          SizedBox(height: AppSpacing.sm),
          ShimmerBox(width: 200, height: 18),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              ShimmerBox(width: 60, height: 24, borderRadius: 12),
              SizedBox(width: AppSpacing.sm),
              ShimmerBox(width: 70, height: 24, borderRadius: 12),
              SizedBox(width: AppSpacing.sm),
              ShimmerBox(width: 50, height: 24, borderRadius: 12),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SKELETON VARIANTS
// ============================================================

/// Skeleton for a user list item (explore top-developers, search people tab).
class UserListItemSkeleton extends StatelessWidget {
  const UserListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ShimmerBox(width: 46, height: 46, borderRadius: 23),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 120, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: 80, height: 12),
              ],
            ),
          ),
          ShimmerBox(width: 64, height: 28, borderRadius: 14),
        ],
      ),
    );
  }
}

/// Skeleton for a conversation row (chat list).
class ConversationRowSkeleton extends StatelessWidget {
  const ConversationRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ShimmerBox(width: 50, height: 50, borderRadius: 25),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 140, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: double.infinity, height: 12),
              ],
            ),
          ),
          SizedBox(width: 8),
          ShimmerBox(width: 36, height: 12),
        ],
      ),
    );
  }
}

/// Skeleton for a notification tile.
class NotificationTileSkeleton extends StatelessWidget {
  const NotificationTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 36, height: 36, borderRadius: 18),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: 80, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a job card.
class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(width: 46, height: 46, borderRadius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 160, height: 15),
                    SizedBox(height: 6),
                    ShimmerBox(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 12),
          SizedBox(height: 6),
          ShimmerBox(width: 200, height: 12),
          SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 40, borderRadius: 14),
        ],
      ),
    );
  }
}

/// Skeleton for a project card.
class ProjectCardSkeleton extends StatelessWidget {
  const ProjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 180, height: 16),
          SizedBox(height: 8),
          ShimmerBox(width: double.infinity, height: 12),
          SizedBox(height: 4),
          ShimmerBox(width: 240, height: 12),
          SizedBox(height: 12),
          Row(
            children: [
              ShimmerBox(width: 60, height: 24, borderRadius: 12),
              SizedBox(width: 8),
              ShimmerBox(width: 60, height: 24, borderRadius: 12),
              SizedBox(width: 8),
              ShimmerBox(width: 60, height: 24, borderRadius: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a leaderboard row.
class LeaderboardRowSkeleton extends StatelessWidget {
  const LeaderboardRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ShimmerBox(width: 28, height: 14),
          SizedBox(width: 8),
          ShimmerBox(width: 40, height: 40, borderRadius: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 120, height: 14),
                SizedBox(height: 4),
                ShimmerBox(width: 80, height: 11),
              ],
            ),
          ),
          ShimmerBox(width: 60, height: 28, borderRadius: 14),
        ],
      ),
    );
  }
}

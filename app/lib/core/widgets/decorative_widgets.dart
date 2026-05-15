import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A gradient header banner for screen tops - similar to login screen style
class ScreenGradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Color>? gradientColors;
  final Widget? trailing;

  const ScreenGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.gradientColors,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        gradientColors ?? [const Color(0xFF5B53F6), const Color(0xFF21B5FF)];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              icon ?? Icons.auto_awesome,
              size: 80,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Decorative floating circles for backgrounds
class DecorativeBackground extends StatelessWidget {
  final Widget child;

  const DecorativeBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -40,
          right: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.04),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -40,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.04),
            ),
          ),
        ),
        Positioned(
          top: 200,
          left: -20,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.aiPurple.withValues(alpha: 0.03),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Enhanced card with subtle gradient border and shadow
class EnhancedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? accentColor;
  final bool showAccentLine;

  const EnhancedCard({
    super.key,
    required this.child,
    this.padding,
    this.accentColor,
    this.showAccentLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAccentLine)
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor ?? AppColors.primary,
                      (accentColor ?? AppColors.primary).withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
          ],
        ),
      ),
    );
  }
}

/// Animated entrance wrapper with staggered fade + slide
class StaggeredFadeSlide extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;

  const StaggeredFadeSlide({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 80),
  });

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.baseDelay * widget.index, () {
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
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Section title with optional accent dot
class SectionTitle extends StatelessWidget {
  final String title;
  final Color? dotColor;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.dotColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: dotColor ?? AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Subtle shimmer overlay for visual interest on static areas
class SubtleGlowDot extends StatefulWidget {
  final Color color;
  final double size;

  const SubtleGlowDot({
    super.key,
    this.color = AppColors.primary,
    this.size = 8,
  });

  @override
  State<SubtleGlowDot> createState() => _SubtleGlowDotState();
}

class _SubtleGlowDotState extends State<SubtleGlowDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(
              alpha: 0.4 + _controller.value * 0.4,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: 0.2 + _controller.value * 0.2,
                ),
                blurRadius: 4 + _controller.value * 4,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Mini stat card with icon and gradient background
class MiniStatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final List<Color>? gradientColors;

  const MiniStatBadge({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        gradientColors ??
        [
          AppColors.primary.withValues(alpha: 0.1),
          AppColors.primary.withValues(alpha: 0.05),
        ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

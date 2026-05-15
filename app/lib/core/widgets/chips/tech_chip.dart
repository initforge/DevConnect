import 'package:flutter/material.dart';

import 'package:devconnect/core/theme/app_colors.dart';
import 'package:devconnect/core/theme/app_spacing.dart';
import 'package:devconnect/core/widgets/animations/animated_card.dart'
    show PressableScale;

// Border radius constants (local — shared_widgets.dart re-exports these)
const double _kBorderRadiusMd = 12.0;
const double _kBorderRadiusXl = 20.0;

// ============================================================
// CHIPS & TAGS
// ============================================================

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
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(_kBorderRadiusXl),
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
          borderRadius: BorderRadius.circular(_kBorderRadiusMd),
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

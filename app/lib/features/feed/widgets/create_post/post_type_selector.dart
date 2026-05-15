import 'package:flutter/material.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_colors.dart';

/// A pill-shaped chip for selecting the post type.
class PostTypePill extends StatelessWidget {
  const PostTypePill({
    super.key,
    required this.type,
    required this.current,
    required this.label,
    required this.onTap,
  });

  final PostType type;
  final PostType current;
  final String label;
  final ValueChanged<PostType> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = type == current;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF5B53F6) : const Color(0xFFF4F6FA),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

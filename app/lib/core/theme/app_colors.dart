import 'package:flutter/material.dart';

/// DevConnect Design System — Colors
class AppColors {
  AppColors._();

  // ============================================================
  // PRIMARY COLORS
  // ============================================================

  // Primary — Showcase Purple
  static const primary = Color(0xFF5B53F6);
  static const primaryLight = Color(0xFF7C74FF);
  static const primaryDark = Color(0xFF4F46E5);
  static const primarySurface = Color(0xFFF3F0FF);

  // Accent — Teal / Mint
  static const accent = Color(0xFF00D9A6);
  static const accentLight = Color(0xFF34E8BE);
  static const accentSurface = Color(0xFFECFDF5);

  // AI Purple
  static const aiPurple = Color(0xFF8B5CF6);
  static const aiPurpleLight = Color(0xFFA78BFA);
  static const aiPurpleSurface = Color(0xFFF5F3FF);

  // ============================================================
  // SEMANTIC COLORS
  // ============================================================

  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const successSurface = Color(0xFFECFDF5);

  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const warningSurface = Color(0xFFFFFBEB);

  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const errorSurface = Color(0xFFFEF2F2);

  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFDBEAFE);
  static const infoSurface = Color(0xFFEFF6FF);

  // ============================================================
  // STATE COLORS (disabled, inactive, etc.)
  // ============================================================

  // Disabled states
  static const disabled = Color(0xFFCBD5E1);
  static const disabledText = Color(0xFF94A3B8);
  static const disabledBackground = Color(0xFFF1F5F9);

  // Inactive/placeholder states
  static const inactive = Color(0xFFE2E8F0);
  static const inactiveText = Color(0xFF64748B);

  // Divider & border colors
  static const divider = Color(0xFFE2E8F0);
  static const dividerLight = Color(0xFFF1F5F9);

  // Overlay
  static const overlay = Color(0x80000000);
  static const overlayLight = Color(0x1A000000);

  // ============================================================
  // LIGHT THEME — NEUTRALS
  // ============================================================

  static const background = Color(0xFFF8F9FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F3F9);
  static const border = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFF1F5F9);

  // Text colors
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);
  static const textDisabled = Color(0xFFCBD5E1);

  // ============================================================
  // DARK THEME — NEUTRALS
  // ============================================================

  static const darkBackground = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkSurfaceAlt = Color(0xFF334155);
  static const darkBorder = Color(0xFF475569);
  static const darkBorderLight = Color(0xFF334155);

  // Dark theme text colors
  static const darkTextPrimary = Color(0xFFF1F5F9);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextTertiary = Color(0xFF64748B);
  static const darkTextDisabled = Color(0xFF475569);

  // ============================================================
  // TAG COLORS
  // ============================================================

  static const tagBlue = Color(0xFFDBEAFE);
  static const tagGreen = Color(0xFFD1FAE5);
  static const tagPurple = Color(0xFFEDE9FE);
  static const tagOrange = Color(0xFFFEF3C7);
  static const tagRed = Color(0xFFFEE2E2);
  static const tagMint = Color(0xFFCCFBF1);
  static const tagPink = Color(0xFFFCE7F3);
  static const tagIndigo = Color(0xFFE0E7FF);

  // ============================================================
  // GRADIENTS
  // ============================================================

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF2563EB)],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFF00B894)],
  );

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [aiPurple, Color(0xFF6366F1)],
  );

  /// Profile hero gradient (profile_screen.dart cover).
  /// Defined here so it can be replaced without hunting scattered hardcodes.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7A74FF), Color(0xFFE46EA7)],
  );

  // ============================================================
  // SHADOW COLORS
  // ============================================================

  static const shadowColor = Color(0x1A000000);
  static const shadowColorDark = Color(0x40000000);
  static const shadowColorLight = Color(0x0D000000);

  // ============================================================
  // UTILITY FUNCTIONS
  // ============================================================

  /// Get surface color based on brightness
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : surface;
  }

  /// Get text color based on brightness
  static Color getTextColor(BuildContext context, {bool primary = true}) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return primary ? darkTextPrimary : darkTextSecondary;
    }
    return primary ? textPrimary : textSecondary;
  }

  /// Get disabled color
  static Color getDisabledColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextDisabled
        : disabled;
  }

  /// Get semantic color for notification types
  static Color getNotificationColor(String type) {
    switch (type) {
      case 'LIKE':
        return error;
      case 'COMMENT':
        return primary;
      case 'FOLLOW':
        return aiPurple;
      case 'MENTION':
        return accent;
      case 'BEST_ANSWER':
        return warning;
      default:
        return textSecondary;
    }
  }

  /// Get tag color based on tag name
  static Color getTagColor(String tag) {
    final tagLower = tag.toLowerCase();
    if (tagLower.contains('flutter') || tagLower.contains('dart')) {
      return const Color(0xFF0175C2);
    } else if (tagLower.contains('react') ||
        tagLower.contains('javascript') ||
        tagLower.contains('js')) {
      return const Color(0xFFF7DF1E);
    } else if (tagLower.contains('python')) {
      return const Color(0xFF3776AB);
    } else if (tagLower.contains('node') || tagLower.contains('backend')) {
      return const Color(0xFF339933);
    } else if (tagLower.contains('ai') ||
        tagLower.contains('ml') ||
        tagLower.contains('machine learning')) {
      return aiPurple;
    } else if (tagLower.contains('design') ||
        tagLower.contains('ui') ||
        tagLower.contains('ux')) {
      return tagPink;
    } else if (tagLower.contains('devops') ||
        tagLower.contains('docker') ||
        tagLower.contains('cloud')) {
      return const Color(0xFF2496ED);
    }
    return tagBlue;
  }
}

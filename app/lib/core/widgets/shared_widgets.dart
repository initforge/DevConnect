// Barrel file — re-exports all shared widgets.
// All existing imports of 'shared_widgets.dart' continue to work via this barrel.
import 'package:devconnect/core/theme/app_spacing.dart';

export 'shared_widgets/bottom_nav.dart';
export 'loading/shimmer_box.dart';
export 'empty/empty_state.dart';
export 'chips/tech_chip.dart';
export 'avatar/user_avatar.dart';
export 'animations/animated_card.dart';
export 'action_bar/post_action_bar.dart';

// ── Constants kept here for backward compatibility ────────────────────────────

const double kBorderRadiusSm = 8.0;
const double kBorderRadiusMd = 12.0;
const double kBorderRadiusLg = 16.0;
const double kBorderRadiusXl = 20.0;

// Deprecated: use AppSpacing.* instead
@Deprecated('Use AppSpacing.xs')
const double kSpacingXs = AppSpacing.xs;
@Deprecated('Use AppSpacing.sm')
const double kSpacingSm = AppSpacing.sm;
@Deprecated('Use AppSpacing.md')
const double kSpacingMd = AppSpacing.md;
@Deprecated('Use AppSpacing.lg')
const double kSpacingLg = AppSpacing.lg;
@Deprecated('Use AppSpacing.xl')
const double kSpacingXl = AppSpacing.xl;

const Duration kAnimationFast = Duration(milliseconds: 150);
const Duration kAnimationNormal = Duration(milliseconds: 300);
const Duration kAnimationSlow = Duration(milliseconds: 500);

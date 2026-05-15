import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Shows a confirmation dialog before blocking a user.
///
/// TODO: Wire to backend POST /users/me/blocks when endpoint is ready.
/// See plan/feature-08-block-report-real.md for full implementation.
Future<bool?> showBlockUserDialog(BuildContext context, String displayName) {
  return showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Block user'),
          content: Text(
            'Block $displayName? You will no longer see their posts or receive messages from them.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Block'),
            ),
          ],
        ),
  );
}

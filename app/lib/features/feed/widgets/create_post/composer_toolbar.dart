import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Bottom composer toolbar for the create post screen.
/// Contains formatting buttons (bold, italic, link, image, code, list)
/// and media insertion buttons (camera, image, GIF).
class ComposerToolbar extends StatelessWidget {
  const ComposerToolbar({
    super.key,
    required this.onBold,
    required this.onItalic,
    required this.onLink,
    required this.onCode,
    required this.onList,
    required this.onCamera,
    required this.onImage,
    required this.onGif,
  });

  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onLink;
  final VoidCallback onCode;
  final VoidCallback onList;
  final VoidCallback onCamera;
  final VoidCallback onImage;
  final VoidCallback onGif;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EAF2))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _ToolbarButton(
                  icon: Icons.format_bold,
                  tooltip: 'Bold',
                  onTap: onBold,
                ),
                _ToolbarButton(
                  icon: Icons.format_italic,
                  tooltip: 'Italic',
                  onTap: onItalic,
                ),
                _ToolbarButton(
                  icon: Icons.link,
                  tooltip: 'Link',
                  onTap: onLink,
                ),
                _ToolbarButton(
                  icon: Icons.image_outlined,
                  tooltip: 'Image',
                  onTap: onImage,
                ),
                _ToolbarButton(
                  icon: Icons.code,
                  tooltip: 'Code block',
                  onTap: onCode,
                ),
                _ToolbarButton(
                  icon: Icons.format_list_bulleted,
                  tooltip: 'List',
                  onTap: onList,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MediaButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Camera',
                  onTap: onCamera,
                ),
                const SizedBox(width: 8),
                _MediaButton(
                  icon: Icons.image_outlined,
                  label: 'Image',
                  onTap: onImage,
                ),
                const SizedBox(width: 8),
                _MediaButton(
                  icon: Icons.gif_box_outlined,
                  label: 'GIF',
                  onTap: onGif,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

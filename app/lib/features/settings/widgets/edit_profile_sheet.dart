import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/state/profile_refresh_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/user_repository.dart';

/// Modal bottom sheet for editing display name, bio, and skills.
///
/// Calls [onSave] after a successful save so the parent can react
/// (e.g. setState, invalidate provider).
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({
    super.key,
    required this.initialDisplayName,
    required this.initialBio,
    required this.initialSkills,
    required this.onSave,
  });

  final String initialDisplayName;
  final String initialBio;
  final String initialSkills;
  final VoidCallback onSave;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _userRepository = UserRepository();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _skillsCtrl;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialDisplayName);
    _bioCtrl = TextEditingController(text: widget.initialBio);
    _skillsCtrl = TextEditingController(text: widget.initialSkills);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final strings = AppStrings.current();
    final displayName = _nameCtrl.text.trim();
    if (displayName.isEmpty) {
      setState(() => _error = strings.t('settings.displayNameRequired'));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _userRepository.updateCurrentUser(
        displayName: displayName,
        bio: _bioCtrl.text.trim(),
        skills:
            _skillsCtrl.text
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .take(8)
                .toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ProfileRefreshBus.instance.refresh();
      widget.onSave();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      labelText: hint,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.current();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.t('settings.editProfile'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            strings.t('settings.editProfileSubtitle'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: _inputDecoration(strings.t('settings.displayName')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bioCtrl,
            minLines: 3,
            maxLines: 4,
            decoration: _inputDecoration(strings.t('settings.shortBio')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _skillsCtrl,
            decoration: _inputDecoration(strings.t('settings.skillsComma')),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child:
                  _saving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                      : Text(strings.t('settings.saveProfile')),
            ),
          ),
        ],
      ),
    );
  }
}

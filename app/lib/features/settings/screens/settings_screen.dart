import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/riverpod/providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/user_repository.dart';

part 'settings_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _userRepository = UserRepository();
  String _profileVisibility =
      AppPreferences.instance.privateProfile ? 'Private' : 'Public';
  bool _onlineStatus = AppPreferences.instance.onlineStatus;
  bool _pushNotifications = AppPreferences.instance.pushNotif;
  bool _emailNotifications = AppPreferences.instance.emailNotif;
  String _messagePermission = AppPreferences.instance.messagePermission;
  String _quietHours = AppPreferences.instance.quietHours;
  String _fontSize = AppPreferences.instance.fontSize;
  String _language = AppPreferences.instance.language;

  Future<void> _openEditProfile() async {
    final user = AppPreferences.instance.user ?? const <String, dynamic>{};
    final nameCtrl = TextEditingController(
      text: user['displayName']?.toString() ?? '',
    );
    final bioCtrl = TextEditingController(text: user['bio']?.toString() ?? '');
    final skillsCtrl = TextEditingController(
      text: ((user['skills'] as List?) ?? const [])
          .map((item) => item.toString())
          .join(', '),
    );
    String? error;
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> save() async {
              final displayName = nameCtrl.text.trim();
              if (displayName.isEmpty) {
                setSheetState(() => error = 'Display name is required');
                return;
              }

              setSheetState(() {
                saving = true;
                error = null;
              });

              try {
                await _userRepository.updateCurrentUser(
                  displayName: displayName,
                  bio: bioCtrl.text.trim(),
                  skills:
                      skillsCtrl.text
                          .split(',')
                          .map((item) => item.trim())
                          .where((item) => item.isNotEmpty)
                          .take(8)
                          .toList(),
                );
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated')),
                );
                setState(() {});
              } catch (e) {
                setSheetState(() {
                  saving = false;
                  error = e.toString();
                });
              }
            }

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
                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Update the basics people see on your profile.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: _sheetInputDecoration('Display name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioCtrl,
                    minLines: 3,
                    maxLines: 4,
                    decoration: _sheetInputDecoration('Short bio'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: skillsCtrl,
                    decoration: _sheetInputDecoration(
                      'Skills (comma separated)',
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: saving ? null : save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child:
                          saving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Save profile'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    bioCtrl.dispose();
    skillsCtrl.dispose();
  }

  Future<void> _openChangePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              if (newCtrl.text.length < 8) {
                setSheetState(
                  () => error = 'New password must be at least 8 characters',
                );
                return;
              }
              if (newCtrl.text != confirmCtrl.text) {
                setSheetState(() => error = 'Passwords do not match');
                return;
              }

              setSheetState(() {
                saving = true;
                error = null;
              });

              try {
                await ApiService.instance.post('/auth/change-password', {
                  'currentPassword': currentCtrl.text,
                  'newPassword': newCtrl.text,
                });
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed')),
                );
              } catch (e) {
                setSheetState(() {
                  saving = false;
                  error = e.toString();
                });
              }
            }

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
                  const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: currentCtrl,
                    obscureText: true,
                    decoration: _sheetInputDecoration('Current password'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: _sheetInputDecoration('New password'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: _sheetInputDecoration('Confirm new password'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: saving ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child:
                          saving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Update password'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This removes your account from the current device and backend demo data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _userRepository.deleteCurrentUser();
      await AppPreferences.instance.clearAuth();
      ApiService.instance.setToken(null);
      if (!mounted) return;
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showTerms() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Terms of Service',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 12),
              Text(
                'DevConnect is provided for collaboration, discovery, and educational sharing. Keep account credentials secure, avoid abusive automation, and only publish content you are allowed to share.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'By continuing to use the app, you agree that moderation actions, account removal, and content visibility may be applied to keep the platform healthy.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickSetting({
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ...options.map(
                (option) => RadioListTile<String>(
                  value: option,
                  groupValue: currentValue,
                  activeColor: AppColors.primary,
                  title: Text(option),
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      onSelected(selected);
    }
  }

  InputDecoration _sheetInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF4F6FA),
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
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      bottomNavigationBar: AppBottomNavBar(
        items: [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            route: AppRoutes.home,
          ),
          AppBottomNavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: 'Explore',
            route: AppRoutes.explore,
          ),
          AppBottomNavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Settings',
            route: AppRoutes.settings,
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            route: AppRoutes.profile,
          ),
        ],
        selectedIndex: 2,
        currentRoute: AppRoutes.settings,
        centerCreate: true,
      ),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
        children: [
          _SectionCard(
            title: 'ACCOUNT',
            children: [
              _ArrowRow(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: _openEditProfile,
              ),
              _ArrowRow(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: _openChangePassword,
              ),
              _StatusRow(
                icon: Icons.code,
                title: 'GitHub Integration',
                status: 'Connected',
                statusColor: AppColors.success,
              ),
              _ArrowRow(
                icon: Icons.delete_outline,
                title: 'Delete Account',
                titleColor: AppColors.error,
                onTap: _deleteAccount,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'PRIVACY',
            children: [
              _ValueRow(
                icon: Icons.visibility_outlined,
                title: 'Profile Visibility',
                value: _profileVisibility,
                onTap:
                    () => _pickSetting(
                      title: 'Profile Visibility',
                      options: const ['Public', 'Private'],
                      currentValue: _profileVisibility,
                      onSelected: (value) async {
                        setState(() => _profileVisibility = value);
                        await AppPreferences.instance.setPrivateProfile(
                          value == 'Private',
                        );
                      },
                    ),
              ),
              _SwitchRow(
                icon: Icons.toggle_on_outlined,
                title: 'Online Status',
                value: _onlineStatus,
                onChanged: (value) async {
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() => _onlineStatus = value);
                  await AppPreferences.instance.setOnlineStatus(value);
                  try {
                    await _userRepository.updateOnlineStatus(value);
                  } catch (_) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Saved locally. Sync will retry later.'),
                      ),
                    );
                  }
                },
              ),
              _ValueRow(
                icon: Icons.mail_outline,
                title: 'Who Can Message',
                value: _messagePermission,
                onTap:
                    () => _pickSetting(
                      title: 'Who Can Message',
                      options: const ['Everyone', 'Followers', 'Nobody'],
                      currentValue: _messagePermission,
                      onSelected: (value) async {
                        setState(() => _messagePermission = value);
                        await AppPreferences.instance.setMessagePermission(
                          value,
                        );
                      },
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'NOTIFICATIONS',
            children: [
              _SwitchRow(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                value: _pushNotifications,
                onChanged: (value) async {
                  setState(() => _pushNotifications = value);
                  await AppPreferences.instance.setPushNotif(value);
                },
              ),
              _SwitchRow(
                icon: Icons.email_outlined,
                title: 'Email Notifications',
                value: _emailNotifications,
                onChanged: (value) async {
                  setState(() => _emailNotifications = value);
                  await AppPreferences.instance.setEmailNotif(value);
                },
              ),
              _ValueRow(
                icon: Icons.nightlight_round,
                title: 'Quiet Hours',
                value: _quietHours,
                onTap:
                    () => _pickSetting(
                      title: 'Quiet Hours',
                      options: const [
                        'Off',
                        '10 PM - 8 AM',
                        '11 PM - 7 AM',
                        '12 AM - 8 AM',
                      ],
                      currentValue: _quietHours,
                      onSelected: (value) async {
                        setState(() => _quietHours = value);
                        await AppPreferences.instance.setQuietHours(value);
                      },
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'APPEARANCE',
            children: [
              _ValueRow(
                icon: Icons.palette_outlined,
                title: 'Theme',
                value: themeMode == ThemeMode.dark ? 'Dark' : 'Light',
                onTap: () => themeNotifier.toggleTheme(),
              ),
              _ValueRow(
                icon: Icons.text_fields_outlined,
                title: 'Font Size',
                value: _fontSize,
                onTap:
                    () => _pickSetting(
                      title: 'Font Size',
                      options: const ['Small', 'Medium', 'Large'],
                      currentValue: _fontSize,
                      onSelected: (value) async {
                        setState(() => _fontSize = value);
                        await AppPreferences.instance.setFontSize(value);
                      },
                    ),
              ),
              _ValueRow(
                icon: Icons.language_outlined,
                title: 'Language',
                value: _language,
                onTap:
                    () => _pickSetting(
                      title: 'Language',
                      options: const ['English', 'Vietnamese'],
                      currentValue: _language,
                      onSelected: (value) async {
                        setState(() => _language = value);
                        await AppPreferences.instance.setLanguage(value);
                      },
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'ABOUT',
            children: [
              const _ValueRow(
                icon: Icons.info_outline,
                title: 'Version',
                value: 'v1.0.0',
              ),
              _ArrowRow(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: _showTerms,
              ),
              _ArrowRow(
                icon: Icons.logout,
                title: 'Log Out',
                titleColor: AppColors.error,
                onTap: () async {
                  await AppPreferences.instance.clearAuth();
                  ApiService.instance.setToken(null);
                  if (!context.mounted) return;
                  context.go(AppRoutes.login);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/riverpod/providers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/services/oauth_redirect.dart';
import '../../../core/state/profile_refresh_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/decorative_widgets.dart';
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
  bool _privateProfile = AppPreferences.instance.privateProfile;
  bool _onlineStatus = AppPreferences.instance.onlineStatus;
  bool _pushNotifications = AppPreferences.instance.pushNotif;
  bool _emailNotifications = AppPreferences.instance.emailNotif;
  String _messagePermission = AppPreferences.instance.messagePermission;
  String _quietHours = AppPreferences.instance.quietHours;
  bool _githubConnected = false;

  @override
  void initState() {
    super.initState();
    _loadRemoteSettings();
  }

  Future<void> _loadRemoteSettings() async {
    try {
      final remote = await ApiService.instance.getObject('/users/me/settings');
      final language = remote['language'];
      if (language == 'en' || language == 'vi') {
        await ref.read(appLocaleProvider.notifier).setLocale(Locale(language));
      }
      if (!mounted) return;
      setState(() {
        _privateProfile = remote['privateProfile'] == true;
        _githubConnected = remote['githubConnected'] == true;
        final onlineStatus = remote['onlineStatus'];
        if (onlineStatus is bool) {
          _onlineStatus = onlineStatus;
        }
        final pushNotifications = remote['pushNotifications'];
        if (pushNotifications is bool) {
          _pushNotifications = pushNotifications;
        }
        final emailNotifications = remote['emailNotifications'];
        if (emailNotifications is bool) {
          _emailNotifications = emailNotifications;
        }
        final messagePermission = remote['messagePermission'];
        if (messagePermission is String && messagePermission.isNotEmpty) {
          _messagePermission = messagePermission;
        }
        final quietHours = remote['quietHours'];
        if (quietHours is String && quietHours.isNotEmpty) {
          _quietHours = quietHours;
        }
      });
    } catch (_) {}
  }

  Future<void> _saveRemoteSettings(Map<String, dynamic> data) async {
    try {
      await ApiService.instance.patch('/users/me/settings', data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    }
  }

  String _friendlyError(Object error) {
    if (error is AppException) return AppStrings.current().t(error.messageKey);
    return error.toString();
  }

  Future<void> _openEditProfile() async {
    final strings = AppStrings.current();
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> save() async {
              final displayName = nameCtrl.text.trim();
              if (displayName.isEmpty) {
                setSheetState(
                  () => error = strings.t('settings.displayNameRequired'),
                );
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
                  SnackBar(content: Text(strings.t('settings.profileUpdated'))),
                );
                ProfileRefreshBus.instance.refresh();
                setState(() {});
              } catch (e) {
                setSheetState(() {
                  saving = false;
                  error = _friendlyError(e);
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
                  Text(
                    strings.t('settings.editProfile'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
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
                    controller: nameCtrl,
                    decoration: _sheetInputDecoration(
                      strings.t('settings.displayName'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioCtrl,
                    minLines: 3,
                    maxLines: 4,
                    decoration: _sheetInputDecoration(
                      strings.t('settings.shortBio'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: skillsCtrl,
                    decoration: _sheetInputDecoration(
                      strings.t('settings.skillsComma'),
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
                              : Text(strings.t('settings.saveProfile')),
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
    final strings = AppStrings.current();
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              if (newCtrl.text.length < 8) {
                setSheetState(
                  () => error = strings.t('settings.newPasswordTooShort'),
                );
                return;
              }
              if (newCtrl.text != confirmCtrl.text) {
                setSheetState(
                  () => error = strings.t('settings.passwordsDoNotMatch'),
                );
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
                  SnackBar(
                    content: Text(strings.t('settings.passwordChanged')),
                  ),
                );
              } catch (e) {
                setSheetState(() {
                  saving = false;
                  error = _friendlyError(e);
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
                  Text(
                    strings.t('settings.changePassword'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: currentCtrl,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.password],
                    decoration: _sheetInputDecoration(
                      strings.t('settings.currentPassword'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newCtrl,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: _sheetInputDecoration(
                      strings.t('settings.newPassword'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: _sheetInputDecoration(
                      strings.t('settings.confirmNewPassword'),
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
                              : Text(strings.t('settings.updatePassword')),
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
    final strings = AppStrings.current();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.t('settings.deleteAccountTitle')),
          content: Text(strings.t('settings.deleteAccountBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.t('common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                strings.t('settings.delete'),
                style: const TextStyle(color: AppColors.error),
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
      ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    }
  }

  void _connectGithub() {
    try {
      redirectToExternalUrl('${AppConstants.apiBaseUrl}/auth/github');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.current().t('settings.githubWebOnly')),
        ),
      );
    }
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
    final strings = AppStrings.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(appLocaleProvider);
    final themeNotifier = ref.read(themeModeNotifierProvider.notifier);
    final publicLabel = strings.t('common.public');
    final privateLabel = strings.t('common.private');
    final everyoneLabel = strings.t('common.everyone');
    final followersLabel = strings.t('common.followers');
    final nobodyLabel = strings.t('common.nobody');
    final offLabel = strings.t('common.off');
    final profileVisibilityValue = _privateProfile ? privateLabel : publicLabel;
    final messagePermissionValue =
        _messagePermission == 'Followers'
            ? followersLabel
            : _messagePermission == 'Nobody'
            ? nobodyLabel
            : everyoneLabel;
    final quietHoursValue = _quietHours == 'Off' ? offLabel : _quietHours;
    final englishLabel = strings.t('settings.languageEnglish');
    final vietnameseLabel = strings.t('settings.languageVietnamese');
    final languageValue =
        locale.languageCode == 'vi' ? vietnameseLabel : englishLabel;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: AppBottomNavBar(
        items: [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: strings.nav('home'),
            route: AppRoutes.home,
          ),
          AppBottomNavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: strings.nav('explore'),
            route: AppRoutes.explore,
          ),
          AppBottomNavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: strings.nav('settings'),
            route: AppRoutes.settings,
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: strings.nav('profile'),
            route: AppRoutes.profile,
          ),
        ],
        selectedIndex: 2,
        currentRoute: AppRoutes.settings,
        centerCreate: true,
      ),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.06),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: Text(
          strings.t('settings.title'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: DecorativeBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
          children: [
            ScreenGradientHeader(
              title: strings.t('settings.title'),
              subtitle: strings.t('settings.subtitle'),
              icon: Icons.settings_outlined,
              gradientColors: const [Color(0xFF5B53F6), Color(0xFF8B5CF6)],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: strings.t('settings.account'),
              children: [
                _ArrowRow(
                  icon: Icons.person_outline,
                  title: strings.t('settings.editProfile'),
                  onTap: () => context.go(AppRoutes.profile),
                ),
                _ArrowRow(
                  icon: Icons.lock_outline,
                  title: strings.t('settings.changePassword'),
                  onTap: _openChangePassword,
                ),
                _StatusRow(
                  icon: Icons.code,
                  title: strings.t('settings.githubIntegration'),
                  status:
                      _githubConnected
                          ? strings.t('settings.connected')
                          : strings.t('settings.notLinked'),
                  statusColor:
                      _githubConnected
                          ? AppColors.success
                          : AppColors.textTertiary,
                  onTap: _githubConnected ? null : _connectGithub,
                ),
                _ArrowRow(
                  icon: Icons.delete_outline,
                  title: strings.t('settings.deleteAccount'),
                  titleColor: AppColors.error,
                  onTap: _deleteAccount,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: strings.t('settings.privacy'),
              children: [
                _ValueRow(
                  icon: Icons.visibility_outlined,
                  title: strings.t('settings.profileVisibility'),
                  value: profileVisibilityValue,
                  onTap:
                      () => _pickSetting(
                        title: strings.t('settings.profileVisibilityTitle'),
                        options: [publicLabel, privateLabel],
                        currentValue: profileVisibilityValue,
                        onSelected: (value) async {
                          final isPrivate = value == privateLabel;
                          setState(() => _privateProfile = isPrivate);
                          await AppPreferences.instance.setPrivateProfile(
                            isPrivate,
                          );
                          await _saveRemoteSettings({
                            'privateProfile': isPrivate,
                          });
                        },
                      ),
                ),
                _SwitchRow(
                  icon: Icons.toggle_on_outlined,
                  title: strings.t('settings.onlineStatus'),
                  value: _onlineStatus,
                  onChanged: (value) async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _onlineStatus = value);
                    await AppPreferences.instance.setOnlineStatus(value);
                    await _saveRemoteSettings({'onlineStatus': value});
                    try {
                      await _userRepository.updateOnlineStatus(value);
                    } catch (_) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            strings.t('settings.savedLocallySyncLater'),
                          ),
                        ),
                      );
                    }
                  },
                ),
                _ValueRow(
                  icon: Icons.mail_outline,
                  title: strings.t('settings.whoCanMessage'),
                  value: messagePermissionValue,
                  onTap:
                      () => _pickSetting(
                        title: strings.t('settings.whoCanMessageTitle'),
                        options: [everyoneLabel, followersLabel, nobodyLabel],
                        currentValue: messagePermissionValue,
                        onSelected: (value) async {
                          final rawValue =
                              value == followersLabel
                                  ? 'Followers'
                                  : value == nobodyLabel
                                  ? 'Nobody'
                                  : 'Everyone';
                          setState(() => _messagePermission = rawValue);
                          await AppPreferences.instance.setMessagePermission(
                            rawValue,
                          );
                          await _saveRemoteSettings({
                            'messagePermission': rawValue,
                          });
                        },
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: strings.t('settings.notifications'),
              children: [
                _SwitchRow(
                  icon: Icons.notifications_outlined,
                  title: strings.t('settings.pushNotifications'),
                  value: _pushNotifications,
                  onChanged: (value) async {
                    setState(() => _pushNotifications = value);
                    await AppPreferences.instance.setPushNotif(value);
                    await _saveRemoteSettings({'pushNotifications': value});
                  },
                ),
                _SwitchRow(
                  icon: Icons.email_outlined,
                  title: strings.t('settings.emailNotifications'),
                  value: _emailNotifications,
                  onChanged: (value) async {
                    setState(() => _emailNotifications = value);
                    await AppPreferences.instance.setEmailNotif(value);
                    await _saveRemoteSettings({'emailNotifications': value});
                  },
                ),
                _ValueRow(
                  icon: Icons.nightlight_round,
                  title: strings.t('settings.quietHours'),
                  value: quietHoursValue,
                  onTap:
                      () => _pickSetting(
                        title: strings.t('settings.quietHoursTitle'),
                        options: [
                          offLabel,
                          '10 PM - 8 AM',
                          '11 PM - 7 AM',
                          '12 AM - 8 AM',
                        ],
                        currentValue: quietHoursValue,
                        onSelected: (value) async {
                          final rawValue = value == offLabel ? 'Off' : value;
                          setState(() => _quietHours = rawValue);
                          await AppPreferences.instance.setQuietHours(rawValue);
                          await _saveRemoteSettings({'quietHours': rawValue});
                        },
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: strings.t('settings.appearance'),
              children: [
                _ValueRow(
                  icon: Icons.palette_outlined,
                  title: strings.t('settings.theme'),
                  value:
                      themeMode == ThemeMode.dark
                          ? strings.t('common.dark')
                          : strings.t('common.light'),
                  onTap: () => themeNotifier.toggleTheme(),
                ),
                _ValueRow(
                  icon: Icons.language_outlined,
                  title: strings.t('settings.language'),
                  value: languageValue,
                  onTap:
                      () => _pickSetting(
                        title: strings.t('settings.language'),
                        options: [englishLabel, vietnameseLabel],
                        currentValue: languageValue,
                        onSelected: (value) async {
                          final nextCode =
                              value == vietnameseLabel ? 'vi' : 'en';
                          await ref
                              .read(appLocaleProvider.notifier)
                              .setLocale(Locale(nextCode));
                          await _saveRemoteSettings({'language': nextCode});
                        },
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: strings.t('settings.about'),
              children: [
                _ValueRow(
                  icon: Icons.info_outline,
                  title: strings.t('settings.version'),
                  value: 'v1.0.0',
                ),
                _ArrowRow(
                  icon: Icons.logout,
                  title: strings.t('settings.logout'),
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/services/api_service.dart';
import '../../../core/riverpod/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          const _SectionHeader('Tài khoản'),
          _SettingTile(
            Icons.person_outline,
            'Chỉnh sửa hồ sơ',
            onTap: () => _showInfo(context, 'Luồng chỉnh sửa hồ sơ sẽ hoàn thiện ở phase sau'),
          ),
          _SettingTile(
            Icons.lock_outline,
            'Đổi mật khẩu',
            onTap: () => _showInfo(context, 'Đổi mật khẩu cần backend xác thực ở phase sau'),
          ),
          _SettingTile(
            Icons.email_outlined,
            'Email: minh@dev.com',
            onTap: () => _showInfo(context, 'Cập nhật email sẽ hoàn thiện ở phase sau'),
          ),
          _SettingTile(
            Icons.code,
            'Liên kết GitHub',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Đã liên kết',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const _SectionHeader('Giao diện'),
          SwitchListTile(
            value: themeMode == ThemeMode.dark,
            onChanged: (value) => themeNotifier.toggleTheme(),
            title: const Text('Chế độ tối'),
            secondary: const Icon(Icons.dark_mode_outlined),
            activeColor: AppColors.primary,
          ),
          const _SectionHeader('Thông báo'),
          SwitchListTile(
            value: AppPreferences.instance.pushNotif,
            onChanged: (value) async {
              await AppPreferences.instance.setPushNotif(value);
            },
            title: const Text('Thông báo đẩy'),
            secondary: const Icon(Icons.notifications_outlined),
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            value: AppPreferences.instance.emailNotif,
            onChanged: (value) async {
              await AppPreferences.instance.setEmailNotif(value);
            },
            title: const Text('Thông báo email'),
            secondary: const Icon(Icons.email_outlined),
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            value: AppPreferences.instance.soundEnabled,
            onChanged: (value) async {
              await AppPreferences.instance.setSoundEnabled(value);
            },
            title: const Text('Âm thanh'),
            secondary: const Icon(Icons.volume_up_outlined),
            activeColor: AppColors.primary,
          ),
          const _SectionHeader('Quyền riêng tư'),
          SwitchListTile(
            value: AppPreferences.instance.privateProfile,
            onChanged: (value) async {
              await AppPreferences.instance.setPrivateProfile(value);
            },
            title: const Text('Hồ sơ riêng tư'),
            secondary: const Icon(Icons.visibility_off_outlined),
            activeColor: AppColors.primary,
          ),
          _SettingTile(
            Icons.block,
            'Danh sách chặn',
            onTap: () => _showInfo(context, 'Danh sách chặn hiện chưa có dữ liệu local'),
          ),
          const _SectionHeader('Khác'),
          _SettingTile(
            Icons.help_outline,
            'Trợ giúp & Phản hồi',
            onTap: () => _showInfo(context, 'Kênh phản hồi sẽ nối dịch vụ hỗ trợ ở phase sau'),
          ),
          _SettingTile(
            Icons.info_outline,
            'Phiên bản 1.0.0',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Mới nhất',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ),
          ),
          _SettingTile(
            Icons.description_outlined,
            'Điều khoản sử dụng',
            onTap: () => _showInfo(context, 'Điều khoản sử dụng DevConnect v1.0'),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await AppPreferences.instance.clearAuth();
                ApiService.instance.setToken(null);
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                'Đăng xuất',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile(this.icon, this.title, {this.onTap, this.trailing});

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing:
          trailing ??
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.textTertiary,
          ),
      onTap: onTap,
    );
  }
}

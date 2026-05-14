import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/app_preferences.dart';

class OAuthCallbackScreen extends StatefulWidget {
  const OAuthCallbackScreen({super.key});

  @override
  State<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends State<OAuthCallbackScreen> {
  String? _error;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _completeSignIn();
  }

  Future<void> _completeSignIn() async {
    final uri = GoRouterState.of(context).uri;
    final token = uri.queryParameters['token'];
    final refreshToken = uri.queryParameters['refresh_token'];

    if (token == null || token.isEmpty) {
      setState(() => _error = 'Missing GitHub OAuth token.');
      return;
    }

    try {
      await AppPreferences.instance.saveToken(token);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await AppPreferences.instance.saveRefreshToken(refreshToken);
      }
      ApiService.instance.setToken(token);

      final user = await ApiService.instance.getObject('/users/me');
      await AppPreferences.instance.saveUser(user);
      await _syncOnboardingState(user);

      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _syncOnboardingState(Map<String, dynamic> user) async {
    try {
      final settings = await ApiService.instance.getObject(
        '/users/me/settings',
      );
      final remoteCompleted = settings['onboardingCompleted'];
      if (remoteCompleted is bool) {
        await AppPreferences.instance.setOnboardingCompleted(remoteCompleted);
        return;
      }
    } catch (_) {}

    final skills = user['skills'];
    final hasSkills =
        (skills is List && skills.isNotEmpty) ||
        (skills is String && skills.trim().isNotEmpty);
    await AppPreferences.instance.setOnboardingCompleted(hasSkills);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Back to login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

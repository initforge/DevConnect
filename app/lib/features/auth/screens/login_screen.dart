import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/services/oauth_redirect.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isFormValid = false;
  String? _errorMessage;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.instance.post('/auth/login', {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });

      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;

      await AppPreferences.instance.saveToken(token);
      await AppPreferences.instance.saveUser(user);
      ApiService.instance.setToken(token);
      await _syncOnboardingState(user);

      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  Future<void> _handleGitHubLogin() async {
    unawaited(HapticFeedback.lightImpact());
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      redirectToExternalUrl('${AppConstants.apiBaseUrl}/auth/github');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'GitHub OAuth is only available through the backend redirect.';
      });
    }
  }

  Future<void> _handleGoogleLogin() async {
    unawaited(HapticFeedback.lightImpact());
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      redirectToExternalUrl('${AppConstants.apiBaseUrl}/auth/google');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Google OAuth is only available through the backend redirect.';
      });
    }
  }

  String _friendlyError(Object e) {
    if (e is AppException) return AppStrings.current().t(e.messageKey);
    return AppStrings.current().t('errors.generic');
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

  Future<void> _openForgotPasswordSheet() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    bool submitting = false;
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                setSheetState(() => error = 'Enter a valid email address');
                return;
              }

              setSheetState(() {
                submitting = true;
                error = null;
              });

              try {
                await ApiService.instance.post('/auth/forgot-password', {
                  'email': email,
                });
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'If your account exists, recovery instructions are on the way.',
                    ),
                  ),
                );
              } catch (e) {
                setSheetState(() {
                  submitting = false;
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
                  const Text(
                    'Reset password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the email you use for DevConnect. We will start the recovery flow for that account.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
                    decoration: _fieldDecoration(
                      hint: 'Email Address',
                      prefix: Icons.email_outlined,
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
                      onPressed: submitting ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child:
                          submitting
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Send recovery instructions'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    emailCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5B53F6), Color(0xFF7657F7), Color(0xFFE447A8)],
            stops: [0, 0.28, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildLogo(),
                      const SizedBox(height: 132),
                      _buildLoginPanel(),
                      const SizedBox(height: 22),
                      _buildDivider(),
                      const SizedBox(height: 22),
                      _buildGitHubButton(),
                      const SizedBox(height: 12),
                      _buildGoogleButton(),
                      const SizedBox(height: 24),
                      _buildRegisterLink(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 180,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 18,
            child: Icon(
              Icons.code,
              size: 82,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            right: 18,
            child: Transform.flip(
              flipX: true,
              child: Icon(
                Icons.code,
                size: 82,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.code, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPanel() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        onChanged: () {
          final valid = _formKey.currentState?.validate() ?? false;
          if (valid != _isFormValid) setState(() => _isFormValid = valid);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'DevConnect',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Connect with developers worldwide',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: _fieldDecoration(
                hint: 'Email Address',
                prefix: Icons.email_outlined,
              ),
              validator: (value) {
                final key = Validators.email(value);
                if (key == null) return null;
                return AppStrings.of(context).t(key);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: _fieldDecoration(
                hint: 'Password',
                prefix: Icons.lock_outline,
                suffix: IconButton(
                  onPressed:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              validator: (value) {
                final key = Validators.password(value);
                if (key == null) return null;
                return AppStrings.of(context).t(key);
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _openForgotPasswordSheet,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5B53F6)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: (_isLoading || !_isFormValid) ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textTertiary),
      prefixIcon: Icon(prefix, size: 20, color: AppColors.textTertiary),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE7EAF2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF5B53F6), width: 1.5),
      ),
    );
  }

  Widget _buildDivider() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          const Expanded(
            child: Divider(indent: 28, endIndent: 12, color: Color(0xFFE7EAF2)),
          ),
          Text(
            'OR',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Expanded(
            child: Divider(indent: 12, endIndent: 28, color: Color(0xFFE7EAF2)),
          ),
        ],
      ),
    );
  }

  Widget _buildGitHubButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SizedBox(
        height: 50,
        child: OutlinedButton.icon(
          onPressed: _isLoading ? null : _handleGitHubLogin,
          icon: const Icon(Icons.code, size: 18, color: Colors.black87),
          label: const Text('Continue with GitHub'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF111827), width: 1.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SizedBox(
        height: 50,
        child: OutlinedButton.icon(
          onPressed: _isLoading ? null : _handleGoogleLogin,
          icon: const Icon(Icons.g_mobiledata, size: 22, color: Colors.red),
          label: const Text('Continue with Google'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFDD4B39), width: 1.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        GestureDetector(
          onTap: () {
            unawaited(HapticFeedback.selectionClick());
            context.push(AppRoutes.register);
          },
          child: Text(
            'Sign up',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/decorative_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  int _step = 0;
  bool _obscure = true;
  bool _isLoading = false;
  String? _errorMessage;
  double _passwordStrength = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _calcStrength(String value) {
    setState(() => _passwordStrength = Validators.passwordStrength(value));
  }

  String _friendlyError(Object e) {
    if (e is AppException) return AppStrings.current().t(e.messageKey);
    return AppStrings.current().t('errors.generic');
  }

  Color get _strengthColor {
    if (_passwordStrength <= 0.25) return AppColors.error;
    if (_passwordStrength <= 0.50) return AppColors.warning;
    if (_passwordStrength <= 0.75) return AppColors.primary;
    return AppColors.success;
  }

  String get _strengthText {
    if (_passwordStrength <= 0.25) return 'Weak password';
    if (_passwordStrength <= 0.50) return 'Average password';
    if (_passwordStrength <= 0.75) return 'Good password';
    return 'Strong password';
  }

  Future<void> _nextStep() async {
    if (_step == 0) {
      // Validate all fields before proceeding
      final nameKey = Validators.notEmpty(_nameCtrl.text);
      final usernameKey = Validators.username(_usernameCtrl.text);
      final emailKey = Validators.email(_emailCtrl.text);
      if (nameKey != null || usernameKey != null || emailKey != null) {
        final strings = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nameKey != null
                  ? strings.t(nameKey)
                  : usernameKey != null
                  ? strings.t(usernameKey)
                  : strings.t(emailKey!),
            ),
          ),
        );
        return;
      }
      HapticFeedback.selectionClick();
      setState(() => _step = 1);
      return;
    }

    if (_passwordCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.of(context).t('validators.passwordTooShort'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.instance.post('/auth/register', {
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'username': _usernameCtrl.text.trim(),
        'displayName': _nameCtrl.text.trim(),
      });

      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;

      await AppPreferences.instance.saveToken(token);
      await AppPreferences.instance.saveUser(user);
      ApiService.instance.setToken(token);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = 2;
      });

      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) context.go(AppRoutes.onboarding);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: DecorativeBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 10, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed:
                          _step == 0
                              ? () => context.pop()
                              : () => setState(() => _step -= 1),
                      icon: const Icon(Icons.arrow_back, size: 20),
                    ),
                    Expanded(
                      child: Text(
                        _step == 2 ? 'Account Created' : 'Create Account',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _ProgressDots(currentStep: _step),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildStepBody(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    if (_step == 0) {
      return _RegisterCard(
        key: const ValueKey('step-1'),
        title: 'Join DevConnect',
        subtitle: 'Start your developer journey',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldLabel('Full Name'),
            _RoundedField(
              controller: _nameCtrl,
              hint: 'Enter your full name',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _FieldLabel('Username'),
            _RoundedField(
              controller: _usernameCtrl,
              hint: '@ john_dev',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _FieldLabel('Email Address'),
            _RoundedField(
              controller: _emailCtrl,
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 8),
            _PrimaryPillButton(
              label: 'Continue',
              trailingIcon: Icons.arrow_forward,
              onPressed: _nextStep,
            ),
            const SizedBox(height: 20),
            _FooterLink(
              leading: 'Already have an account? ',
              action: 'Sign In',
              onTap: () => context.go(AppRoutes.login),
            ),
          ],
        ),
      );
    }

    if (_step == 1) {
      return _RegisterCard(
        key: const ValueKey('step-2'),
        title: 'Secure your account',
        subtitle: 'Choose a password to protect your profile',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldLabel('Password'),
            _RoundedField(
              controller: _passwordCtrl,
              hint: 'Enter a secure password',
              obscureText: _obscure,
              onChanged: _calcStrength,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _passwordStrength,
                minHeight: 4,
                backgroundColor: const Color(0xFFE9EDF5),
                color: _strengthColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _strengthText,
              style: TextStyle(
                fontSize: 12,
                color: _strengthColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _PasswordRequirement(
              label: '8+ characters',
              met: _passwordCtrl.text.length >= 8,
            ),
            _PasswordRequirement(
              label: 'Uppercase letter',
              met: RegExp(r'[A-Z]').hasMatch(_passwordCtrl.text),
            ),
            _PasswordRequirement(
              label: 'Number',
              met: RegExp(r'[0-9]').hasMatch(_passwordCtrl.text),
            ),
            _PasswordRequirement(
              label: 'Special character',
              met: RegExp(
                r'[!@#$%^&*(),.?":{}|<>]',
              ).hasMatch(_passwordCtrl.text),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 22),
            _PrimaryPillButton(
              label: _isLoading ? 'Creating account...' : 'Create Account',
              onPressed: _isLoading ? null : _nextStep,
              busy: _isLoading,
            ),
          ],
        ),
      );
    }

    return _RegisterCard(
      key: const ValueKey('step-3'),
      title: 'Welcome aboard',
      subtitle: 'Preparing your personalized onboarding flow',
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 74,
            height: 74,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF10B981),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 20),
          const Text(
            'Account created successfully',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Redirecting you to onboarding...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final selected = index == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 14 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF5B53F6) : const Color(0xFFD5DAE7),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}

class _PasswordRequirement extends StatelessWidget {
  const _PasswordRequirement({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              met ? Icons.check_circle : Icons.radio_button_unchecked,
              key: ValueKey(met),
              size: 16,
              color: met ? AppColors.success : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: met ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onChanged,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF7F8FC),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF5B53F6), width: 1.4),
        ),
      ),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({
    required this.label,
    this.trailingIcon,
    this.onPressed,
    this.busy = false,
  });

  final String label;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5B53F6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child:
            busy
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 6),
                      Icon(trailingIcon, size: 18),
                    ],
                  ],
                ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.leading,
    required this.action,
    required this.onTap,
  });

  final String leading;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          leading,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5B53F6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

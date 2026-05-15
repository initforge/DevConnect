import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/routes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/localization/app_strings.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});
  final String token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pwKey = Validators.password(_newCtrl.text);
    if (pwKey != null) {
      setState(() => _error = AppStrings.of(context).t(pwKey));
      return;
    }
    final confirmKey = Validators.confirmPassword(
      _confirmCtrl.text,
      _newCtrl.text,
    );
    if (confirmKey != null) {
      setState(() => _error = AppStrings.of(context).t(confirmKey));
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ApiService.instance.post('/auth/reset-password', {
        'token': widget.token,
        'newPassword': _newCtrl.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully. Please sign in.'),
        ),
      );
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Reset failed. Link may have expired.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter your new password',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
}

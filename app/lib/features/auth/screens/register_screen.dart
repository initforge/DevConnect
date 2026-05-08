import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/app_preferences.dart';

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
  double _passwordStrength = 0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() { _nameCtrl.dispose(); _usernameCtrl.dispose(); _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  void _calcStrength(String pw) {
    double s = 0;
    if (pw.length >= 8) s += 0.25;
    if (pw.contains(RegExp(r'[A-Z]'))) s += 0.25;
    if (pw.contains(RegExp(r'[0-9]'))) s += 0.25;
    if (pw.contains(RegExp(r'[!@#$%^&*]'))) s += 0.25;
    setState(() => _passwordStrength = s);
  }

  Color _strengthColor() {
    if (_passwordStrength <= 0.25) return AppColors.error;
    if (_passwordStrength <= 0.5) return AppColors.warning;
    if (_passwordStrength <= 0.75) return AppColors.primary;
    return AppColors.success;
  }

  String _strengthText() {
    if (_passwordStrength <= 0.25) return 'Yếu';
    if (_passwordStrength <= 0.5) return 'Trung bình';
    if (_passwordStrength <= 0.75) return 'Mạnh';
    return 'Rất mạnh';
  }

  Future<void> _nextStep() async {
    if (_step == 0) {
      if (_nameCtrl.text.isEmpty || _usernameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) return;
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_passwordCtrl.text.length < 8) return;
      setState(() { _isLoading = true; _errorMessage = null; });
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
        HapticFeedback.mediumImpact();
        setState(() { _step = 2; _isLoading = false; });
        await Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/onboarding');
        });
      } catch (e) {
        if (mounted) {
          setState(() { _isLoading = false; _errorMessage = e.toString(); });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFEEF2FF), Color(0xFFF0FDFA), Color(0xFFFAF5FF)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  if (_step > 0 && _step < 2) IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step--)),
                  const Spacer(),
                  TextButton(onPressed: () => context.go('/login'), child: const Text('Đã có tài khoản')),
                ]),
              ),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ))),
              ),
              const SizedBox(height: 32),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _step == 0 ? _buildStep1() : _step == 1 ? _buildStep2() : _buildStep3(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(key: const ValueKey(0), crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Tạo tài khoản', style: Theme.of(context).textTheme.displayMedium),
      const SizedBox(height: 8),
      Text('Tham gia cộng đồng lập trình viên', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 32),
      TextFormField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Họ và tên', prefixIcon: Icon(Icons.person_outline)), textInputAction: TextInputAction.next),
      const SizedBox(height: 16),
      TextFormField(controller: _usernameCtrl, decoration: const InputDecoration(hintText: 'Tên đăng nhập', prefixIcon: Icon(Icons.alternate_email)), textInputAction: TextInputAction.next),
      const SizedBox(height: 16),
      TextFormField(controller: _emailCtrl, decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.done),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _nextStep, child: const Text('Tiếp tục'))),
    ]);
  }

  Widget _buildStep2() {
    return Column(key: const ValueKey(1), crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Mật khẩu', style: Theme.of(context).textTheme.displayMedium),
      const SizedBox(height: 8),
      Text('Tối thiểu 8 ký tự, nên có chữ hoa, số và ký tự đặc biệt', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 32),
      if (_errorMessage != null) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
          child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
        ),
        const SizedBox(height: 16),
      ],
      TextFormField(
        controller: _passwordCtrl, obscureText: _obscure,
        onChanged: _calcStrength,
        decoration: InputDecoration(hintText: 'Mật khẩu', prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscure = !_obscure))),
      ),
      const SizedBox(height: 12),
      // Strength bar
      Row(children: [
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: _passwordStrength, backgroundColor: AppColors.border, color: _strengthColor(), minHeight: 6))),
        const SizedBox(width: 12),
        Text(_strengthText(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _strengthColor())),
      ]),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
        onPressed: _isLoading ? null : _nextStep,
        child: _isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Đăng ký'),
      )),
    ]);
  }

  Widget _buildStep3() {
    return Column(key: const ValueKey(2), children: [
      const SizedBox(height: 60),
      Container(width: 80, height: 80, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
        child: const Icon(Icons.check, color: Colors.white, size: 40)),
      const SizedBox(height: 24),
      Text('Đăng ký thành công! 🎉', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      Text('Đang chuyển hướng...', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
    ]);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_seed_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/app_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0; // 0: languages, 1: frameworks, 2: topics
  final Set<String> _selectedLangs = {};
  final Set<String> _selectedFrameworks = {};
  final Set<String> _selectedTopics = {};

  Set<String> get _currentSet => _page == 0 ? _selectedLangs : _page == 1 ? _selectedFrameworks : _selectedTopics;
  List<String> get _currentItems => _page == 0
      ? AppSeedConstants.languages
      : _page == 1
          ? AppSeedConstants.frameworks
          : AppSeedConstants.topics;
  String get _title => _page == 0 ? 'Ngôn ngữ lập trình' : _page == 1 ? 'Framework yêu thích' : 'Chủ đề quan tâm';
  String get _subtitle => _page == 0 ? 'Bạn đang dùng ngôn ngữ nào?' : _page == 1 ? 'Bạn thích framework nào?' : 'Bạn hứng thú với chủ đề gì?';

  void _toggle(String item) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentSet.contains(item)) { _currentSet.remove(item); }
      else { _currentSet.add(item); }
    });
  }

  void _next() async {
    if (_page < 2) { setState(() => _page++); }
    else {
      // Save onboarding data and mark as completed
      await AppPreferences.instance.saveOnboardingData(
        languages: _selectedLangs.toList(),
        frameworks: _selectedFrameworks.toList(),
        topics: _selectedTopics.toList(),
      );
      await AppPreferences.instance.setOnboardingCompleted(true);
      if (mounted) context.go('/home');
    }
  }

  void _skip() async {
    await AppPreferences.instance.setOnboardingCompleted(true);
    if (mounted) context.go('/home');
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  if (_page > 0) IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _page--)),
                  const Spacer(),
                  TextButton(onPressed: _skip, child: const Text('Bỏ qua')),
                ]),
              ),
              // Progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: List.generate(3, (i) => Expanded(
                  child: Container(height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(color: i <= _page ? AppColors.accent : AppColors.border, borderRadius: BorderRadius.circular(2))),
                ))),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_title, style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 8),
                  Text(_subtitle, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
                ]),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: SingleChildScrollView(
                    key: ValueKey(_page),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 10, runSpacing: 10,
                      children: _currentItems.map((item) {
                        final selected = _currentSet.contains(item);
                        return GestureDetector(
                          onTap: () => _toggle(item),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                              boxShadow: selected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
                            ),
                            child: Text(item, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.textPrimary)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              // Bottom
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Text('Đã chọn ${_currentSet.length} mục', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary)),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _currentSet.isNotEmpty ? _next : null,
                      child: Text(_page < 2 ? 'Tiếp tục' : 'Bắt đầu khám phá'),
                    )),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_seed_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/decorative_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Set<String> _selected = {'React', 'Node.js', 'Go'};

  List<String> get _items => [
    'React',
    'Flutter',
    'Python',
    'Node.js',
    'TypeScript',
    'Docker',
    'AWS',
    'PostgreSQL',
    'AI/ML',
    'DevOps',
    'Rust',
    'Go',
  ];

  Future<void> _continue() async {
    try {
      // Persist onboarding completion locally first so this flow only runs once.
      await AppPreferences.instance.saveOnboardingData(
        languages: _selected.toList(),
        frameworks: const <String>[],
        topics: AppSeedConstants.topics.take(3).toList(),
      );
      await AppPreferences.instance.setOnboardingCompleted(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save onboarding state: $e')),
      );
      return;
    }

    try {
      // Sync to backend if authenticated.
      if (ApiService.instance.isAuthenticated) {
        await ApiService.instance.patch(ApiEndpoints.usersMe, {
          'skills': _selected.join('|'),
        });
        await ApiService.instance.patch('/users/me/settings', {
          'onboardingCompleted': true,
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sync onboarding profile: $e')),
      );
      return;
    }

    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _toggle(String item) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else {
        _selected.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DecorativeBackground(
        child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final columnCount = _columnCount(width);
            final cardHeight = height < 700 ? 88.0 : 98.0;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back, size: 20),
                        ),
                        const Expanded(
                          child: Text(
                            'Onboarding',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final selected = index == 3;
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? const Color(0xFF5B53F6)
                                    : const Color(0xFFD6DAE6),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                const SliverToBoxAdapter(
                  child: Text(
                    'Almost there!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      'Pick your interests to personalize your feed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: cardHeight,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _items[index];
                      final selected = _selected.contains(item);
                      return _InterestCard(
                        label: item,
                        selected: selected,
                        icon: _iconFor(item),
                        onTap: () => _toggle(item),
                      );
                    }, childCount: _items.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _selected.isEmpty ? null : _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text('Continue'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _continue,
                          child: const Text(
                            'Skip for now',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }

  int _columnCount(double width) {
    if (width < 360) return 2;
    if (width < 620) return 3;
    if (width < 980) return 4;
    return 5;
  }

  IconData _iconFor(String label) {
    switch (label) {
      case 'React':
        return Icons.code;
      case 'Flutter':
        return Icons.phone_android;
      case 'Python':
        return Icons.terminal;
      case 'Node.js':
        return Icons.javascript;
      case 'TypeScript':
        return Icons.description_outlined;
      case 'Docker':
        return Icons.inventory_2_outlined;
      case 'AWS':
        return Icons.cloud_outlined;
      case 'PostgreSQL':
        return Icons.storage_outlined;
      case 'AI/ML':
        return Icons.psychology_outlined;
      case 'DevOps':
        return Icons.all_inclusive;
      case 'Rust':
        return Icons.build_outlined;
      case 'Go':
        return Icons.rocket_launch_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}

class _InterestCard extends StatelessWidget {
  const _InterestCard({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF5B53F6) : const Color(0xFFE5E8F0),
            width: selected ? 1.7 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (selected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5B53F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color:
                        selected
                            ? const Color(0xFF5B53F6)
                            : const Color(0xFF1F2937),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          selected
                              ? const Color(0xFF5B53F6)
                              : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

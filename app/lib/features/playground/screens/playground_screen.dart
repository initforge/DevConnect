import 'package:flutter/material.dart';

import '../../../core/constants/routes.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ai_sheets.dart';
import '../../../core/widgets/shared_widgets.dart';

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  String _language = 'TypeScript';
  final _codeCtrl = TextEditingController(
    text:
        'function greet(name: string) {\n  console.log(`Hello from \$name`);\n}\n\ngreet("DevConnect");',
  );
  String _output = '';
  bool _running = false;

  final _languages = const ['TypeScript', 'Python', 'Dart', 'Go'];

  Future<void> _runCode() async {
    setState(() {
      _running = true;
      _output = '';
    });

    try {
      final result = await ApiService.instance.post('/api/code/run', {
        'code': _codeCtrl.text,
        'language': _language.toLowerCase(),
      });
      if (!mounted) return;
      setState(() {
        _running = false;
        _output = result['output']?.toString() ?? result.toString();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _output = 'Error: unable to run code right now.';
      });
    }
  }

  Future<void> _showReview() {
    return showAiReviewSheet(
      context,
      reviewFuture: AiService.instance.reviewCode(
        code: _codeCtrl.text,
        language: _language,
      ),
    );
  }

  Future<void> _showExplain() {
    return showAiExplainSheet(
      context,
      explanationFuture: AiService.instance.explainCode(
        code: _codeCtrl.text,
        language: _language,
      ),
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            icon: Icons.code_outlined,
            selectedIcon: Icons.code,
            label: 'Playground',
            route: AppRoutes.playground,
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            route: AppRoutes.profile,
          ),
        ],
        selectedIndex: 2,
        currentRoute: AppRoutes.playground,
        centerCreate: true,
      ),
      appBar: AppBar(
        title: const Text(
          'Code Playground',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _running ? null : _runCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16C784),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(_running ? 'Running' : 'Run'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _language,
                      isExpanded: true,
                      items:
                          _languages
                              .map(
                                (language) => DropdownMenuItem(
                                  value: language,
                                  child: Text(
                                    language,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _language = value);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.settings_outlined, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _EditorCard(controller: _codeCtrl, language: _language),
          const SizedBox(height: 12),
          _OutputCard(output: _output, running: _running),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AssistCard(
                  icon: Icons.auto_awesome,
                  title: 'AI Review',
                  subtitle:
                      'Highlight risky logic and suggest cleaner structure.',
                  onTap: _showReview,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _AssistCard(
                  icon: Icons.psychology_alt_outlined,
                  title: 'AI Explain',
                  subtitle: 'Break down the snippet in plain language.',
                  onTap: _showExplain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.controller, required this.language});

  final TextEditingController controller;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                language,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.refresh, size: 16, color: Color(0xFF5B53F6)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8EAF2)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: const Row(
                    children: [
                      _Dot(color: Color(0xFFFF5F57)),
                      SizedBox(width: 6),
                      _Dot(color: Color(0xFFFEBB2E)),
                      SizedBox(width: 6),
                      _Dot(color: Color(0xFF28C840)),
                    ],
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.55,
                      color: Color(0xFF4F46E5),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputCard extends StatelessWidget {
  const _OutputCard({required this.output, required this.running});

  final String output;
  final bool running;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Console Output',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 110),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EAF2)),
            ),
            child:
                running
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : Text(
                      output.isEmpty
                          ? 'hello from devconnect\nrun complete\n'
                          : output,
                      style: TextStyle(
                        color:
                            output.isEmpty
                                ? const Color(0xFF047857)
                                : const Color(0xFF047857),
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        height: 1.55,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _AssistCard extends StatelessWidget {
  const _AssistCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EAF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF5B53F6), size: 20),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

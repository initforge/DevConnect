import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/services/api_service.dart';

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});
  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  String _language = 'Python';
  final _codeCtrl = TextEditingController(text: '# Viết code ở đây\nprint("Hello, DevConnect!")\n\nfor i in range(5):\n    print(f"Lần {i + 1}")');
  String _output = '';
  bool _running = false;

  final _languages = ['Python', 'JavaScript', 'Dart', 'Go', 'TypeScript', 'Rust', 'Java', 'C++'];

  Future<void> _runCode() async {
    setState(() { _running = true; _output = ''; });
    try {
      final result = await ApiService.instance.post('/api/code/run', {
        'code': _codeCtrl.text,
        'language': _language.toLowerCase(),
      });
      setState(() { _running = false; _output = result.toString(); });
    } catch (e) {
      setState(() { _running = false; _output = 'Lỗi: Không thể chạy code. Vui lòng thử lại.'; });
    }
  }

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sân chơi Code'), actions: [
        // Language selector
        Container(margin: const EdgeInsets.symmetric(vertical: 8), padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _language, isDense: true,
            items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _language = v!)))),
        const SizedBox(width: 8),
        IconButton(icon: _running
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.play_arrow, color: AppColors.success), onPressed: _running ? null : _runCode),
        const SizedBox(width: 4),
      ]),
      body: Column(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: FuturePhaseBanner(
            title: 'Code playground đang ở mức local prototype',
            description: 'Màn này được giữ lại để thử nghiệm trải nghiệm editor. Khi chuyển sang phase sau, phần compile sandbox, history và chia sẻ session sẽ tách thành workstream riêng.',
            badge: 'PREVIEW',
            icon: Icons.science_outlined,
          ),
        ),
        // Code editor
        Expanded(flex: 3, child: Container(color: const Color(0xFF1E1E2E),
          child: TextField(controller: _codeCtrl, maxLines: null, expands: true,
            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 14, color: Color(0xFFCDD6F4), height: 1.5),
            decoration: const InputDecoration(border: InputBorder.none, filled: false,
              contentPadding: EdgeInsets.all(16))))),
        // Divider with handle
        Container(height: 32, color: AppColors.surfaceAlt,
          child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.drag_handle, size: 16, color: AppColors.textTertiary),
            SizedBox(width: 8),
            Text('Kết quả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
          ]))),
        // Output
        Expanded(flex: 2, child: Container(width: double.infinity, color: const Color(0xFF11111B),
          padding: const EdgeInsets.all(16),
          child: _output.isEmpty
            ? const Text('Nhấn ▶ để chạy code', style: TextStyle(color: Color(0xFF6C7086), fontFamily: 'JetBrains Mono', fontSize: 13))
            : Text(_output, style: const TextStyle(color: Color(0xFFA6E3A1), fontFamily: 'JetBrains Mono', fontSize: 13, height: 1.5)))),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/post_repository.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _repository = PostRepository();
  final _imagePicker = ImagePicker();

  PostType _type = PostType.article;
  final List<String> _tags = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(String filePath) async {
    try {
      final result = await ApiService.instance.uploadFile(
        '/api/media/upload',
        filePath: filePath,
        fieldName: 'image',
      );
      return result['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        // Try to upload first
        String inserted;
        if (ApiService.instance.isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đang tải ảnh lên...'), duration: Duration(seconds: 1)),
          );
          final uploadedUrl = await _uploadImage(image.path);
          if (uploadedUrl != null) {
            inserted = '\n![${image.name}]($uploadedUrl)\n';
          } else {
            inserted = '\n![${image.name}](${image.path})\n';
          }
        } else {
          inserted = '\n![${image.name}](${image.path})\n';
        }
        _insertText(inserted);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể chọn ảnh')),
        );
      }
    }
  }

  void _insertCodeBlock() {
    HapticFeedback.lightImpact();
    final cursorPos = _contentCtrl.selection.baseOffset;
    final codeBlock = '\n```dart\n// Your code here\n```\n';
    _insertText(codeBlock, cursorPos: cursorPos >= 0 ? cursorPos : null);
  }

  void _showLinkDialog() {
    HapticFeedback.lightImpact();
    final linkCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm liên kết'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textCtrl,
              decoration: const InputDecoration(
                labelText: 'Văn bản hiển thị',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: linkCtrl,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textCtrl.text.trim();
              final link = linkCtrl.text.trim();
              if (link.isNotEmpty) {
                final markdown = text.isNotEmpty ? '[$text]($link)' : link;
                _insertText(markdown);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _wrapSelection(String prefix, String suffix) {
    HapticFeedback.lightImpact();
    final selection = _contentCtrl.selection;
    final text = _contentCtrl.text;
    if (selection.isValid && selection.start != selection.end) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
      _contentCtrl.text = newText;
      _contentCtrl.selection = TextSelection.collapsed(offset: selection.end + prefix.length + suffix.length);
    } else {
      _insertText('$prefix$suffix');
      _contentCtrl.selection = TextSelection.collapsed(offset: _contentCtrl.selection.baseOffset - suffix.length);
    }
  }

  void _insertText(String text, {int? cursorPos}) {
    final currentPos = cursorPos ?? _contentCtrl.selection.baseOffset;
    final currentText = _contentCtrl.text;
    if (currentPos >= 0) {
      _contentCtrl.text = currentText.substring(0, currentPos) + text + currentText.substring(currentPos);
      _contentCtrl.selection = TextSelection.collapsed(offset: currentPos + text.length);
    } else {
      _contentCtrl.text = currentText + text;
      _contentCtrl.selection = TextSelection.collapsed(offset: _contentCtrl.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viết bài'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Đăng',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Loại bài viết', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PostType.values.map((type) {
                  final selected = type == _type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_typeLabel(type)),
                      selected: selected,
                      onSelected: (_) => setState(() => _type = type),
                      selectedColor: AppColors.primary.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: 'Tiêu đề bài viết...',
                border: InputBorder.none,
                filled: false,
              ),
              maxLines: null,
            ),
            const Divider(),
            TextField(
              controller: _contentCtrl,
              style: const TextStyle(fontSize: 15, height: 1.6),
              decoration: const InputDecoration(
                hintText: 'Viết nội dung bằng Markdown...\n\n## Tiêu đề phụ\nNội dung...\n\n```dart\n// Code block\n```',
                border: InputBorder.none,
                filled: false,
              ),
              maxLines: null,
              minLines: 10,
            ),
            const SizedBox(height: 16),
            const Text('Tags', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ..._tags.map(
                  (tag) => Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _tagCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Thêm tag...',
                      border: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (value) {
                      final trimmed = value.trim();
                      if (trimmed.isNotEmpty && _tags.length < 5) {
                        setState(() => _tags.add(trimmed));
                        _tagCtrl.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ToolBtn(icon: Icons.image_outlined, label: 'Ảnh', onTap: _pickImage),
                      _ToolBtn(icon: Icons.code, label: 'Code', onTap: _insertCodeBlock),
                      _ToolBtn(icon: Icons.link, label: 'Link', onTap: _showLinkDialog),
                      _ToolBtn(icon: Icons.format_bold, label: 'B', onTap: () => _wrapSelection('**', '**')),
                      _ToolBtn(icon: Icons.format_italic, label: 'I', onTap: () => _wrapSelection('*', '*')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.aiPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: AppColors.aiPurple),
                          SizedBox(width: 4),
                          Text(
                            'AI Review',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.aiPurple),
                          ),
                        ],
                      ),
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

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần nhập tiêu đề và nội dung trước khi đăng')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await _repository.createPost(
      title: title,
      content: content,
      type: _type,
      tags: _tags,
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _typeLabel(PostType type) {
    switch (type) {
      case PostType.article:
        return 'Bài viết';
      case PostType.snippet:
        return 'Code';
      case PostType.til:
        return 'TIL';
      case PostType.question:
        return 'Hỏi đáp';
      case PostType.project:
        return 'Dự án';
      case PostType.discussion:
        return 'Thảo luận';
    }
  }
}

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}

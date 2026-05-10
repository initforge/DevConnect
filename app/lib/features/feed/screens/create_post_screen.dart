import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/models.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ai_sheets.dart';
import '../../../data/repositories/post_repository.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController(
    text: 'def hello_devs():\n    print("Hello DevConnect!")',
  );
  final _tagCtrl = TextEditingController();
  final _repository = PostRepository();
  final _imagePicker = ImagePicker();

  final List<String> _tags = ['typescript', 'react'];
  PostType _type = PostType.article;
  bool _aiReview = true;
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
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;
    final uploadedUrl = await _uploadImage(image.path);
    _insertText('\n![${image.name}](${uploadedUrl ?? image.path})\n');
  }

  void _insertText(String text) {
    final currentPos = _contentCtrl.selection.baseOffset;
    final currentText = _contentCtrl.text;
    final offset = currentPos >= 0 ? currentPos : currentText.length;
    _contentCtrl.text =
        currentText.substring(0, offset) + text + currentText.substring(offset);
    _contentCtrl.selection = TextSelection.collapsed(
      offset: offset + text.length,
    );
  }

  Future<void> _insertGif() async {
    final options = <Map<String, String>>[
      {
        'label': 'Happy coding',
        'url': 'https://media.giphy.com/media/13HgwGsXF0aiGY/giphy.gif',
      },
      {
        'label': 'Ship it',
        'url': 'https://media.giphy.com/media/fAnEC88LccN7a/giphy.gif',
      },
      {
        'label': 'Debug mode',
        'url': 'https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif',
      },
    ];

    final selectedUrl = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        final customCtrl = TextEditingController();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insert GIF',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a preset or paste a GIF URL.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                ...options.map(
                  (option) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.gif_box_outlined),
                    title: Text(option['label']!),
                    subtitle: Text(
                      option['url']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(context).pop(option['url']),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: customCtrl,
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    filled: true,
                    fillColor: const Color(0xFFF4F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).pop(customCtrl.text.trim()),
                    child: const Text('Use GIF'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedUrl == null || selectedUrl.trim().isEmpty || !mounted) return;
    _insertText(
      '\n![]( ${selectedUrl.trim()} )\n'
          .replaceAll('( ', '(')
          .replaceAll(' )', ')'),
    );
  }

  Future<void> _previewAiReview() {
    return showAiReviewSheet(
      context,
      reviewFuture: AiService.instance.reviewCode(
        code: _contentCtrl.text,
        language: _type == PostType.snippet ? 'snippet' : 'markdown',
      ),
    );
  }

  Future<void> _submit() async {
    final title =
        _titleCtrl.text.trim().isEmpty
            ? 'What are you working on?'
            : _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some content before posting')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    if (_aiReview) {
      final review = await AiService.instance.reviewCode(
        code: content,
        language: _type == PostType.snippet ? 'snippet' : 'markdown',
      );
      if (!mounted) return;
      final shouldPost = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('AI review before posting'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score: ${review.score}/10',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(review.summary),
                if (review.issues.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...review.issues
                      .take(2)
                      .map(
                        (issue) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('- ${issue.message}'),
                        ),
                      ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep editing'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Post now'),
              ),
            ],
          );
        },
      );
      if (shouldPost != true) {
        setState(() => _isSubmitting = false);
        return;
      }
    }

    await _repository.createPost(
      title: title,
      content: content,
      type: _type,
      tags: _tags,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF5B53F6),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Post', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomComposerBar(
        onCamera: _pickImage,
        onImage: _pickImage,
        onGif: _insertGif,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
        children: [
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _TypePill(
                  type: PostType.article,
                  current: _type,
                  label: 'Article',
                  onTap: _setType,
                ),
                _TypePill(
                  type: PostType.snippet,
                  current: _type,
                  label: 'Snippet',
                  onTap: _setType,
                ),
                _TypePill(
                  type: PostType.til,
                  current: _type,
                  label: 'TIL',
                  onTap: _setType,
                ),
                _TypePill(
                  type: PostType.question,
                  current: _type,
                  label: 'Q&A',
                  onTap: _setType,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            decoration: const InputDecoration(
              hintText: 'What are you working on?',
              hintStyle: TextStyle(
                color: Color(0xFFB2B8C7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 26),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'CODE PREVIEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'main.py',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5B53F6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentCtrl,
                  minLines: 7,
                  maxLines: 9,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFF6E59F7),
                    height: 1.55,
                  ),
                  decoration: const InputDecoration(
                    hintText: '# Start your code block here',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._tags.map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5B53F6),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _tags.remove(tag)),
                        child: const Icon(
                          Icons.close,
                          size: 13,
                          color: Color(0xFF5B53F6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: 102,
                  child: TextField(
                    controller: _tagCtrl,
                    onSubmitted: (value) {
                      final trimmed = value.trim();
                      if (trimmed.isEmpty) return;
                      setState(() => _tags.add(trimmed));
                      _tagCtrl.clear();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Add tags...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _previewAiReview,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8EAF2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F0FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: Color(0xFF5B53F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Code Review',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Preview automated feedback before posting',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _aiReview,
                    activeColor: const Color(0xFF16C784),
                    onChanged: (value) => setState(() => _aiReview = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  void _setType(PostType type) {
    setState(() => _type = type);
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.type,
    required this.current,
    required this.label,
    required this.onTap,
  });

  final PostType type;
  final PostType current;
  final String label;
  final ValueChanged<PostType> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = type == current;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF5B53F6) : const Color(0xFFF4F6FA),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomComposerBar extends StatelessWidget {
  const _BottomComposerBar({
    required this.onCamera,
    required this.onImage,
    required this.onGif,
  });

  final VoidCallback onCamera;
  final VoidCallback onImage;
  final VoidCallback onGif;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EAF2))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: const [
                _ToolbarIcon(Icons.format_bold),
                SizedBox(width: 18),
                _ToolbarIcon(Icons.format_italic),
                SizedBox(width: 18),
                _ToolbarIcon(Icons.link),
                SizedBox(width: 18),
                _ToolbarIcon(Icons.image_outlined),
                SizedBox(width: 18),
                _ToolbarIcon(Icons.code),
                SizedBox(width: 18),
                _ToolbarIcon(Icons.format_list_bulleted),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MediaButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Camera',
                  onTap: onCamera,
                ),
                const SizedBox(width: 8),
                _MediaButton(
                  icon: Icons.image_outlined,
                  label: 'Image',
                  onTap: onImage,
                ),
                const SizedBox(width: 8),
                _MediaButton(
                  icon: Icons.gif_box_outlined,
                  label: 'GIF',
                  onTap: onGif,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 18, color: AppColors.textPrimary);
  }
}

class _MediaButton extends StatelessWidget {
  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

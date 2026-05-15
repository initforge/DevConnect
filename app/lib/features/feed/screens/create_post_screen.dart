import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/models/models.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/services/image_compression_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ai_sheets.dart';
import '../../../data/repositories/post_repository.dart';
import '../widgets/create_post/composer_toolbar.dart';
import '../widgets/create_post/post_type_selector.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _projectUrlCtrl = TextEditingController();
  final _projectTeamCtrl = TextEditingController();
  final _projectStackCtrl = TextEditingController();
  final _discussionCtrl = TextEditingController();
  final _repository = PostRepository();
  final _imageCompression = ImageCompressionService();

  final List<String> _tags = ['typescript', 'react'];
  PostType _type = PostType.article;
  bool _aiReview = true;
  bool _isSubmitting = false;
  bool _isPreview = false;

  void _togglePreview() {
    setState(() => _isPreview = !_isPreview);
    unawaited(HapticFeedback.mediumImpact());
  }

  @override
  void initState() {
    super.initState();
    final titleDraft = AppPreferences.instance.getDraft('post.title');
    final contentDraft = AppPreferences.instance.getDraft('post.content');
    if (titleDraft != null && titleDraft.isNotEmpty) {
      _titleCtrl.text = titleDraft;
    }
    if (contentDraft != null && contentDraft.isNotEmpty) {
      _contentCtrl.text = contentDraft;
    }
  }

  @override
  void dispose() {
    if (_contentCtrl.text.trim().isNotEmpty) {
      AppPreferences.instance.setDraft('post.title', _titleCtrl.text);
      AppPreferences.instance.setDraft('post.content', _contentCtrl.text);
    }
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    _projectUrlCtrl.dispose();
    _projectTeamCtrl.dispose();
    _projectStackCtrl.dispose();
    _discussionCtrl.dispose();
    super.dispose();
  }

  Future<String?> _uploadImageBytes(List<int> bytes, String fileName) async {
    try {
      final result = await ApiService.instance.uploadFileBytes(
        '/media/upload',
        bytes: bytes,
        fileName: fileName,
        fieldName: 'file',
      );
      return (result['fullUrl'] ?? result['url']) as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickImage() async {
    unawaited(HapticFeedback.lightImpact());
    final image = await _imageCompression.pickCompressedImage(
      source: ImageSource.gallery,
    );
    if (image == null || !mounted) return;
    final allowed = await _imageCompression.isUnderUploadLimit(image);
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image must be under 10MB after compression.'),
        ),
      );
      return;
    }
    final bytes = await image.readAsBytes();
    final uploadedUrl = await _uploadImageBytes(bytes, image.name);
    if (uploadedUrl != null) {
      _insertText('\n![${image.name}]($uploadedUrl)\n');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upload image. Please try again.'),
        ),
      );
    }
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

  void _wrapSelection(
    String before,
    String after, {
    String placeholder = 'text',
  }) {
    final selection = _contentCtrl.selection;
    final text = _contentCtrl.text;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : start;
    final selectedText =
        start != end ? text.substring(start, end) : placeholder;
    final replacement = '$before$selectedText$after';
    _contentCtrl.text = text.replaceRange(start, end, replacement);
    _contentCtrl.selection = TextSelection.collapsed(
      offset: start + before.length + selectedText.length,
    );
  }

  void _insertBold() => _wrapSelection('**', '**');

  void _insertItalic() => _wrapSelection('*', '*');

  void _insertLink() =>
      _wrapSelection('[', '](https://example.com)', placeholder: 'link text');

  void _insertCodeBlock() => _insertText('\n```\ncode\n```\n');

  void _insertList() => _insertText('\n- item one\n- item two\n');

  String _buildSubmissionContent() {
    final content = _contentCtrl.text.trim();
    final details = <String>[];

    if (_type == PostType.project) {
      final url = _projectUrlCtrl.text.trim();
      final team = _projectTeamCtrl.text.trim();
      final stack = _projectStackCtrl.text.trim();
      if (url.isNotEmpty) details.add('Project URL: $url');
      if (team.isNotEmpty) details.add('Team: $team');
      if (stack.isNotEmpty) details.add('Tech Stack: $stack');
    } else if (_type == PostType.discussion) {
      final discussion = _discussionCtrl.text.trim();
      if (discussion.isNotEmpty) {
        details.add('Discussion prompt: $discussion');
      }
    }

    if (details.isEmpty) return content;
    return [content, '', ...details.map((line) => '- $line')].join('\n');
  }

  String _buildPreviewMarkdown() {
    final title = _titleCtrl.text.trim();
    final body = _buildSubmissionContent();
    return '# ${title.isEmpty ? 'What are you working on?' : title}\n\n$body';
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
        code: _buildSubmissionContent(),
        language: _type == PostType.snippet ? 'snippet' : 'markdown',
      ),
    );
  }

  Future<void> _submit() async {
    final title =
        _titleCtrl.text.trim().isEmpty
            ? AppStrings.of(context).t('feed.defaultTitle')
            : _titleCtrl.text.trim();
    final content = _buildSubmissionContent();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).t('feed.addContent'))),
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
            title: Text(AppStrings.of(context).t('feed.aiReview')),
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
                child: Text(AppStrings.of(context).t('feed.keepEditing')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppStrings.of(context).t('feed.postNow')),
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

    try {
      await _repository.createPost(
        title: title,
        content: content,
        type: _type,
        tags: _tags,
      );
      if (!mounted) return;
      await AppPreferences.instance.clearDraft('post.title');
      await AppPreferences.instance.clearDraft('post.content');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to publish post: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.06),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
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
          IconButton(
            onPressed: _togglePreview,
            icon: Icon(
              _isPreview ? Icons.edit_note : Icons.remove_red_eye_outlined,
            ),
            tooltip: _isPreview ? 'Edit' : 'Preview',
          ),
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
                        : Text(
                          AppStrings.of(context).t('feed.post'),
                          style: const TextStyle(fontSize: 12),
                        ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ComposerToolbar(
        onBold: _insertBold,
        onItalic: _insertItalic,
        onLink: _insertLink,
        onCode: _insertCodeBlock,
        onList: _insertList,
        onCamera: _pickImage,
        onImage: _pickImage,
        onGif: _insertGif,
      ),
      body:
          _isPreview
              ? Markdown(
                data: _buildPreviewMarkdown(),
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(
                  code: const TextStyle(
                    fontFamily: 'monospace',
                    backgroundColor: Color(0xFFF7F8FC),
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
              : ListView(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
                children: [
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        PostTypePill(
                          type: PostType.article,
                          current: _type,
                          label: 'Article',
                          onTap: _setType,
                        ),
                        PostTypePill(
                          type: PostType.snippet,
                          current: _type,
                          label: 'Snippet',
                          onTap: _setType,
                        ),
                        PostTypePill(
                          type: PostType.til,
                          current: _type,
                          label: 'TIL',
                          onTap: _setType,
                        ),
                        PostTypePill(
                          type: PostType.question,
                          current: _type,
                          label: 'Q&A',
                          onTap: _setType,
                        ),
                        PostTypePill(
                          type: PostType.project,
                          current: _type,
                          label: 'Project',
                          onTap: _setType,
                        ),
                        PostTypePill(
                          type: PostType.discussion,
                          current: _type,
                          label: 'Discussion',
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
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Editor title bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          color: const Color(0xFF1E1E2E),
                          child: Row(
                            children: [
                              const Row(
                                children: [
                                  _EditorDot(Color(0xFFFF5F56)),
                                  SizedBox(width: 6),
                                  _EditorDot(Color(0xFFFFBD2E)),
                                  SizedBox(width: 6),
                                  _EditorDot(Color(0xFF27C93F)),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF313244),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _type == PostType.snippet
                                      ? 'SNIPPET'
                                      : 'CONTENT',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF89B4FA),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Editor body
                        Container(
                          width: double.infinity,
                          color: const Color(0xFF1E1E2E),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: TextField(
                            controller: _contentCtrl,
                            minLines: 8,
                            maxLines: 12,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Color(0xFFCDD6F4),
                              height: 1.6,
                            ),
                            cursorColor: const Color(0xFF89B4FA),
                            decoration: const InputDecoration(
                              hintText: '// Write your content or code here...',
                              hintStyle: TextStyle(color: Color(0xFF6C7086)),
                              filled: true,
                              fillColor: Color(0xFF1E1E2E),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_type == PostType.project) ...[
                    const SizedBox(height: 14),
                    _MetadataPanel(
                      title: 'Project details',
                      subtitle: 'Optional metadata for project posts.',
                      child: Column(
                        children: [
                          _InlineField(
                            controller: _projectUrlCtrl,
                            hint: 'GitHub URL or live demo link',
                            icon: Icons.link,
                          ),
                          const SizedBox(height: 10),
                          _InlineField(
                            controller: _projectTeamCtrl,
                            hint: 'Team members or team name',
                            icon: Icons.group_outlined,
                          ),
                          const SizedBox(height: 10),
                          _InlineField(
                            controller: _projectStackCtrl,
                            hint: 'Tech stack, comma separated',
                            icon: Icons.layers_outlined,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_type == PostType.discussion) ...[
                    const SizedBox(height: 14),
                    _MetadataPanel(
                      title: 'Discussion prompt',
                      subtitle: 'Capture the question or poll context.',
                      child: _InlineField(
                        controller: _discussionCtrl,
                        hint: 'What do you want the community to weigh in on?',
                        icon: Icons.forum_outlined,
                        maxLines: 4,
                      ),
                    ),
                  ],
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
                            onChanged:
                                (value) => setState(() => _aiReview = value),
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

class _MetadataPanel extends StatelessWidget {
  const _MetadataPanel({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: const Color(0xFFF7F8FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _EditorDot extends StatelessWidget {
  const _EditorDot(this.color);
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

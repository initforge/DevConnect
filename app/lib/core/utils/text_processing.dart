/// Text processing utilities for DevConnect.
///
/// Handles code extraction, markdown stripping, and language detection.
/// Separate from validators.dart — these are transformations, not validations.
library;

import '../models/post.dart';

class TextProcessing {
  TextProcessing._();

  // ── Code block extraction ──────────────────────────────────────────────────

  /// Extracts the first fenced code block from [content].
  ///
  /// Returns the code inside ``` ``` fences, or empty string if none found.
  static String extractCodeBlock(String content) {
    final match = RegExp(
      r'```\w*\n?(.*?)```',
      dotAll: true,
    ).firstMatch(content);
    return match?.group(1)?.trim() ?? '';
  }

  /// Extracts a code snippet from a [Post], with fallback to metadata snippet.
  static String extractPostCodeSnippet(Post post) {
    final fromContent = extractCodeBlock(post.content);
    if (fromContent.isNotEmpty) return fromContent;

    // Fallback: generate a representative snippet from post metadata
    final normalizedTitle = post.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final firstTag = post.tags.isNotEmpty ? post.tags.first : 'snippet';
    return "const ${normalizedTitle.isEmpty ? 'postDetail' : normalizedTitle} = {\n"
        "  topic: '${post.title}',\n"
        "  tag: '$firstTag',\n"
        "  status: 'ready for review',\n"
        "};";
  }

  // ── Language detection ─────────────────────────────────────────────────────

  /// Detects the programming language of a [Post] based on tags and content.
  static String detectPostLanguage(Post post) {
    final content = post.content.toLowerCase();
    final tags = post.tags.map((t) => t.toLowerCase()).toList();
    if (tags.contains('python') ||
        content.contains('def ') ||
        content.contains('import ')) {
      return 'python';
    }
    if (tags.contains('typescript') || tags.contains('nestjs'))
      return 'typescript';
    if (tags.contains('javascript') || tags.contains('react'))
      return 'javascript';
    if (tags.contains('dart') || tags.contains('flutter')) return 'dart';
    if (tags.contains('go') || tags.contains('golang')) return 'go';
    if (tags.contains('rust')) return 'rust';
    return 'code';
  }

  // ── Markdown stripping ─────────────────────────────────────────────────────

  /// Returns a plain-text preview from markdown [content].
  ///
  /// Strips code blocks, markdown syntax, and collapses whitespace.
  static String previewFromMarkdown(String content) {
    return content
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAll(RegExp(r'[#*_`]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ── Code snippet detection ─────────────────────────────────────────────────

  /// Returns true if [content] appears to contain a code snippet.
  static bool hasCodeSnippet(String content) {
    return content.contains(RegExp(r'```|`[^`]+`')) ||
        content.contains('const ') ||
        content.contains('function ') ||
        content.contains('class ') ||
        content.contains('import ') ||
        content.contains('def ');
  }
}

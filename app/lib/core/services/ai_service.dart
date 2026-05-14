import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import 'app_preferences.dart';
import 'api_service.dart';

class AiService {
  AiService._();

  static final AiService instance = AiService._();

  Future<AiCodeReview> reviewCode({
    required String code,
    required String language,
  }) async {
    final locale = _currentLocaleCode();
    try {
      final response = await ApiService.instance.post(
        ApiEndpoints.aiCodeReview,
        {'code': code, 'language': language.toLowerCase(), 'locale': locale},
      );
      return AiCodeReview.fromJson(response);
    } catch (error) {
      debugPrint('AiService.reviewCode failed: $error');
      rethrow;
    }
  }

  Future<AiCodeExplanation> explainCode({
    required String code,
    required String language,
    String level = 'intermediate',
  }) async {
    final locale = _currentLocaleCode();
    try {
      final response = await ApiService.instance.post(ApiEndpoints.aiExplain, {
        'code': code,
        'language': language.toLowerCase(),
        'level': level,
        'locale': locale,
      });
      return AiCodeExplanation.fromJson(response);
    } catch (error) {
      debugPrint('AiService.explainCode failed: $error');
      rethrow;
    }
  }

  // --- Streaming AI responses (SSE) ---

  /// Stream a code review from the AI worker, emitting partial text as it arrives.
  Stream<String> streamCodeReview({
    required String code,
    required String language,
  }) {
    final locale = _currentLocaleCode();
    return ApiService.instance.streamSse(
      ApiEndpoints.aiCodeReviewStream,
      body: {
        'code': code,
        'language': language.toLowerCase(),
        'locale': locale,
      },
    );
  }

  /// Stream a code explanation from the AI worker, emitting partial text.
  Stream<String> streamExplainCode({
    required String code,
    required String language,
    String level = 'intermediate',
  }) {
    final locale = _currentLocaleCode();
    return ApiService.instance.streamSse(
      ApiEndpoints.aiExplainStream,
      body: {
        'code': code,
        'language': language.toLowerCase(),
        'level': level,
        'locale': locale,
      },
    );
  }

}

class AiCodeReview {
  AiCodeReview({
    required this.score,
    required this.summary,
    required this.issues,
  });

  final int score;
  final String summary;
  final List<AiReviewIssue> issues;

  factory AiCodeReview.fromJson(Map<String, dynamic> json) {
    final issues =
        (json['issues'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AiReviewIssue.fromJson)
            .toList();

    if (json['summary'] == null || json['score'] == null) {
      throw const FormatException('Invalid AI review response shape.');
    }

    return AiCodeReview(
      score: (json['score'] as num?)?.toInt() ?? 8,
      summary:
          json['summary']?.toString() ??
          _localized(
            _currentLocaleCode(),
            'The snippet is structurally sound with a few follow-up suggestions.',
            'Đoạn code nhìn ổn về cấu trúc và chỉ còn vài gợi ý cần xử lý.',
          ),
      issues: issues,
    );
  }
}

class AiReviewIssue {
  AiReviewIssue({
    required this.type,
    required this.severity,
    required this.line,
    required this.message,
    required this.fix,
  });

  final String type;
  final String severity;
  final int line;
  final String message;
  final String fix;

  factory AiReviewIssue.fromJson(Map<String, dynamic> json) {
    return AiReviewIssue(
      type: json['type']?.toString() ?? 'quality',
      severity: json['severity']?.toString() ?? 'low',
      line: (json['line'] as num?)?.toInt() ?? 1,
      message: json['message']?.toString() ?? 'Suggested improvement.',
      fix: json['fix']?.toString() ?? 'Refine this block before sharing it.',
    );
  }
}

class AiCodeExplanation {
  AiCodeExplanation({
    required this.level,
    required this.explanation,
    required this.concepts,
    required this.complexity,
    required this.alternatives,
  });

  final String level;
  final String explanation;
  final List<String> concepts;
  final String complexity;
  final List<String> alternatives;

  factory AiCodeExplanation.fromJson(Map<String, dynamic> json) {
    final concepts =
        (json['concepts'] as List? ?? const [])
            .map((item) => item.toString())
            .toList();
    final alternatives =
        (json['alternatives'] as List? ?? const [])
            .map((item) => item.toString())
            .toList();

    if (json['explanation'] == null) {
      throw const FormatException('Invalid AI explanation response shape.');
    }

    return AiCodeExplanation(
      level: json['level']?.toString() ?? 'intermediate',
      explanation:
          json['explanation']?.toString() ??
          _localized(
            _currentLocaleCode(),
            'This snippet executes a focused workflow step by step.',
            'Đoạn code này thực thi một luồng xử lý nhỏ theo từng bước.',
          ),
      concepts: concepts,
      complexity:
          json['complexity']?.toString() ??
          _localized(
            _currentLocaleCode(),
            'Linear in the number of processed lines.',
            'Tuyến tính theo số dòng được xử lý.',
          ),
      alternatives: alternatives,
    );
  }
}


String _currentLocaleCode() {
  try {
    return AppPreferences.instance.languageCode;
  } catch (_) {
    return 'en';
  }
}

String _localized(String locale, String en, String vi) {
  return locale == 'vi' ? vi : en;
}

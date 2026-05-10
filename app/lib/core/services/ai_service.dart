import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../models/models.dart';
import 'api_service.dart';

class AiService {
  AiService._();

  static final AiService instance = AiService._();

  Future<AiCodeReview> reviewCode({
    required String code,
    required String language,
  }) async {
    try {
      final response = await ApiService.instance.post(
        ApiEndpoints.aiCodeReview,
        {'code': code, 'language': language.toLowerCase()},
      );
      return AiCodeReview.fromJson(response, fallbackCode: code);
    } catch (error) {
      debugPrint('AiService.reviewCode fallback: $error');
      return AiCodeReview.fallback(code: code, language: language);
    }
  }

  Future<AiCodeExplanation> explainCode({
    required String code,
    required String language,
    String level = 'intermediate',
  }) async {
    try {
      final response = await ApiService.instance.post(ApiEndpoints.aiExplain, {
        'code': code,
        'language': language.toLowerCase(),
        'level': level,
      });
      return AiCodeExplanation.fromJson(response, fallbackCode: code);
    } catch (error) {
      debugPrint('AiService.explainCode fallback: $error');
      return AiCodeExplanation.fallback(
        code: code,
        language: language,
        level: level,
      );
    }
  }

  Future<List<AiMentorMatch>> matchMentors({
    required User currentUser,
    required List<User> mentors,
    List<String> goals = const [],
  }) async {
    try {
      final response = await ApiService.instance.post(
        ApiEndpoints.aiMentorshipMatch,
        {
          'user': {
            'id': currentUser.id,
            'skills': currentUser.skills,
            'goals': goals,
            'reputation': currentUser.reputation,
          },
          'mentors':
              mentors
                  .map(
                    (mentor) => {
                      'id': mentor.id,
                      'skills': mentor.skills,
                      'reputation': mentor.reputation,
                      'followerCount': mentor.followerCount,
                      'bio': mentor.bio,
                    },
                  )
                  .toList(),
        },
      );

      final items = response['matches'];
      if (items is List) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(AiMentorMatch.fromJson)
            .toList();
      }
    } catch (error) {
      debugPrint('AiService.matchMentors fallback: $error');
    }

    return _fallbackMentorMatches(
      currentUser: currentUser,
      mentors: mentors,
      goals: goals,
    );
  }

  List<AiMentorMatch> _fallbackMentorMatches({
    required User currentUser,
    required List<User> mentors,
    required List<String> goals,
  }) {
    final desired = {
      ...currentUser.skills.map((skill) => skill.toLowerCase()),
      ...goals.map((goal) => goal.toLowerCase()),
    };

    final matches =
        mentors.map((mentor) {
          final mentorSkills =
              mentor.skills.map((skill) => skill.toLowerCase()).toSet();
          final overlap =
              desired.isEmpty
                  ? mentorSkills.length.clamp(1, 6) / 6
                  : desired.intersection(mentorSkills).length /
                      desired.length.clamp(1, 999);
          final experienceScore = (mentor.reputation / 3000).clamp(0.35, 1.0);
          final followerScore = (mentor.followerCount / 100).clamp(0.2, 1.0);
          final score =
              ((overlap * 0.55) +
                  (experienceScore * 0.3) +
                  (followerScore * 0.15)) *
              100;

          final reasons = <String>[
            if (desired.intersection(mentorSkills).isNotEmpty)
              'Shared skills: ${desired.intersection(mentorSkills).take(3).join(', ')}',
            'Experience signal: ${mentor.reputation} XP',
            if (mentor.bio != null && mentor.bio!.trim().isNotEmpty)
              mentor.bio!.trim(),
          ];

          return AiMentorMatch(
            mentorId: mentor.id,
            score: score.round().clamp(50, 98),
            label: score >= 85 ? 'Strong fit' : 'Good fit',
            reasons: reasons.take(3).toList(),
          );
        }).toList();

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
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

  factory AiCodeReview.fromJson(
    Map<String, dynamic> json, {
    required String fallbackCode,
  }) {
    final issues =
        (json['issues'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AiReviewIssue.fromJson)
            .toList();

    if (issues.isEmpty && (json['summary'] == null || json['score'] == null)) {
      return AiCodeReview.fallback(code: fallbackCode, language: 'code');
    }

    return AiCodeReview(
      score: (json['score'] as num?)?.toInt() ?? 8,
      summary:
          json['summary']?.toString() ??
          'The snippet is structurally sound with a few follow-up suggestions.',
      issues: issues,
    );
  }

  factory AiCodeReview.fallback({
    required String code,
    required String language,
  }) {
    final issues = <AiReviewIssue>[];
    final lines = code.split('\n');
    if (code.contains('print(') || code.contains('console.log(')) {
      issues.add(
        AiReviewIssue(
          type: 'maintainability',
          severity: 'low',
          line: _firstLineContaining(lines, ['print(', 'console.log(']),
          message: 'Debug output is still in the snippet.',
          fix:
              'Replace ad-hoc prints with structured logging or remove them before shipping.',
        ),
      );
    }
    if (!code.contains('try') && !code.contains('catch') && code.length > 120) {
      issues.add(
        AiReviewIssue(
          type: 'reliability',
          severity: 'medium',
          line: 1,
          message: 'The flow has no obvious error-handling path.',
          fix:
              'Add a guarded execution branch or surface a fallback state for failures.',
        ),
      );
    }
    if (code.contains('TODO') || code.contains('FIXME')) {
      issues.add(
        AiReviewIssue(
          type: 'readiness',
          severity: 'medium',
          line: _firstLineContaining(lines, ['TODO', 'FIXME']),
          message: 'The snippet still contains unresolved placeholders.',
          fix:
              'Resolve or remove TODO/FIXME markers before publishing the example.',
        ),
      );
    }

    final score = (10 -
            issues.fold<int>(0, (sum, issue) {
              switch (issue.severity) {
                case 'high':
                  return sum + 3;
                case 'medium':
                  return sum + 2;
                default:
                  return sum + 1;
              }
            }))
        .clamp(4, 10);

    final summary =
        issues.isEmpty
            ? 'This $language snippet reads cleanly and is ready to share.'
            : 'This $language snippet is close, but it still has a few issues worth fixing before you ship or post it.';

    return AiCodeReview(score: score, summary: summary, issues: issues);
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

  factory AiCodeExplanation.fromJson(
    Map<String, dynamic> json, {
    required String fallbackCode,
  }) {
    final concepts =
        (json['concepts'] as List? ?? const [])
            .map((item) => item.toString())
            .toList();
    final alternatives =
        (json['alternatives'] as List? ?? const [])
            .map((item) => item.toString())
            .toList();

    if ((json['explanation'] == null || concepts.isEmpty) &&
        alternatives.isEmpty) {
      return AiCodeExplanation.fallback(
        code: fallbackCode,
        language: 'code',
        level: json['level']?.toString() ?? 'intermediate',
      );
    }

    return AiCodeExplanation(
      level: json['level']?.toString() ?? 'intermediate',
      explanation:
          json['explanation']?.toString() ??
          'This snippet executes a focused workflow step by step.',
      concepts: concepts,
      complexity:
          json['complexity']?.toString() ??
          'Linear in the number of processed lines.',
      alternatives: alternatives,
    );
  }

  factory AiCodeExplanation.fallback({
    required String code,
    required String language,
    required String level,
  }) {
    final trimmed =
        code
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
    final lineCount = trimmed.length;
    final concepts = <String>[
      if (code.contains('class ')) 'Object modeling',
      if (code.contains('async') || code.contains('await'))
        'Async control flow',
      if (code.contains('for ') || code.contains('while ')) 'Iteration',
      if (code.contains('if ')) 'Branching logic',
      if (code.contains('return')) 'Return value flow',
    ];

    final explanation = switch (level) {
      'beginner' =>
        'This $language snippet is split into $lineCount meaningful lines. It defines a small workflow, runs it from top to bottom, and returns or prints a result at the end.',
      'advanced' =>
        'This $language snippet combines ${concepts.isEmpty ? 'basic control flow' : concepts.join(', ')}. The main tradeoff is readability versus terseness, and the current version favors straightforward execution.',
      _ =>
        'This $language snippet organizes a focused task into $lineCount lines. The code reads top-to-bottom, with each branch or statement contributing directly to the final output.',
    };

    return AiCodeExplanation(
      level: level,
      explanation: explanation,
      concepts:
          concepts.isEmpty ? ['Control flow', 'Data transformation'] : concepts,
      complexity:
          lineCount > 20
              ? 'Mostly linear work with a moderate readability surface.'
              : 'Mostly constant or linear work with low cognitive overhead.',
      alternatives: [
        'Extract reusable pieces into named helpers if this snippet keeps growing.',
        'Add input validation or typed guards if the snippet will handle dynamic data.',
      ],
    );
  }
}

class AiMentorMatch {
  AiMentorMatch({
    required this.mentorId,
    required this.score,
    required this.label,
    required this.reasons,
  });

  final String mentorId;
  final int score;
  final String label;
  final List<String> reasons;

  factory AiMentorMatch.fromJson(Map<String, dynamic> json) {
    return AiMentorMatch(
      mentorId: json['mentorId']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      label: json['label']?.toString() ?? 'Suggested match',
      reasons:
          (json['reasons'] as List? ?? const [])
              .map((item) => item.toString())
              .toList(),
    );
  }
}

int _firstLineContaining(List<String> lines, List<String> needles) {
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (needles.any(line.contains)) {
      return index + 1;
    }
  }
  return 1;
}

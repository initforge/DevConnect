import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../services/ai_service.dart';
import '../theme/app_colors.dart';

Future<void> showAiReviewSheet(
  BuildContext context, {
  required Future<AiCodeReview> reviewFuture,
  String title = 'AI Code Review',
}) {
  final strings = AppStrings.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: FutureBuilder<AiCodeReview>(
            future: reviewFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final review = snapshot.data;
              if (review == null) {
                return _AiErrorState(
                  title: strings.t('ai.unableReview'),
                  subtitle: strings.t('ai.tryUpdateSnippet'),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE8EAF2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: _scoreColor(
                                review.score,
                              ).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${review.score}/10',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _scoreColor(review.score),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              review.summary,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (review.issues.isEmpty)
                      _AiSuccessTile(
                        title: strings.t('ai.noMajorIssues'),
                        subtitle: strings.t('ai.snippetLooksClean'),
                      )
                    else
                      ...review.issues.map(
                        (issue) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE8EAF2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _severityColor(
                                        issue.severity,
                                      ).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      issue.severity.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: _severityColor(issue.severity),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${strings.t('ai.line')} ${issue.line}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                issue.message,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                issue.fix,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

Future<void> showAiExplainSheet(
  BuildContext context, {
  required Future<AiCodeExplanation> explanationFuture,
  String title = 'AI Explain',
}) {
  final strings = AppStrings.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: FutureBuilder<AiCodeExplanation>(
            future: explanationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final explanation = snapshot.data;
              if (explanation == null) {
                return _AiErrorState(
                  title: strings.t('ai.unableExplain'),
                  subtitle: strings.t('ai.tryUpdateSnippet'),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      explanation.level.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      explanation.explanation,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InfoBlock(
                      title: strings.t('ai.concepts'),
                      items: explanation.concepts,
                    ),
                    const SizedBox(height: 12),
                    _InfoBlock(
                      title: strings.t('ai.alternatives'),
                      items: explanation.alternatives,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE8EAF2)),
                      ),
                      child: Text(
                        '${strings.t('ai.complexity')}: ${explanation.complexity}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $item',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiErrorState extends StatelessWidget {
  const _AiErrorState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              size: 34,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiSuccessTile extends StatelessWidget {
  const _AiSuccessTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: AppColors.success),
              SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Streaming AI Sheets (SSE-backed) ----

/// Show a streaming AI code review bottom sheet with progressive text display.
Future<void> showAiReviewStreamSheet(
  BuildContext context, {
  required Stream<String> reviewStream,
  String title = 'AI Code Review',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: StreamBuilder<String>(
            stream: reviewStream,
            builder: (context, snapshot) {
              final strings = AppStrings.current();
              final accumulatedText = _accumulateStreamText(snapshot);

              if (snapshot.connectionState == ConnectionState.waiting &&
                  accumulatedText.isEmpty) {
                return const _StreamingReviewLoading();
              }

              if (snapshot.hasError) {
                return _AiErrorState(
                  title: strings.t('ai.reviewInterrupted'),
                  subtitle: strings.t('ai.connectionLostReview'),
                );
              }

              final isComplete =
                  snapshot.connectionState == ConnectionState.done;
              final parsedReview = _tryParseReviewResult(accumulatedText);

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (parsedReview != null)
                      _renderParsedReview(parsedReview)
                    else
                      _StreamingTextBlock(
                        text: accumulatedText,
                        isComplete: isComplete,
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (!isComplete) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            strings.t('ai.reviewing'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ] else
                          Text(
                            strings.t('ai.reviewComplete'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

/// Show a streaming AI code explanation bottom sheet with progressive text display.
Future<void> showAiExplainStreamSheet(
  BuildContext context, {
  required Stream<String> explainStream,
  String title = 'AI Explain',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: StreamBuilder<String>(
            stream: explainStream,
            builder: (context, snapshot) {
              final strings = AppStrings.current();
              final accumulatedText = _accumulateStreamText(snapshot);

              if (snapshot.connectionState == ConnectionState.waiting &&
                  accumulatedText.isEmpty) {
                return const _StreamingReviewLoading();
              }

              if (snapshot.hasError) {
                return _AiErrorState(
                  title: strings.t('ai.explanationInterrupted'),
                  subtitle: strings.t('ai.connectionLostExplanation'),
                );
              }

              final isComplete =
                  snapshot.connectionState == ConnectionState.done;
              final parsedExplanation = _tryParseExplainResult(accumulatedText);

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (parsedExplanation != null)
                      _renderParsedExplanation(parsedExplanation)
                    else
                      _StreamingTextBlock(
                        text: accumulatedText,
                        isComplete: isComplete,
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (!isComplete) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            strings.t('ai.explaining'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ] else
                          Text(
                            strings.t('ai.explanationComplete'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

// ---- Streaming helpers ----

/// Accumulate all received text from a Stream snapshot.
String _accumulateStreamText(AsyncSnapshot<String> snapshot) {
  if (snapshot.hasData) return snapshot.data ?? '';
  return '';
}

/// Attempt to parse the accumulated streaming text as a JSON review result.
/// Returns null if the text is not yet valid JSON or is still streaming.
Map<String, dynamic>? _tryParseReviewResult(String text) {
  if (text.isEmpty) return null;
  try {
    final parsed = _extractLastJsonObject(text);
    if (parsed != null && parsed.containsKey('score')) {
      return parsed;
    }
  } catch (_) {
    // Not yet valid JSON — still streaming
  }
  return null;
}

/// Attempt to parse the accumulated streaming text as a JSON explanation result.
Map<String, dynamic>? _tryParseExplainResult(String text) {
  if (text.isEmpty) return null;
  try {
    final parsed = _extractLastJsonObject(text);
    if (parsed != null && parsed.containsKey('explanation')) {
      return parsed;
    }
  } catch (_) {
    return null;
  }
  return null;
}

/// Extract the last valid JSON object from potentially partial streaming text.
Map<String, dynamic>? _extractLastJsonObject(String text) {
  final firstOpenBrace = text.indexOf('{');
  final lastCloseBrace = text.lastIndexOf('}');
  if (firstOpenBrace == -1 || lastCloseBrace <= firstOpenBrace) return null;

  final candidate = text.substring(firstOpenBrace, lastCloseBrace + 1);

  try {
    final parsed = jsonDecode(candidate);
    return parsed is Map<String, dynamic> ? parsed : null;
  } catch (_) {
    return null;
  }
}

Widget _renderParsedReview(Map<String, dynamic> parsed) {
  final strings = AppStrings.current();
  final score = (parsed['score'] as num?)?.toInt() ?? 7;
  final summary =
      parsed['summary']?.toString() ?? strings.t('ai.reviewComplete');
  final issues =
      (parsed['issues'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (issue) => AiReviewIssue(
              type: issue['type']?.toString() ?? 'info',
              severity: issue['severity']?.toString() ?? 'low',
              line: (issue['line'] as num?)?.toInt() ?? 1,
              message: issue['message']?.toString() ?? '',
              fix: issue['fix']?.toString() ?? '',
            ),
          )
          .toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EAF2)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _scoreColor(score).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$score/10',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _scoreColor(score),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                summary,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (issues.isEmpty)
        _AiSuccessTile(
          title: strings.t('ai.noMajorIssues'),
          subtitle: strings.t('ai.snippetLooksClean'),
        )
      else
        ...issues.map(
          (issue) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8EAF2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _severityColor(
                          issue.severity,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        issue.severity.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _severityColor(issue.severity),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${strings.t('ai.line')} ${issue.line}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  issue.message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  issue.fix,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

Widget _renderParsedExplanation(Map<String, dynamic> parsed) {
  final strings = AppStrings.current();
  final level = parsed['level']?.toString() ?? 'intermediate';
  final explanation =
      parsed['explanation']?.toString() ?? strings.t('ai.explanationComplete');
  final concepts =
      (parsed['concepts'] as List? ?? const [])
          .map((e) => e.toString())
          .toList();
  final complexity = parsed['complexity']?.toString() ?? '';
  final alternatives =
      (parsed['alternatives'] as List? ?? const [])
          .map((e) => e.toString())
          .toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        level.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        explanation,
        style: const TextStyle(
          fontSize: 13,
          height: 1.55,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 14),
      _InfoBlock(title: strings.t('ai.concepts'), items: concepts),
      const SizedBox(height: 12),
      _InfoBlock(title: strings.t('ai.alternatives'), items: alternatives),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EAF2)),
        ),
        child: Text(
          '${strings.t('ai.complexity')}: $complexity',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _StreamingReviewLoading extends StatelessWidget {
  const _StreamingReviewLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.current().t('ai.thinking'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamingTextBlock extends StatelessWidget {
  const _StreamingTextBlock({required this.text, required this.isComplete});

  final String text;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.isEmpty ? AppStrings.current().t('ai.waitingResponse') : text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
          if (!isComplete) const _TypingIndicator(),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final opacity =
              0.3 + 0.7 * (0.5 + 0.5 * (_controller.value * 2 - 1).abs());
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StreamingDot(0.0, opacity),
              _StreamingDot(0.15, opacity),
              _StreamingDot(0.3, opacity),
              const SizedBox(width: 6),
              Text(
                AppStrings.current().t('ai.typing'),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary.withValues(alpha: opacity),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StreamingDot extends StatelessWidget {
  const _StreamingDot(this.delay, this.opacity);

  final double delay;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

Color _scoreColor(int score) {
  if (score >= 8) return AppColors.success;
  if (score >= 6) return AppColors.warning;
  return AppColors.error;
}

Color _severityColor(String severity) {
  switch (severity) {
    case 'high':
      return AppColors.error;
    case 'medium':
      return AppColors.warning;
    default:
      return AppColors.success;
  }
}

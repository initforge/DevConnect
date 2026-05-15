import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Summary card showing hiring pulse metrics (open roles, remote, avg match).
class JobsSummary extends StatelessWidget {
  const JobsSummary({
    super.key,
    required this.totalJobs,
    required this.remoteJobs,
    required this.avgMatch,
  });

  final int totalJobs;
  final int remoteJobs;
  final int avgMatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_history_outlined, color: Color(0xFF5B53F6)),
              const SizedBox(width: 8),
              Text(
                AppStrings.of(context).t('jobs.hiringPulse'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: JobMetricTile(
                  value: '$totalJobs',
                  label: AppStrings.of(context).t('jobs.openRoles'),
                  tint: const Color(0xFFEFF3FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: JobMetricTile(
                  value: '$remoteJobs',
                  label: AppStrings.of(context).t('jobs.remote'),
                  tint: const Color(0xFFECFDF5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: JobMetricTile(
                  value: '$avgMatch%',
                  label: AppStrings.of(context).t('jobs.avgMatch'),
                  tint: const Color(0xFFF5F3FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single metric tile used inside [JobsSummary].
class JobMetricTile extends StatelessWidget {
  const JobMetricTile({
    super.key,
    required this.value,
    required this.label,
    required this.tint,
  });

  final String value;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

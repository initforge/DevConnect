import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/job_repository.dart';

class JobBoardScreen extends StatefulWidget {
  const JobBoardScreen({super.key});

  @override
  State<JobBoardScreen> createState() => _JobBoardScreenState();
}

class _JobBoardScreenState extends State<JobBoardScreen> {
  final _repository = JobRepository();
  late Future<List<dynamic>> _loader;
  final Set<String> _appliedJobs = {};

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  void _loadFeeds() {
    _loader = _repository.getJobs();
  }

  Future<void> _refresh() async {
    _loadFeeds();
    if (!mounted) return;
    setState(() {});
    await _loader;
  }

  Future<void> _applyForJob(String jobId) async {
    if (!ApiService.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long dang nhap de ung tuyen')),
      );
      return;
    }
    if (_appliedJobs.contains(jobId)) return;

    try {
      final success = await _repository.applyForJob(jobId);
      if (success && mounted) {
        setState(() => _appliedJobs.add(jobId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Da ung tuyen thanh cong!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Khong the ung tuyen. Vui long thu lai.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tuyen dung')),
      body: FutureBuilder<List<dynamic>>(
        future: _loader,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  ErrorState(
                    message: 'Da xay ra loi khi tai viec lam.\nVui long thu lai.',
                    onRetry: _refresh,
                  ),
                ],
              ),
            );
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return const EmptyState(
              icon: Icons.work_outline,
              title: 'Chua co viec lam nao',
              subtitle: 'Hay quay lai sau.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final job = jobs[index];
                final isApplied = _appliedJobs.contains(job.id);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                job.company[0],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  job.company,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${job.matchPercent}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: job.techStack.map<Widget>((tech) => TechChip(label: tech)).toList(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            job.remote ? Icons.home_outlined : Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${job.location}${job.remote ? ' - Remote' : ''}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.payments_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            job.salaryRange,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _applyForJob(job.id),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isApplied
                                ? AppColors.success.withValues(alpha: 0.1)
                                : null,
                            side: BorderSide(
                              color: isApplied ? AppColors.success : AppColors.border,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            isApplied ? 'Da ung tuyen' : 'Ung tuyen ngay',
                            style: TextStyle(
                              color: isApplied ? AppColors.success : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

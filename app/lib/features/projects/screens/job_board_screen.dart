import 'package:flutter/material.dart';

import '../../../core/constants/routes.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/job_repository.dart';

class JobBoardScreen extends StatefulWidget {
  const JobBoardScreen({super.key});

  @override
  State<JobBoardScreen> createState() => _JobBoardScreenState();
}

class _JobBoardScreenState extends State<JobBoardScreen> {
  final _repository = JobRepository();
  late Future<List<Job>> _loader;
  final Set<String> _appliedJobs = <String>{};
  int _selectedFilter = 0;
  bool _remoteOnly = false;

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

  Future<void> _applyForJob(Job job) async {
    if (!ApiService.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to apply for jobs')),
      );
      return;
    }

    if (_appliedJobs.contains(job.id)) return;

    try {
      final success = await _repository.applyForJob(job.id);
      if (!mounted || !success) return;
      setState(() => _appliedJobs.add(job.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Applied to ${job.company}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application failed. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      bottomNavigationBar: AppBottomNavBar(
        items: [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            route: AppRoutes.home,
          ),
          AppBottomNavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: 'Explore',
            route: AppRoutes.explore,
          ),
          AppBottomNavItem(
            icon: Icons.business_center_outlined,
            selectedIcon: Icons.business_center,
            label: 'Jobs',
            route: AppRoutes.jobs,
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            route: AppRoutes.profile,
          ),
        ],
        selectedIndex: 2,
        currentRoute: AppRoutes.jobs,
        centerCreate: true,
      ),
      appBar: AppBar(
        title: const Text(
          'Jobs',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<Job>>(
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
                    message: 'Unable to load jobs.\nPull to try again.',
                    onRetry: _refresh,
                  ),
                ],
              ),
            );
          }

          final jobs = snapshot.data ?? const <Job>[];
          final filtered = _filteredJobs(jobs);

          if (jobs.isEmpty) {
            return const EmptyState(
              icon: Icons.work_outline,
              title: 'No jobs available',
              subtitle: 'Check back later for new openings.',
            );
          }

          final remoteJobs = jobs.where((job) => job.remote).length;
          final avgMatch =
              jobs.isEmpty
                  ? 0
                  : jobs
                          .map((job) => job.matchPercent)
                          .reduce((a, b) => a + b) ~/
                      jobs.length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.getContentMaxWidth(context),
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                  children: [
                    _JobsSummary(
                      totalJobs: jobs.length,
                      remoteJobs: remoteJobs,
                      avgMatch: avgMatch,
                    ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SegmentedFilters(
                        labels: const ['Top match', 'Recent', 'Senior'],
                        selected: _selectedFilter,
                        onSelected:
                            (value) => setState(() => _selectedFilter = value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8EAF2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Remote',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Switch(
                            value: _remoteOnly,
                            onChanged:
                                (value) => setState(() => _remoteOnly = value),
                            activeColor: const Color(0xFF16C784),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...filtered.map(
                  (job) => _JobCard(
                    job: job,
                    applied: _appliedJobs.contains(job.id),
                    onApply: () => _applyForJob(job),
                  ),
                ),
              ],
              ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Job> _filteredJobs(List<Job> jobs) {
    var filtered = jobs;

    if (_remoteOnly) {
      filtered = filtered.where((job) => job.remote).toList();
    }

    switch (_selectedFilter) {
      case 1:
        filtered = [...filtered]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 2:
        filtered =
            filtered
                .where((job) => job.experience.toLowerCase().contains('senior'))
                .toList();
        break;
      default:
        filtered = [...filtered]
          ..sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    }

    return filtered;
  }
}

class _JobsSummary extends StatelessWidget {
  const _JobsSummary({
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
          const Row(
            children: [
              Icon(Icons.work_history_outlined, color: Color(0xFF5B53F6)),
              SizedBox(width: 8),
              Text(
                'Hiring pulse',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  value: '$totalJobs',
                  label: 'Open roles',
                  tint: const Color(0xFFEFF3FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  value: '$remoteJobs',
                  label: 'Remote',
                  tint: const Color(0xFFECFDF5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  value: '$avgMatch%',
                  label: 'Avg match',
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.applied,
    required this.onApply,
  });

  final Job job;
  final bool applied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  job.company.isEmpty ? '?' : job.company[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5B53F6),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      job.company,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${job.matchPercent}% match',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                job.techStack.map((tech) => TechChip(label: tech)).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _JobMeta(
                icon:
                    job.remote
                        ? Icons.home_work_outlined
                        : Icons.location_on_outlined,
                label: '${job.location}${job.remote ? ' · Remote' : ''}',
              ),
              _JobMeta(icon: Icons.payments_outlined, label: job.salaryRange),
              _JobMeta(icon: Icons.timeline_outlined, label: job.experience),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: applied ? null : onApply,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    applied ? const Color(0xFFECFDF5) : const Color(0xFF5B53F6),
                foregroundColor: applied ? AppColors.success : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                applied ? 'Applied' : 'Apply now',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobMeta extends StatelessWidget {
  const _JobMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SegmentedFilters extends StatelessWidget {
  const _SegmentedFilters({
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        active
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

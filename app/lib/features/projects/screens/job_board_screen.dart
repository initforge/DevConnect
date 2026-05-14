import 'package:flutter/material.dart';

import '../../../core/constants/routes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/decorative_widgets.dart';
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
  bool _remoteOnly = false;

  String _searchQuery = '';
  String _selectedLevel = '';
  String _selectedTech = '';

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
        SnackBar(content: Text(AppStrings.of(context).t('jobs.signInToApply'))),
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
      ).showSnackBar(SnackBar(content: Text('${AppStrings.of(context).t('jobs.applied')} - ${job.company}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).t('jobs.applicationFailed'))),
      );
    }
  }

  Future<void> _openPostJobSheet() async {
    if (!ApiService.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).t('jobs.signInToApply'))),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    final experienceCtrl = TextEditingController();
    final techCtrl = TextEditingController();
    bool remote = false;
    String? error;
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              final title = titleCtrl.text.trim();
              final company = companyCtrl.text.trim();
              if (title.isEmpty || company.isEmpty) {
                setSheetState(() => error = AppStrings.of(context).t('jobs.titleCompanyRequired'));
                return;
              }
              setSheetState(() { saving = true; error = null; });
              try {
                await _repository.createJob(
                  title: title,
                  company: company,
                  location: locationCtrl.text.trim(),
                  remote: remote,
                  salaryRange: salaryCtrl.text.trim(),
                  techStack: techCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  experience: experienceCtrl.text.trim(),
                );
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                if (!mounted) return;
                _loadFeeds();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppStrings.of(context).t('jobs.posted'))),
                );
              } catch (e) {
                setSheetState(() { saving = false; error = e.toString(); });
              }
            }

            InputDecoration decoration(String hint) {
              return InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: const Color(0xFFF7F8FC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF5B53F6))),
              );
            }

            final strings = AppStrings.of(context);
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(strings.t('jobs.postJob'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(strings.t('jobs.postJobSubtitle'), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    TextField(controller: titleCtrl, decoration: decoration(strings.t('jobs.jobTitle'))),
                    const SizedBox(height: 10),
                    TextField(controller: companyCtrl, decoration: decoration(strings.t('jobs.company'))),
                    const SizedBox(height: 10),
                    TextField(controller: locationCtrl, decoration: decoration(strings.t('jobs.location'))),
                    const SizedBox(height: 10),
                    TextField(controller: salaryCtrl, decoration: decoration(strings.t('jobs.salary'))),
                    const SizedBox(height: 10),
                    TextField(controller: experienceCtrl, decoration: decoration(strings.t('jobs.experience'))),
                    const SizedBox(height: 10),
                    TextField(controller: techCtrl, decoration: decoration(strings.t('jobs.techStackHint'))),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(strings.t('jobs.remote'), style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Switch(value: remote, onChanged: (v) => setSheetState(() => remote = v), activeColor: const Color(0xFF16C784)),
                      ],
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(error!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: saving ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B53F6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(strings.t('jobs.postJob'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    companyCtrl.dispose();
    locationCtrl.dispose();
    salaryCtrl.dispose();
    experienceCtrl.dispose();
    techCtrl.dispose();
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
            label: AppStrings.of(context).nav('home'),
            route: AppRoutes.home,
          ),
          AppBottomNavItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: AppStrings.of(context).nav('explore'),
            route: AppRoutes.explore,
          ),
          AppBottomNavItem(
            icon: Icons.business_center_outlined,
            selectedIcon: Icons.business_center,
            label: AppStrings.of(context).nav('jobs'),
            route: AppRoutes.jobs,
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: AppStrings.of(context).nav('profile'),
            route: AppRoutes.profile,
          ),
        ],
        selectedIndex: 2,
        currentRoute: AppRoutes.jobs,
        centerCreate: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPostJobSheet,
        backgroundColor: const Color(0xFF5B53F6),
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add, size: 20),
        label: Text(AppStrings.of(context).t('jobs.postJob'), style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.06),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: Text(
          AppStrings.of(context).t('jobs.title'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                    message: AppStrings.of(context).t('jobs.unableLoad'),
                    onRetry: _refresh,
                  ),
                ],
              ),
            );
          }

          final jobs = snapshot.data ?? const <Job>[];
          final filtered = _filteredJobs(jobs);

          if (jobs.isEmpty) {
            return EmptyState(
              icon: Icons.work_outline,
              title: AppStrings.of(context).t('jobs.noJobs'),
              subtitle: AppStrings.of(context).t('jobs.noJobsSubtitle'),
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
                // Search bar
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: AppStrings.of(context).t('jobs.search'),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8EAF2))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8EAF2))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF5B53F6))),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter row: Level + Tech + Remote
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterDropdown(
                        value: _selectedLevel,
                        items: [
                          _FilterItem('', AppStrings.of(context).t('jobs.allLevels')),
                          _FilterItem('junior', AppStrings.of(context).t('jobs.junior')),
                          _FilterItem('mid', AppStrings.of(context).t('jobs.mid')),
                          _FilterItem('senior', AppStrings.of(context).t('jobs.senior')),
                        ],
                        onChanged: (v) => setState(() => _selectedLevel = v),
                      ),
                      const SizedBox(width: 8),
                      _FilterDropdown(
                        value: _selectedTech,
                        items: [
                          _FilterItem('', AppStrings.of(context).t('jobs.filterTech')),
                          ..._extractTechTags(jobs).map((t) => _FilterItem(t, t)),
                        ],
                        onChanged: (v) => setState(() => _selectedTech = v),
                      ),
                      const SizedBox(width: 8),
                      _RemoteToggleChip(
                        active: _remoteOnly,
                        label: AppStrings.of(context).t('jobs.remote'),
                        onTap: () => setState(() => _remoteOnly = !_remoteOnly),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Match % explanation
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    AppStrings.of(context).t('jobs.matchExplain'),
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  ),
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

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((job) =>
        job.title.toLowerCase().contains(q) ||
        job.company.toLowerCase().contains(q) ||
        job.techStack.any((t) => t.toLowerCase().contains(q))
      ).toList();
    }

    // Remote
    if (_remoteOnly) {
      filtered = filtered.where((job) => job.remote).toList();
    }

    // Level
    if (_selectedLevel.isNotEmpty) {
      filtered = filtered.where((job) =>
        job.experience.toLowerCase().contains(_selectedLevel)
      ).toList();
    }

    // Tech stack
    if (_selectedTech.isNotEmpty) {
      final tech = _selectedTech.toLowerCase();
      filtered = filtered.where((job) =>
        job.techStack.any((t) => t.toLowerCase() == tech)
      ).toList();
    }

    // Sort by match percent descending
    filtered = [...filtered]..sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return filtered;
  }

  List<String> _extractTechTags(List<Job> jobs) {
    final tags = <String>{};
    for (final job in jobs) {
      for (final tech in job.techStack) {
        tags.add(tech);
      }
    }
    final sorted = tags.toList()..sort();
    return sorted.take(15).toList();
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
          Row(
            children: [
              const Icon(Icons.work_history_outlined, color: Color(0xFF5B53F6)),
              const SizedBox(width: 8),
              Text(
                AppStrings.of(context).t('jobs.hiringPulse'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  value: '$totalJobs',
                  label: AppStrings.of(context).t('jobs.openRoles'),
                  tint: const Color(0xFFEFF3FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  value: '$remoteJobs',
                  label: AppStrings.of(context).t('jobs.remote'),
                  tint: const Color(0xFFECFDF5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
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
                  '${job.matchPercent}% ${AppStrings.of(context).t('jobs.match')}',
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
                applied ? AppStrings.of(context).t('jobs.applied') : AppStrings.of(context).t('jobs.applyNow'),
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

class _FilterItem {
  const _FilterItem(this.value, this.label);
  final String value;
  final String label;
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<_FilterItem> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = items.firstWhere(
      (i) => i.value == value,
      orElse: () => items.first,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: value.isEmpty ? Colors.white : const Color(0xFFEEECFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value.isEmpty ? const Color(0xFFE8EAF2) : const Color(0xFF5B53F6),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.expand_more, size: 18),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: value.isEmpty ? AppColors.textSecondary : const Color(0xFF5B53F6),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item.value,
            child: Text(item.label),
          )).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _RemoteToggleChip extends StatelessWidget {
  const _RemoteToggleChip({
    required this.active,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE6FFF4) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? const Color(0xFF16C784) : const Color(0xFFE8EAF2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi, size: 14, color: active ? const Color(0xFF16C784) : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? const Color(0xFF16C784) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

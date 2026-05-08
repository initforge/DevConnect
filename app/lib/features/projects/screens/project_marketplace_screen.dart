import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/project_repository.dart';

class ProjectMarketplaceScreen extends StatefulWidget {
  const ProjectMarketplaceScreen({super.key});

  @override
  State<ProjectMarketplaceScreen> createState() => _ProjectMarketplaceScreenState();
}

class _ProjectMarketplaceScreenState extends State<ProjectMarketplaceScreen> {
  final _repository = ProjectRepository();
  late Future<List<dynamic>> _loader;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  void _loadFeeds() {
    _loader = _repository.getProjects();
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    _loadFeeds();
    if (!mounted) return;
    setState(() {});
    await _loader;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sàn dự án')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo dự án mới sẽ triển khai ở phase sau')),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tạo dự án'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
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
                    message: 'Đã xảy ra lỗi khi tải dự án.\nVui lòng thử lại.',
                    onRetry: _refresh,
                  ),
                ],
              ),
            );
          }

          final projects = snapshot.data ?? const [];

          if (projects.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_outlined,
              title: 'Chưa có dự án nào',
              subtitle: 'Hãy tạo dự án đầu tiên.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final project = projects[index];
                final isLooking = project.status == 'LOOKING_FOR_MEMBERS';
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLooking ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          UserAvatar(name: project.owner.displayName, size: 36, isOnline: project.owner.isOnline),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(project.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                Text(project.owner.displayName, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isLooking ? AppColors.accent : AppColors.primary).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isLooking ? 'Tuyển' : 'Hoạt động',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isLooking ? AppColors.accent : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(project.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 6, children: project.techStack.map<Widget>((tech) => TechChip(label: tech)).toList()),
                      const SizedBox(height: 10),
                      Text(
                        '${project.memberCount}/${project.maxMembers} thành viên',
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
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

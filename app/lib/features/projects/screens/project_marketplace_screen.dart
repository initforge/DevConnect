import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/constants/routes.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/project_repository.dart';

part 'project_marketplace_widgets.dart';

const bool _kScreenshotMode = AppRuntimeConfig.screenshotMode;

class ProjectMarketplaceScreen extends StatefulWidget {
  const ProjectMarketplaceScreen({super.key});

  @override
  State<ProjectMarketplaceScreen> createState() =>
      _ProjectMarketplaceScreenState();
}

class _ProjectMarketplaceScreenState extends State<ProjectMarketplaceScreen> {
  final _repository = ProjectRepository();
  late Future<List<Project>> _loader;
  final Set<String> _joinedProjects = <String>{};
  int _selectedFilter = 0;

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

  Future<void> _joinProject(Project project) async {
    if (_joinedProjects.contains(project.id)) return;
    HapticFeedback.lightImpact();

    try {
      final joined = await _repository.joinProject(project.id);
      if (!mounted || !joined) return;
      setState(() => _joinedProjects.add(project.id));
      _loadFeeds();
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Joined ${project.title}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to join project right now')),
      );
    }
  }

  Future<void> _openCreateProjectSheet() async {
    if (!ApiService.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to create a project')),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final techStackCtrl = TextEditingController();
    final maxMembersCtrl = TextEditingController(text: '5');
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
              final description = descriptionCtrl.text.trim();
              final techStack =
                  techStackCtrl.text
                      .split(',')
                      .map((item) => item.trim())
                      .where((item) => item.isNotEmpty)
                      .take(8)
                      .toList();
              final maxMembers = int.tryParse(maxMembersCtrl.text.trim()) ?? 5;

              if (title.isEmpty || description.isEmpty) {
                setSheetState(
                  () => error = 'Title and description are required',
                );
                return;
              }

              setSheetState(() {
                saving = true;
                error = null;
              });

              try {
                await _repository.createProject(
                  title: title,
                  description: description,
                  techStack: techStack,
                  maxMembers: maxMembers,
                );
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                if (!mounted) return;
                _loadFeeds();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project created')),
                );
              } catch (e) {
                setSheetState(() {
                  saving = false;
                  error = e.toString();
                });
              }
            }

            InputDecoration decoration(String hint) {
              return InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: const Color(0xFFF4F6FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Project',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set up a new collaboration workspace for the community.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: decoration('Project title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionCtrl,
                    minLines: 3,
                    maxLines: 4,
                    decoration: decoration('Describe what you are building'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: techStackCtrl,
                    decoration: decoration('Tech stack (comma separated)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: maxMembersCtrl,
                    keyboardType: TextInputType.number,
                    decoration: decoration('Max members'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: saving ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child:
                          saving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Create project'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    descriptionCtrl.dispose();
    techStackCtrl.dispose();
    maxMembersCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_kScreenshotMode) {
      return const _ShowcaseProjectMarketplaceScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Project>>(
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.28),
                  ErrorState(
                    message: 'Unable to load projects.\nPull to try again.',
                    onRetry: _refresh,
                  ),
                ],
              ),
            );
          }

          final projects = snapshot.data ?? const <Project>[];
          final filtered = _filteredProjects(projects);

          if (projects.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_open_outlined,
              title: 'No projects yet',
              subtitle: 'Create the first project to start collaborating.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.getContentMaxWidth(context),
              ),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Projects',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(Icons.search, size: 18),
                      SizedBox(width: 12),
                      Icon(Icons.tune, size: 18),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ShowcaseFilterChip(
                        label: 'All',
                        selected: _selectedFilter == 0,
                        onTap: () => setState(() => _selectedFilter = 0),
                      ),
                      _ShowcaseFilterChip(
                        label: 'Looking for Devs',
                        selected: _selectedFilter == 1,
                        onTap: () => setState(() => _selectedFilter = 1),
                      ),
                      _ShowcaseFilterChip(
                        label: 'Open Source',
                        selected: _selectedFilter == 2,
                        onTap: () => setState(() => _selectedFilter = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...filtered.map(
                    (project) => _ProjectCard(
                      project: project,
                      joined: _joinedProjects.contains(project.id),
                      onJoin: () => _joinProject(project),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Project> _filteredProjects(List<Project> projects) {
    switch (_selectedFilter) {
      case 1:
        return projects
            .where((project) => project.status == 'LOOKING_FOR_MEMBERS')
            .toList();
      case 2:
        return projects
            .where((project) => project.status != 'LOOKING_FOR_MEMBERS')
            .toList();
      default:
        return projects;
    }
  }
}

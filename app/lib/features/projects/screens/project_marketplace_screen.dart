import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/constants/routes.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/decorative_widgets.dart';
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
  String _searchQuery = '';
  String _selectedTech = '';

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  void _loadFeeds() {
    _loader = _repository.getProjects();
  }

  Future<void> _refresh() async {
    unawaited(HapticFeedback.mediumImpact());
    _loadFeeds();
    if (!mounted) return;
    setState(() {});
    await _loader;
  }

  Future<void> _joinProject(Project project) async {
    if (_joinedProjects.contains(project.id)) return;
    unawaited(HapticFeedback.lightImpact());

    try {
      final joined = await _repository.joinProject(project.id);
      if (!mounted || !joined) return;
      setState(() => _joinedProjects.add(project.id));
      _loadFeeds();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.current().t('projects.joined')} ${project.title}',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.current().t('projects.unableJoin'))),
      );
    }
  }

  Future<void> _openCreateProjectSheet() async {
    if (!ApiService.instance.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.current().t('projects.unableJoin'))),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                  () =>
                      error = AppStrings.of(
                        context,
                      ).t('projects.titleDescRequired'),
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
                  SnackBar(
                    content: Text(AppStrings.of(context).t('projects.created')),
                  ),
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
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
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
                  Text(
                    AppStrings.of(context).t('projects.createProject'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.of(context).t('projects.createSubtitle'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: decoration(
                      AppStrings.of(context).t('projects.projectTitle'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionCtrl,
                    minLines: 3,
                    maxLines: 4,
                    decoration: decoration(
                      AppStrings.of(context).t('projects.projectDescription'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: techStackCtrl,
                    decoration: decoration(
                      AppStrings.of(context).t('projects.techStack'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: maxMembersCtrl,
                    keyboardType: TextInputType.number,
                    decoration: decoration(
                      AppStrings.of(context).t('projects.maxMembers'),
                    ),
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
                              : Text(
                                AppStrings.of(context).t('projects.create'),
                              ),
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
    if (_kScreenshotMode && kDebugMode) {
      return const _ShowcaseProjectMarketplaceScreen();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.06),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: Text(
          AppStrings.of(context).t('projects.title'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateProjectSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          AppStrings.of(context).t('projects.createProject'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<Project>>(
        future: _loader,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
              itemCount: 4,
              itemBuilder: (_, __) => const ProjectCardSkeleton(),
            );
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.28),
                  ErrorState(
                    message: AppStrings.of(context).t('projects.unableLoad'),
                    onRetry: _refresh,
                  ),
                ],
              ),
            );
          }

          final projects = snapshot.data ?? const <Project>[];
          final filtered = _filteredProjects(projects);

          if (projects.isEmpty) {
            return EmptyState(
              icon: Icons.folder_open_outlined,
              title: AppStrings.of(context).t('projects.noProjects'),
              subtitle: AppStrings.of(context).t('projects.noProjectsSubtitle'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: DecorativeBackground(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.getContentMaxWidth(context),
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
                  children: [
                    ScreenGradientHeader(
                      title: AppStrings.of(context).t('projects.marketplace'),
                      subtitle: AppStrings.of(
                        context,
                      ).t('projects.marketplaceSubtitle'),
                      icon: Icons.rocket_launch_outlined,
                      gradientColors: const [
                        Color(0xFF5B53F6),
                        Color(0xFF00D9A6),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Search bar
                    TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: AppStrings.of(
                          context,
                        ).t('explore.searchPlaceholder'),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Status filter chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ShowcaseFilterChip(
                          label: AppStrings.of(context).t('projects.all'),
                          selected: _selectedFilter == 0,
                          onTap: () => setState(() => _selectedFilter = 0),
                        ),
                        _ShowcaseFilterChip(
                          label: AppStrings.of(
                            context,
                          ).t('projects.lookingForDevs'),
                          selected: _selectedFilter == 1,
                          onTap: () => setState(() => _selectedFilter = 1),
                        ),
                        _ShowcaseFilterChip(
                          label: AppStrings.of(
                            context,
                          ).t('projects.openSource'),
                          selected: _selectedFilter == 2,
                          onTap: () => setState(() => _selectedFilter = 2),
                        ),
                        // Tech stack filter badges (dynamic from data)
                        ..._extractTechTags(projects).map(
                          (tag) => _ShowcaseFilterChip(
                            label: tag,
                            selected: _selectedTech == tag,
                            onTap:
                                () => setState(
                                  () =>
                                      _selectedTech =
                                          _selectedTech == tag ? '' : tag,
                                ),
                          ),
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
            ),
          );
        },
      ),
    );
  }

  List<Project> _filteredProjects(List<Project> projects) {
    var filtered = projects;

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered =
          filtered
              .where(
                (project) =>
                    project.title.toLowerCase().contains(q) ||
                    project.description.toLowerCase().contains(q) ||
                    project.techStack.any((t) => t.toLowerCase().contains(q)),
              )
              .toList();
    }

    // Tech stack filter
    if (_selectedTech.isNotEmpty) {
      final tech = _selectedTech.toLowerCase();
      filtered =
          filtered
              .where(
                (project) =>
                    project.techStack.any((t) => t.toLowerCase() == tech),
              )
              .toList();
    }

    // Status filter
    switch (_selectedFilter) {
      case 1:
        return filtered
            .where((project) => project.status == 'LOOKING_FOR_MEMBERS')
            .toList();
      case 2:
        return filtered
            .where((project) => project.status != 'LOOKING_FOR_MEMBERS')
            .toList();
      default:
        return filtered;
    }
  }

  List<String> _extractTechTags(List<Project> projects) {
    final tags = <String>{};
    for (final project in projects) {
      for (final tech in project.techStack) {
        tags.add(tech);
      }
    }
    final sorted = tags.toList()..sort();
    return sorted.take(10).toList();
  }
}

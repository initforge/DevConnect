import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/models/models.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/decorative_widgets.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/project_repository.dart';

const bool _kScreenshotMode = AppRuntimeConfig.screenshotMode;

/// Represents the join/leave lifecycle for a project.
enum JoinState { notJoined, joining, joined, leaving }

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final Project? initialProject;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.initialProject,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _repository = ProjectRepository();
  late Future<Project?> _detailLoader;
  Future<List<Map<String, dynamic>>>? _membersLoader;
  JoinState _joinState = JoinState.notJoined;

  @override
  void initState() {
    super.initState();
    _detailLoader =
        widget.initialProject != null
            ? Future.value(widget.initialProject)
            : _repository.getProjectById(widget.projectId);
    _loadMembers();
  }

  void _loadMembers() {
    _membersLoader = _repository.getProjectMembers(widget.projectId);
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    _detailLoader = _repository.getProjectById(widget.projectId);
    _loadMembers();
    if (!mounted) return;
    setState(() {});
    await _detailLoader;
  }

  Future<void> _joinProject() async {
    if (_joinState == JoinState.joining || _joinState == JoinState.joined)
      return;
    HapticFeedback.lightImpact();

    setState(() => _joinState = JoinState.joining);
    try {
      final joined = await _repository.joinProject(widget.projectId);
      if (!mounted) return;
      setState(
        () => _joinState = joined ? JoinState.joined : JoinState.notJoined,
      );
      if (joined) {
        _loadMembers();
        _refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).t('projects.joinedProject')),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _joinState = JoinState.notJoined);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).t('projects.unableJoin2')),
        ),
      );
    }
  }

  Future<void> _leaveProject() async {
    if (_joinState != JoinState.joined) return;
    HapticFeedback.lightImpact();

    setState(() => _joinState = JoinState.leaving);
    try {
      final left = await _repository.leaveProject(widget.projectId);
      if (!mounted) return;
      setState(
        () => _joinState = left ? JoinState.notJoined : JoinState.joined,
      );
      if (left) {
        _loadMembers();
        _refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).t('projects.leftProject')),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _joinState = JoinState.joined);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).t('projects.unableLeave')),
        ),
      );
    }
  }

  bool _isCurrentUserOwner(User? owner) {
    if (owner == null) return false;
    try {
      final userId = AppPreferences.instance.userId;
      return userId != null && userId == owner.id;
    } catch (_) {
      return false;
    }
  }

  Future<void> _editProject(Project project) async {
    if (_kScreenshotMode && kDebugMode) return;
    final titleCtrl = TextEditingController(text: project.title);
    final descriptionCtrl = TextEditingController(text: project.description);
    final techStackCtrl = TextEditingController(
      text: project.techStack.join(', '),
    );

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
                await _repository.updateProject(
                  projectId: project.id,
                  title: title,
                  description: description,
                  techStack: techStack,
                );
                if (mounted) {
                  sheetContext.pop();
                  _refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppStrings.of(context).t('projects.projectUpdated'),
                      ),
                    ),
                  );
                }
              } catch (e) {
                setSheetState(
                  () => error = AppStrings.current().t('projects.failedUpdate'),
                );
              } finally {
                setSheetState(() => saving = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Edit Project',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: techStackCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tech Stack (comma-separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: saving ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          saving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                'Save Changes',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    descriptionCtrl.dispose();
    techStackCtrl.dispose();
  }

  Future<void> _deleteProject(String projectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Delete Project'),
            content: const Text(
              'Are you sure you want to delete this project? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteProject(projectId);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).t('projects.projectDeleted')),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).t('projects.failedDelete')),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'LOOKING_FOR_MEMBERS':
        return AppColors.primary;
      case 'ACTIVE':
      case 'IN_PROGRESS':
        return AppColors.success;
      case 'COMPLETED':
        return AppColors.accent;
      case 'ON_HOLD':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'LOOKING_FOR_MEMBERS':
        return 'Looking for Members';
      case 'ACTIVE':
        return 'In Progress';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'ON_HOLD':
        return 'On Hold';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.06), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Project Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          FutureBuilder<Project?>(
            future: _detailLoader,
            builder: (context, snapshot) {
              final project = snapshot.data;
              final isOwner = _isCurrentUserOwner(project?.owner);
              if (!isOwner) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit project',
                    onPressed:
                        project != null ? () => _editProject(project) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Delete project',
                    onPressed: () => _deleteProject(widget.projectId),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Project?>(
        future: _detailLoader,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'Project not found',
                subtitle: 'This project may have been deleted.',
              ),
            );
          }

          final project = snapshot.data!;
          final isOwner = _isCurrentUserOwner(project.owner);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.getContentMaxWidth(context),
              ),
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
                  children: [
                    // Owner card
                    _OwnerCard(owner: project.owner, isOwner: isOwner),
                    const SizedBox(height: 10),

                    // Title and description
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE8EAF2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  project.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    project.status,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _getStatusLabel(project.status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _getStatusColor(project.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            project.description,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.55,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children:
                                project.techStack
                                    .map(
                                      (tech) => ColoredTagChip(
                                        label: tech,
                                        color: AppColors.getTagColor(tech),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Stats row
                    _ProjectStats(project: project),

                    const SizedBox(height: 10),

                    // Members section
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _membersLoader,
                      builder: (context, memberSnapshot) {
                        if (memberSnapshot.connectionState !=
                            ConnectionState.done) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        final members = memberSnapshot.data ?? const [];

                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE8EAF2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.group_outlined,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Team Members (${members.length})',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              if (members.isEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'No members yet. Be the first to join!',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 12),
                                ...members.map((m) => _MemberRow(member: m)),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomSheet:
          (_kScreenshotMode && kDebugMode)
              ? null
              : FutureBuilder<Project?>(
                future: _detailLoader,
                builder: (context, snapshot) {
                  final project = snapshot.data;
                  if (project == null) return const SizedBox.shrink();
                  final isOwner = _isCurrentUserOwner(project.owner);
                  if (isOwner) return const SizedBox.shrink();

                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              (_joinState == JoinState.joining ||
                                      _joinState == JoinState.leaving)
                                  ? null
                                  : _joinState == JoinState.joined
                                  ? _leaveProject
                                  : _joinProject,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor:
                                _joinState == JoinState.joined
                                    ? AppColors.error
                                    : AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child:
                              (_joinState == JoinState.joining ||
                                      _joinState == JoinState.leaving)
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    _joinState == JoinState.joined
                                        ? 'Leave Project'
                                        : 'Join Project',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

// ============================================================
// WIDGETS
// ============================================================

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.owner, required this.isOwner});

  final User owner;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              owner.displayName.isNotEmpty
                  ? owner.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5B53F6),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      owner.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (owner.isMentor) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE68A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Mentor',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      '${owner.reputation}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      owner.isOnline ? Icons.circle : Icons.circle_outlined,
                      size: 10,
                      color:
                          owner.isOnline
                              ? AppColors.success
                              : AppColors.disabled,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      owner.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectStats extends StatelessWidget {
  const _ProjectStats({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.calendar_today_outlined,
              value: _formatDate(project.createdAt),
              label: 'Created',
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.group_outlined,
              value: '${project.memberCount}/${project.maxMembers}',
              label: 'Members',
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.code_outlined,
              value: '${project.techStack.length}',
              label: 'Technologies',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    final displayName = member['displayName'] as String? ?? 'Unknown';
    final role = member['role'] as String? ?? 'Member';
    final status = member['status'] as String? ?? 'PENDING';

    Color statusColor;
    switch (status) {
      case 'ACCEPTED':
        statusColor = AppColors.success;
        break;
      case 'REJECTED':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFECEEFF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5B53F6),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status[0] + status.substring(1).toLowerCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

part of 'project_marketplace_screen.dart';

class _ShowcaseProjectMarketplaceScreen extends StatelessWidget {
  const _ShowcaseProjectMarketplaceScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: AppBottomNavBar(
        items: const [
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
            icon: Icons.work_outline,
            selectedIcon: Icons.work,
            label: 'Projects',
            route: AppRoutes.projects,
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            route: AppRoutes.profile,
          ),
        ],
        selectedIndex: 2,
        currentRoute: AppRoutes.projects,
        centerCreate: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          children: const [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Projects',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(Icons.search, size: 18),
                SizedBox(width: 12),
                Icon(Icons.tune, size: 18),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ShowcaseFilterChip(label: 'All'),
                _ShowcaseFilterChip(label: 'Looking for Devs', selected: true),
                _ShowcaseFilterChip(label: 'Open Source'),
              ],
            ),
            SizedBox(height: 14),
            _ShowcaseProjectCard(
              title: 'FlutterShop — E-commerce Mobile App',
              owner: 'Alex Kim',
              description:
                  'Building a cross-platform boutique shopping experience with real-time inventory and Stripe integration.',
              tags: ['Flutter', 'Dart', 'Firebase'],
              members: '3/5 members',
              label: 'Looking for Devs',
            ),
            _ShowcaseProjectCard(
              title: 'DevConnect API',
              owner: 'Sarah Chen',
              description:
                  'The core backend services powering the DevConnect mobile and web ecosystem.',
              tags: ['NestJS', 'PostgreSQL', 'GraphQL'],
              members: '2/4 members',
              label: 'Active',
            ),
            _ShowcaseProjectCard(
              title: 'RustOS — Lightweight Kernel',
              owner: 'Mike Ross',
              description:
                  'Educational operating system written in Rust focusing on safety and minimal footprint.',
              tags: ['Rust', 'Assembly'],
              members: '1/10 members',
              label: 'Open Source',
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowcaseProjectCard extends StatefulWidget {
  const _ShowcaseProjectCard({
    required this.title,
    required this.owner,
    required this.description,
    required this.tags,
    required this.members,
    required this.label,
  });

  final String title;
  final String owner;
  final String description;
  final List<String> tags;
  final String members;
  final String label;

  @override
  State<_ShowcaseProjectCard> createState() => _ShowcaseProjectCardState();
}

class _ShowcaseProjectCardState extends State<_ShowcaseProjectCard> {
  bool _joined = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _joined ? 'Joined' : widget.label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.description,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                widget.tags
                    .map(
                      (tag) => ColoredTagChip(
                        label: tag,
                        color: AppColors.getTagColor(tag),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 58,
                height: 24,
                child: Stack(
                  children: List.generate(3, (index) {
                    return Positioned(
                      left: index * 14,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4EEDF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Text(
                _joined ? _joinedMembersLabel(widget.members) : widget.members,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed:
                      _joined
                          ? null
                          : () {
                            HapticFeedback.lightImpact();
                            setState(() => _joined = true);
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: AppColors.primary,
                    disabledForegroundColor: AppColors.success,
                    side: const BorderSide(color: Color(0xFFD9D6FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _joined ? 'Joined' : 'Join',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _joinedMembersLabel(String label) {
    final parts = label.split(' ');
    final ratio = parts.isEmpty ? label : parts.first;
    final counts = ratio.split('/');
    if (counts.length != 2) return label;

    final current = int.tryParse(counts.first);
    final max = int.tryParse(counts.last);
    if (current == null || max == null) return label;

    final next = (current + 1).clamp(0, max);
    return '$next/$max members';
  }
}

class _ShowcaseFilterChip extends StatelessWidget {
  const _ShowcaseFilterChip({
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected ? AppColors.primary : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.joined,
    required this.onJoin,
  });

  final Project project;
  final bool joined;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final isOpen = project.status == 'LOOKING_FOR_MEMBERS';
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          AppRoutes.nameProjectDetail,
          pathParameters: {'id': project.id},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isOpen
                            ? const Color(0xFFF3F0FF)
                            : const Color(0xFFEFF7FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isOpen ? 'Open' : 'Active',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color:
                          isOpen
                              ? const Color(0xFF5B53F6)
                              : const Color(0xFF2279FF),
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
                  project.techStack
                      .take(4)
                      .map((tech) => TechChip(label: tech))
                      .toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _MiniMembers(project: project),
                const Spacer(),
                OutlinedButton(
                  onPressed: joined ? null : onJoin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        joined ? AppColors.success : const Color(0xFF5B53F6),
                    side: BorderSide(
                      color:
                          joined
                              ? const Color(0xFFB7E6CF)
                              : const Color(0xFFD9D6FF),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    joined ? 'Joined' : 'Join',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMembers extends StatelessWidget {
  const _MiniMembers({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      project.owner.displayName.split(' ').first.characters.first,
      ...project.techStack.take(2).map((tech) => tech.characters.first),
    ];

    return Row(
      children: [
        SizedBox(
          width: 78,
          height: 28,
          child: Stack(
            children: List.generate(labels.length, (index) {
              return Positioned(
                left: index * 18,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEEFF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[index],
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5B53F6),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Text(
          '${project.memberCount}/${project.maxMembers} members',
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

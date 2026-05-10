import 'package:flutter/material.dart';

import '../../../core/constants/routes.dart';
import '../../../core/models/models.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ai_sheets.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/user_repository.dart';

class MentorshipScreen extends StatefulWidget {
  const MentorshipScreen({super.key});

  @override
  State<MentorshipScreen> createState() => _MentorshipScreenState();
}

class _MentorshipScreenState extends State<MentorshipScreen> {
  final _repository = UserRepository();
  late Future<_MentorshipViewData> _loader;

  @override
  void initState() {
    super.initState();
    _loader = _load();
  }

  Future<_MentorshipViewData> _load() async {
    final currentUser = await _repository.getCurrentUser();
    final users = await _repository.getAllUsers();
    final mentors = users.where((user) => user.isMentor).toList();
    final activeUser =
        currentUser ??
        users.firstWhere(
          (user) => !user.isMentor,
          orElse: () => mentors.isNotEmpty ? mentors.first : users.first,
        );

    final matches = await AiService.instance.matchMentors(
      currentUser: activeUser,
      mentors: mentors,
      goals: const ['career growth', 'clean architecture', 'shipping projects'],
    );

    final matchesById = {for (final match in matches) match.mentorId: match};
    final rankedMentors = [...mentors]..sort(
      (a, b) => (matchesById[b.id]?.score ?? 0).compareTo(
        matchesById[a.id]?.score ?? 0,
      ),
    );

    return _MentorshipViewData(
      currentUser: activeUser,
      mentors: rankedMentors,
      matches: matches,
      matchesById: matchesById,
    );
  }

  Future<void> _showMatches(_MentorshipViewData data) {
    return showMentorMatchesSheet(
      context,
      matchesFuture: Future.value(data.matches),
      mentorNames: {
        for (final mentor in data.mentors) mentor.id: mentor.displayName,
      },
    );
  }

  Future<void> _sendRequest(User mentor) async {
    final noteCtrl = TextEditingController(
      text: 'I would like guidance on shipping stronger production code.',
    );
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Connect with ${mentor.displayName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Send a short mentorship request so the mentor knows what you need.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Share your goals...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Send request'),
            ),
          ],
        );
      },
    );

    if (sent != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request sent to ${mentor.displayName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            icon: Icons.school_outlined,
            selectedIcon: Icons.school,
            label: 'Mentorship',
            route: AppRoutes.mentorship,
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            route: AppRoutes.profile,
          ),
        ],
        selectedIndex: 2,
        currentRoute: AppRoutes.mentorship,
        centerCreate: true,
      ),
      appBar: AppBar(
        title: const Text(
          'Mentorship',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<_MentorshipViewData>(
        future: _loader,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: ErrorState(
                message: 'Unable to load mentorship suggestions right now.',
                onRetry: () => setState(() => _loader = _load()),
              ),
            );
          }

          final data = snapshot.data!;
          final mentors = data.mentors;
          final topMentors = mentors.take(4).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE8EAF2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F0FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF5B53F6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AI Mentor Match',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ranked using shared skills, experience signal, and mentoring profile fit for ${data.currentUser.displayName}.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () => _showMatches(data),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF5B53F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Find My Match',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Best matches for you',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ...mentors.map(
                (mentor) => _MentorCard(
                  mentor: mentor,
                  match: data.matchesById[mentor.id],
                  onConnect: () => _sendRequest(mentor),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Top rated mentors',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: topMentors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder:
                      (_, index) => _TopMentorCard(
                        mentor: topMentors[index],
                        match: data.matchesById[topMentors[index].id],
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MentorshipViewData {
  const _MentorshipViewData({
    required this.currentUser,
    required this.mentors,
    required this.matches,
    required this.matchesById,
  });

  final User currentUser;
  final List<User> mentors;
  final List<AiMentorMatch> matches;
  final Map<String, AiMentorMatch> matchesById;
}

class _TopMentorCard extends StatelessWidget {
  const _TopMentorCard({required this.mentor, this.match});

  final User mentor;
  final AiMentorMatch? match;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            name: mentor.displayName,
            size: 42,
            isOnline: mentor.isOnline,
          ),
          const SizedBox(height: 10),
          Text(
            mentor.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            '${match?.score ?? 80}% match',
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

class _MentorCard extends StatelessWidget {
  const _MentorCard({
    required this.mentor,
    required this.onConnect,
    this.match,
  });

  final User mentor;
  final AiMentorMatch? match;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final matchPct = match?.score ?? 78;
    final reasons =
        match?.reasons ??
        const ['Shared experience and strong profile signal.'];

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
              UserAvatar(
                name: mentor.displayName,
                size: 52,
                isOnline: mentor.isOnline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mentor.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF3D8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Mentor',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mentor.bio ?? 'Experienced builder and mentor.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${mentor.reputation} XP · ${mentor.followerCount} followers',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: matchPct / 100,
                      strokeWidth: 5,
                      backgroundColor: const Color(0xFFF1F3F8),
                      color:
                          matchPct >= 85
                              ? AppColors.success
                              : const Color(0xFF5B53F6),
                    ),
                    Text(
                      '$matchPct%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match?.label ?? 'Suggested fit',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reasons.first,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onConnect,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Connect'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                mentor.skills.map((skill) => TechChip(label: skill)).toList(),
          ),
        ],
      ),
    );
  }
}

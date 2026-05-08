import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/user_repository.dart';

class MentorshipScreen extends StatelessWidget {
  const MentorshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = UserRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Ghép cặp Mentor')),
      body: FutureBuilder<List<User>>(
        future: repository.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final mentors = (snapshot.data ?? const <User>[]).where((user) => user.isMentor).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FuturePhaseBanner(
                  title: 'Mentorship là tính năng giai đoạn sau',
                  description:
                      'Màn hình này đang dùng dữ liệu mentor từ local database để giữ flow trình diễn ổn định. Matching engine, lịch hẹn và đồng bộ backend sẽ được bổ sung ở phase tiếp theo.',
                  icon: Icons.school_outlined,
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.aiPurple, AppColors.primary]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'AI Matching',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hệ thống AI sẽ phân tích kỹ năng, kinh nghiệm và lịch trình để gợi ý mentor phù hợp nhất với bạn ở phase backend tiếp theo.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Luồng matching sẽ hoàn thiện sau khi nối backend'),
                              duration: Duration(seconds: 2),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.aiPurple,
                          ),
                          child: const Text('Tìm Mentor ngay'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Mentor gợi ý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...mentors.map((mentor) => _MentorCard(mentor: mentor)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MentorCard extends StatelessWidget {
  const _MentorCard({required this.mentor});

  final User mentor;

  @override
  Widget build(BuildContext context) {
    final matchPct = mentor.id.hashCode % 50 + 50;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(name: mentor.displayName, size: 52, isOnline: mentor.isOnline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(mentor.displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Mentor',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mentor.bio ?? '',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${mentor.reputation} XP · ${mentor.followerCount} followers',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: matchPct / 100,
                      strokeWidth: 4,
                      backgroundColor: AppColors.border,
                      color: matchPct >= 80 ? AppColors.success : AppColors.primary,
                    ),
                    Text('$matchPct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              SizedBox(
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Độ phù hợp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(
                      'Dựa trên kỹ năng, kinh nghiệm, lịch trình',
                      style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yêu cầu kết nối sẽ xử lý khi có backend'),
                    duration: Duration(seconds: 1),
                  ),
                ),
                child: const Text('Kết nối', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: mentor.skills.map((skill) => TechChip(label: skill)).toList(),
          ),
        ],
      ),
    );
  }
}

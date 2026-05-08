import 'package:flutter/material.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/repositories/user_repository.dart';

class LiveCodeScreen extends StatelessWidget {
  const LiveCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = UserRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Code Trực Tiếp')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo phòng code sẽ triển khai ở phase sau'),
            duration: Duration(seconds: 1),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tạo phòng'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<User>>(
        future: repository.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? const <User>[];
          final userById = {for (final user in users) user.id: user};

          final activeRooms = _buildRoomPreviews(users, false);
          final recentRooms = _buildRoomPreviews(users, true);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              const FuturePhaseBanner(
                title: 'Live collaboration sẽ hoàn thiện sau midterm',
                description:
                    'Danh sách phòng đang dùng dữ liệu người dùng từ local database để giữ cấu trúc màn hình ổn định. Realtime room, editor sync và backend orchestration sẽ được bổ sung ở giai đoạn sau.',
                icon: Icons.code_off_outlined,
              ),
              _RoomSection(title: 'Phòng đang hoạt động', rooms: activeRooms, users: userById),
              const SizedBox(height: 24),
              _RoomSection(title: 'Phòng gần đây', rooms: recentRooms, users: userById),
            ],
          );
        },
      ),
    );
  }

  static List<_RoomPreview> _buildRoomPreviews(List<User> users, bool recent) {
    final filtered = recent
        ? users.where((u) => u.id != 'u2' && u.id != 'u3' && u.id != 'u4').take(2).toList()
        : users.where((u) => u.id == 'u2' || u.id == 'u3' || u.id == 'u4').toList();
    if (filtered.isEmpty) return [];
    return filtered.asMap().entries.map((e) {
      final idx = e.key;
      return _RoomPreview(
        recent
            ? 'Phòng ${idx + 1}'
            : 'Live: ${filtered[idx].displayName}',
        filtered[idx].id,
        (idx + 1) * 3,
        !recent,
        idx.isEven ? 'Dart' : 'TypeScript',
      );
    }).toList();
  }
}

class _RoomSection extends StatelessWidget {
  const _RoomSection({
    required this.title,
    required this.rooms,
    required this.users,
  });

  final String title;
  final List<_RoomPreview> rooms;
  final Map<String, User> users;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...rooms.map((room) {
          final host = users[room.hostId];
          if (host == null) return const SizedBox.shrink();
          return _RoomCard(room: room, host: host);
        }),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.host});

  final _RoomPreview room;
  final User host;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: room.isLive ? AppColors.error.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (room.isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_manual_record, size: 8, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Text(
                  room.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              UserAvatar(name: host.displayName, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  host.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.people, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('${room.participants}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  room.language,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomPreview {
  const _RoomPreview(this.title, this.hostId, this.participants, this.isLive, this.language);

  final String title;
  final String hostId;
  final int participants;
  final bool isLive;
  final String language;
}

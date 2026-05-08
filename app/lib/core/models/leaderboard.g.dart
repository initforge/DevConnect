// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaderboardEntry _$LeaderboardEntryFromJson(Map<String, dynamic> json) =>
    LeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      points: (json['points'] as num).toInt(),
      rankChange: (json['rankChange'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$LeaderboardEntryToJson(LeaderboardEntry instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'user': instance.user,
      'points': instance.points,
      'rankChange': instance.rankChange,
    };

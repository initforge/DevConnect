import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'leaderboard.g.dart';

@JsonSerializable()
class LeaderboardEntry extends Equatable {
  final int rank;
  final User user;
  final int points;
  @JsonKey(name: 'rankChange')
  final int rankChange;

  const LeaderboardEntry({
    required this.rank,
    required this.user,
    required this.points,
    this.rankChange = 0,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => _$LeaderboardEntryFromJson(json);
  Map<String, dynamic> toJson() => _$LeaderboardEntryToJson(this);

  @override
  List<Object?> get props => [rank, user.id];
}

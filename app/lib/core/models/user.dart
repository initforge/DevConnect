import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String email;
  @JsonKey(name: 'avatarUrl')
  final String? avatarUrl;
  final String? bio;
  final List<String> skills;
  @JsonKey(name: 'followerCount')
  final int followerCount;
  @JsonKey(name: 'followingCount')
  final int followingCount;
  @JsonKey(name: 'postCount')
  final int postCount;
  final int reputation;
  @JsonKey(name: 'isOnline')
  final bool isOnline;
  @JsonKey(name: 'isMentor')
  final bool isMentor;
  @JsonKey(name: 'isFollowedByMe')
  final bool isFollowedByMe;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.skills = const [],
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.reputation = 0,
    this.isOnline = false,
    this.isMentor = false,
    this.isFollowedByMe = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  List<Object?> get props => [id];

  User copyWith({
    String? id,
    String? username,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? bio,
    List<String>? skills,
    int? followerCount,
    int? followingCount,
    int? postCount,
    int? reputation,
    bool? isOnline,
    bool? isMentor,
    bool? isFollowedByMe,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
      reputation: reputation ?? this.reputation,
      isOnline: isOnline ?? this.isOnline,
      isMentor: isMentor ?? this.isMentor,
      isFollowedByMe: isFollowedByMe ?? this.isFollowedByMe,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

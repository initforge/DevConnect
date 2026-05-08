// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String,
  email: json['email'] as String,
  avatarUrl: json['avatarUrl'] as String?,
  bio: json['bio'] as String?,
  skills:
      (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
  followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
  postCount: (json['postCount'] as num?)?.toInt() ?? 0,
  reputation: (json['reputation'] as num?)?.toInt() ?? 0,
  isOnline: json['isOnline'] as bool? ?? false,
  isMentor: json['isMentor'] as bool? ?? false,
  isFollowedByMe: json['isFollowedByMe'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'displayName': instance.displayName,
  'email': instance.email,
  'avatarUrl': instance.avatarUrl,
  'bio': instance.bio,
  'skills': instance.skills,
  'followerCount': instance.followerCount,
  'followingCount': instance.followingCount,
  'postCount': instance.postCount,
  'reputation': instance.reputation,
  'isOnline': instance.isOnline,
  'isMentor': instance.isMentor,
  'isFollowedByMe': instance.isFollowedByMe,
  'createdAt': instance.createdAt.toIso8601String(),
};

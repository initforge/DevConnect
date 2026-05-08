// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
  id: json['id'] as String,
  author: User.fromJson(json['author'] as Map<String, dynamic>),
  title: json['title'] as String,
  content: json['content'] as String,
  type:
      json['type'] == null ? PostType.article : _postTypeFromJson(json['type']),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  imageUrl: json['imageUrl'] as String?,
  viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
  likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
  commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
  bookmarkCount: (json['bookmarkCount'] as num?)?.toInt() ?? 0,
  isLikedByMe: json['isLikedByMe'] as bool? ?? false,
  isBookmarkedByMe: json['isBookmarkedByMe'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
  'id': instance.id,
  'author': instance.author,
  'title': instance.title,
  'content': instance.content,
  'type': _postTypeToJson(instance.type),
  'tags': instance.tags,
  'imageUrl': instance.imageUrl,
  'viewCount': instance.viewCount,
  'likeCount': instance.likeCount,
  'commentCount': instance.commentCount,
  'bookmarkCount': instance.bookmarkCount,
  'isLikedByMe': instance.isLikedByMe,
  'isBookmarkedByMe': instance.isBookmarkedByMe,
  'createdAt': instance.createdAt.toIso8601String(),
};

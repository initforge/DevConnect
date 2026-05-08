// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
  id: json['id'] as String,
  author: User.fromJson(json['author'] as Map<String, dynamic>),
  content: json['content'] as String,
  depth: (json['depth'] as num?)?.toInt() ?? 0,
  upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
  replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
  isBest: json['isBest'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
  'id': instance.id,
  'author': instance.author,
  'content': instance.content,
  'depth': instance.depth,
  'upvotes': instance.upvotes,
  'replyCount': instance.replyCount,
  'isBest': instance.isBest,
  'createdAt': instance.createdAt.toIso8601String(),
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project _$ProjectFromJson(Map<String, dynamic> json) => Project(
  id: json['id'] as String,
  owner: User.fromJson(json['owner'] as Map<String, dynamic>),
  title: json['title'] as String,
  description: json['description'] as String,
  techStack:
      (json['techStack'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  status: json['status'] as String? ?? 'LOOKING_FOR_MEMBERS',
  memberCount: (json['memberCount'] as num?)?.toInt() ?? 1,
  maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 5,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
  'id': instance.id,
  'owner': instance.owner,
  'title': instance.title,
  'description': instance.description,
  'techStack': instance.techStack,
  'status': instance.status,
  'memberCount': instance.memberCount,
  'maxMembers': instance.maxMembers,
  'createdAt': instance.createdAt.toIso8601String(),
};

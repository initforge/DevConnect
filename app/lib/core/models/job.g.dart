// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Job _$JobFromJson(Map<String, dynamic> json) => Job(
  id: json['id'] as String,
  company: json['company'] as String,
  title: json['title'] as String,
  location: json['location'] as String,
  remote: json['remote'] as bool? ?? false,
  salaryRange: json['salaryRange'] as String,
  techStack:
      (json['techStack'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  experience: json['experience'] as String,
  matchPercent: (json['matchPercent'] as num?)?.toInt() ?? 0,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$JobToJson(Job instance) => <String, dynamic>{
  'id': instance.id,
  'company': instance.company,
  'title': instance.title,
  'location': instance.location,
  'remote': instance.remote,
  'salaryRange': instance.salaryRange,
  'techStack': instance.techStack,
  'experience': instance.experience,
  'matchPercent': instance.matchPercent,
  'createdAt': instance.createdAt.toIso8601String(),
};

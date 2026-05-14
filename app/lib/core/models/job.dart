import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'job.g.dart';

@JsonSerializable()
class Job extends Equatable {
  final String id;
  final String company;
  final String title;
  final String location;
  final bool remote;
  @JsonKey(name: 'salaryRange')
  final String salaryRange;
  @JsonKey(name: 'techStack')
  final List<String> techStack;
  final String experience;
  @JsonKey(name: 'matchPercent')
  final int matchPercent;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  const Job({
    required this.id,
    required this.company,
    required this.title,
    required this.location,
    this.remote = false,
    required this.salaryRange,
    this.techStack = const [],
    required this.experience,
    this.matchPercent = 0,
    required this.createdAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
  Map<String, dynamic> toJson() => _$JobToJson(this);

  Job copyWith({
    String? id,
    String? company,
    String? title,
    String? location,
    bool? remote,
    String? salaryRange,
    List<String>? techStack,
    String? experience,
    int? matchPercent,
    DateTime? createdAt,
  }) {
    return Job(
      id: id ?? this.id,
      company: company ?? this.company,
      title: title ?? this.title,
      location: location ?? this.location,
      remote: remote ?? this.remote,
      salaryRange: salaryRange ?? this.salaryRange,
      techStack: techStack ?? this.techStack,
      experience: experience ?? this.experience,
      matchPercent: matchPercent ?? this.matchPercent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id];
}

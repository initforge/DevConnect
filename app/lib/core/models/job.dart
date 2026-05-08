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

  @override
  List<Object?> get props => [id];
}

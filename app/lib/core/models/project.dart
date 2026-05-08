import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'project.g.dart';

@JsonSerializable()
class Project extends Equatable {
  final String id;
  final User owner;
  final String title;
  final String description;
  @JsonKey(name: 'techStack')
  final List<String> techStack;
  final String status;
  @JsonKey(name: 'memberCount')
  final int memberCount;
  @JsonKey(name: 'maxMembers')
  final int maxMembers;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.owner,
    required this.title,
    required this.description,
    this.techStack = const [],
    this.status = 'LOOKING_FOR_MEMBERS',
    this.memberCount = 1,
    this.maxMembers = 5,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);

  @override
  List<Object?> get props => [id];
}

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'comment.g.dart';

@JsonSerializable()
class Comment extends Equatable {
  final String id;
  final User author;
  final String content;
  final int depth;
  final int upvotes;
  @JsonKey(name: 'replyCount')
  final int replyCount;
  @JsonKey(name: 'isBest')
  final bool isBest;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.author,
    required this.content,
    this.depth = 0,
    this.upvotes = 0,
    this.replyCount = 0,
    this.isBest = false,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);

  @override
  List<Object?> get props => [id];
}

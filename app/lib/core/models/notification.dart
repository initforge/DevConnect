import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'notification.g.dart';

@JsonSerializable()
class AppNotification extends Equatable {
  final String id;
  final String type;
  final String title;
  final String body;
  @JsonKey(name: 'fromUser')
  final User? fromUser;
  @JsonKey(name: 'isRead')
  final bool isRead;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;
  @JsonKey(name: 'mergedCount', defaultValue: 1)
  final int mergedCount;
  @JsonKey(name: 'targetPostId')
  final String? targetPostId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.fromUser,
    this.isRead = false,
    required this.createdAt,
    this.mergedCount = 1,
    this.targetPostId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);

  @override
  List<Object?> get props => [id];
}

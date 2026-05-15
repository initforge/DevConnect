import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'conversation.g.dart';

@JsonSerializable()
class Conversation extends Equatable {
  final String id;
  @JsonKey(name: 'otherUser')
  final User otherUser;
  @JsonKey(name: 'lastMessage')
  final String lastMessage;
  @JsonKey(name: 'unreadCount')
  final int unreadCount;
  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.otherUser,
    required this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  @override
  List<Object?> get props => [id];
}

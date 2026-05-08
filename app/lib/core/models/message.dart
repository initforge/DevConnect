import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

/// Types of messages supported.
enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('code')
  code,
}

@JsonSerializable()
class Message extends Equatable {
  final String id;
  @JsonKey(name: 'senderId')
  final String senderId;
  final String content;
  @JsonKey(fromJson: _messageTypeFromJson, toJson: _messageTypeToJson)
  final MessageType type;
  @JsonKey(name: 'codeLanguage')
  final String? codeLanguage;
  @JsonKey(name: 'codeSource')
  final String? codeSource;
  final List<String> reactions;
  @JsonKey(name: 'isRead')
  final bool isRead;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.codeLanguage,
    this.codeSource,
    this.reactions = const [],
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  @override
  List<Object?> get props => [id];
}

MessageType _messageTypeFromJson(dynamic value) {
  if (value is String) {
    return MessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageType.text,
    );
  }
  return MessageType.text;
}

String _messageTypeToJson(MessageType type) => type.name;

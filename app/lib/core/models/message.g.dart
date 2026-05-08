// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: json['id'] as String,
  senderId: json['senderId'] as String,
  content: json['content'] as String,
  type:
      json['type'] == null
          ? MessageType.text
          : _messageTypeFromJson(json['type']),
  codeLanguage: json['codeLanguage'] as String?,
  codeSource: json['codeSource'] as String?,
  reactions:
      (json['reactions'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isRead: json['isRead'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'senderId': instance.senderId,
  'content': instance.content,
  'type': _messageTypeToJson(instance.type),
  'codeLanguage': instance.codeLanguage,
  'codeSource': instance.codeSource,
  'reactions': instance.reactions,
  'isRead': instance.isRead,
  'createdAt': instance.createdAt.toIso8601String(),
};

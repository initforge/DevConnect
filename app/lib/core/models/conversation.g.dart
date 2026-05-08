// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
  id: json['id'] as String,
  otherUser: User.fromJson(json['otherUser'] as Map<String, dynamic>),
  lastMessage: json['lastMessage'] as String,
  unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'otherUser': instance.otherUser,
      'lastMessage': instance.lastMessage,
      'unreadCount': instance.unreadCount,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

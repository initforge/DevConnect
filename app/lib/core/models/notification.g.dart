// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      fromUser:
          json['fromUser'] == null
              ? null
              : User.fromJson(json['fromUser'] as Map<String, dynamic>),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      mergedCount: (json['mergedCount'] as num?)?.toInt() ?? 1,
      targetPostId: json['targetPostId'] as String?,
    );

Map<String, dynamic> _$AppNotificationToJson(AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'body': instance.body,
      'fromUser': instance.fromUser,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt.toIso8601String(),
      'mergedCount': instance.mergedCount,
      'targetPostId': instance.targetPostId,
    };

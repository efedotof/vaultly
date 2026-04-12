// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) =>
    _AuthResponse(
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      userId: json['userId'] as String,
      email: json['email'] as String?,
      username: json['username'] as String,
      storageUsed: (json['storageUsed'] as num).toInt(),
      storageLimit: (json['storageLimit'] as num).toInt(),
      roles: (json['roles'] as List<dynamic>).map((e) => e as String).toSet(),
    );

Map<String, dynamic> _$AuthResponseToJson(_AuthResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'userId': instance.userId,
      'email': instance.email,
      'username': instance.username,
      'storageUsed': instance.storageUsed,
      'storageLimit': instance.storageLimit,
      'roles': instance.roles.toList(),
    };

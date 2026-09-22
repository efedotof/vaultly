// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'totp_verify_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TotpVerifyResponse _$TotpVerifyResponseFromJson(Map<String, dynamic> json) =>
    _TotpVerifyResponse(
      success: json['success'] as bool,
      backupCodes: (json['backupCodes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TotpVerifyResponseToJson(_TotpVerifyResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'backupCodes': instance.backupCodes,
    };

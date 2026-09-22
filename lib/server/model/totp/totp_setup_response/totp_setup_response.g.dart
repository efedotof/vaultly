// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'totp_setup_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TotpSetupResponse _$TotpSetupResponseFromJson(Map<String, dynamic> json) =>
    _TotpSetupResponse(
      secret: json['secret'] as String,
      qrCodeUrl: json['qrCodeUrl'] as String,
    );

Map<String, dynamic> _$TotpSetupResponseToJson(_TotpSetupResponse instance) =>
    <String, dynamic>{
      'secret': instance.secret,
      'qrCodeUrl': instance.qrCodeUrl,
    };

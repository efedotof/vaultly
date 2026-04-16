import 'package:freezed_annotation/freezed_annotation.dart';

part 'recovery_data_response.freezed.dart';
part 'recovery_data_response.g.dart';

@freezed
abstract class RecoveryDataResponse with _$RecoveryDataResponse {
  const factory RecoveryDataResponse({
    required String recoveryEncryptedRsaKey,
    required String salt,
  }) = _RecoveryDataResponse;

  factory RecoveryDataResponse.fromJson(Map<String, dynamic> json) =>
      _$RecoveryDataResponseFromJson(json);
}

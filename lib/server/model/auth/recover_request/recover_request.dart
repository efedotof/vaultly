import 'package:freezed_annotation/freezed_annotation.dart';

part 'recover_request.freezed.dart';
part 'recover_request.g.dart';

@freezed
abstract class RecoverRequest with _$RecoverRequest {
  const factory RecoverRequest({required String publicKey}) = _RecoverRequest;

  factory RecoverRequest.fromJson(Map<String, dynamic> json) =>
      _$RecoverRequestFromJson(json);
}

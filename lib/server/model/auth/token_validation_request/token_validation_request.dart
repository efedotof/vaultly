import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_validation_request.freezed.dart';
part 'token_validation_request.g.dart';

@freezed
abstract class TokenValidationRequest with _$TokenValidationRequest {
  const factory TokenValidationRequest({required String token}) =
      _TokenValidationRequest;

  factory TokenValidationRequest.fromJson(Map<String, dynamic> json) =>
      _$TokenValidationRequestFromJson(json);
}

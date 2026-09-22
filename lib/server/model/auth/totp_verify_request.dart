class TotpVerifyRequest {
  final String code;

  TotpVerifyRequest({required this.code});

  factory TotpVerifyRequest.fromJson(Map<String, dynamic> json) {
    return TotpVerifyRequest(code: json['code'] as String);
  }

  Map<String, dynamic> toJson() => {'code': code};
}

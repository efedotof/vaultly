class TotpDisableRequest {
  final String code;

  TotpDisableRequest({required this.code});

  factory TotpDisableRequest.fromJson(Map<String, dynamic> json) {
    return TotpDisableRequest(code: json['code'] as String);
  }

  Map<String, dynamic> toJson() => {'code': code};
}

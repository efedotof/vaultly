class TotpVerifyResponse {
  final bool success;
  final List<String> backupCodes;

  TotpVerifyResponse({required this.success, required this.backupCodes});

  factory TotpVerifyResponse.fromJson(Map<String, dynamic> json) {
    return TotpVerifyResponse(
      success: json['success'] as bool,
      backupCodes: (json['backupCodes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'backupCodes': backupCodes,
  };
}

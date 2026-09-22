class TotpSetupResponse {
  final String qrCodeUrl;

  TotpSetupResponse({required this.qrCodeUrl});

  factory TotpSetupResponse.fromJson(Map<String, dynamic> json) {
    return TotpSetupResponse(qrCodeUrl: json['qrCodeUrl'] as String);
  }

  Map<String, dynamic> toJson() => {'qrCodeUrl': qrCodeUrl};
}

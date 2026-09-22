class LoginWithTotpRequest {
  final String preAuthToken;
  final String totpCode;

  LoginWithTotpRequest({required this.preAuthToken, required this.totpCode});

  factory LoginWithTotpRequest.fromJson(Map<String, dynamic> json) {
    return LoginWithTotpRequest(
      preAuthToken: json['preAuthToken'] as String,
      totpCode: json['totpCode'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'preAuthToken': preAuthToken,
    'totpCode': totpCode,
  };
}

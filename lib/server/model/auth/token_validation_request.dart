class TokenValidationRequest {
  final String? token;

  TokenValidationRequest({this.token});

  factory TokenValidationRequest.fromJson(Map<String, dynamic> json) {
    return TokenValidationRequest(token: json['token'] as String?);
  }

  Map<String, dynamic> toJson() => {if (token != null) 'token': token};
}

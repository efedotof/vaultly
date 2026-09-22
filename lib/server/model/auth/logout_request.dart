class LogoutRequest {
  final String? token;

  LogoutRequest({this.token});

  factory LogoutRequest.fromJson(Map<String, dynamic> json) {
    return LogoutRequest(token: json['token'] as String?);
  }

  Map<String, dynamic> toJson() => {if (token != null) 'token': token};
}

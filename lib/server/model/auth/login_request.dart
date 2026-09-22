class LoginRequest {
  final String username;
  final String password;
  final String? totpCode;

  LoginRequest({required this.username, required this.password, this.totpCode});

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      username: json['username'] as String,
      password: json['password'] as String,
      totpCode: json['totpCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    if (totpCode != null) 'totpCode': totpCode,
  };
}

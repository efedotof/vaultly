class AuthResponse {
  final String? accessToken;
  final String? userId;
  final String? email;
  final String? username;
  final int? storageUsed;
  final int? storageLimit;
  final Set<String>? roles;
  final bool? totpEnabled;

  AuthResponse({
    this.accessToken,
    this.userId,
    this.email,
    this.username,
    this.storageUsed,
    this.storageLimit,
    this.roles,
    this.totpEnabled,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String?,
      userId: json['userId'] as String?,
      email: json['email'] as String?,
      username: json['username'] as String?,
      storageUsed: json['storageUsed'] as int?,
      storageLimit: json['storageLimit'] as int?,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e as String).toSet(),
      totpEnabled: json['totpEnabled'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (accessToken != null) 'accessToken': accessToken,
    if (userId != null) 'userId': userId,
    if (email != null) 'email': email,
    if (username != null) 'username': username,
    if (storageUsed != null) 'storageUsed': storageUsed,
    if (storageLimit != null) 'storageLimit': storageLimit,
    if (roles != null) 'roles': roles!.toList(),
    if (totpEnabled != null) 'totpEnabled': totpEnabled,
  };
}

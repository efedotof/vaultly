class UserProfileDto {
  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final int storageUsed;
  final int storageLimit;
  final String publicKey;
  final bool totpEnabled;

  UserProfileDto({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.storageUsed,
    required this.storageLimit,
    required this.publicKey,
    required this.totpEnabled,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      storageUsed: json['storageUsed'] as int,
      storageLimit: json['storageLimit'] as int,
      publicKey: json['publicKey'] as String,
      totpEnabled: json['totpEnabled'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'firstName': firstName,
    'lastName': lastName,
    'avatarUrl': avatarUrl,
    'storageUsed': storageUsed,
    'storageLimit': storageLimit,
    'publicKey': publicKey,
    'totpEnabled': totpEnabled,
  };
}

class RegisterRequest {
  final String username;
  final String password;
  final String? firstName;
  final String? lastName;
  final String? publicKey;
  final String? privateKeyEncrypted;
  final String? salt;
  final String? email;

  RegisterRequest({
    required this.username,
    required this.password,
    this.firstName,
    this.lastName,
    this.publicKey,
    this.privateKeyEncrypted,
    this.salt,
    this.email,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      username: json['username'] as String,
      password: json['password'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      publicKey: json['publicKey'] as String?,
      privateKeyEncrypted: json['privateKeyEncrypted'] as String?,
      salt: json['salt'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    if (firstName != null) 'firstName': firstName,
    if (lastName != null) 'lastName': lastName,
    if (publicKey != null) 'publicKey': publicKey,
    if (privateKeyEncrypted != null) 'privateKeyEncrypted': privateKeyEncrypted,
    if (salt != null) 'salt': salt,
    if (email != null) 'email': email,
  };
}

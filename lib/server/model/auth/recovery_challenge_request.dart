class RecoveryChallengeRequest {
  final String publicKey;

  RecoveryChallengeRequest({required this.publicKey});

  factory RecoveryChallengeRequest.fromJson(Map<String, dynamic> json) {
    return RecoveryChallengeRequest(publicKey: json['publicKey'] as String);
  }

  Map<String, dynamic> toJson() => {'publicKey': publicKey};
}

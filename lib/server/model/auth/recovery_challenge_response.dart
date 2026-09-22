class RecoveryChallengeResponse {
  final String challenge;
  final int expiresInSeconds;

  RecoveryChallengeResponse({
    required this.challenge,
    required this.expiresInSeconds,
  });

  factory RecoveryChallengeResponse.fromJson(Map<String, dynamic> json) {
    return RecoveryChallengeResponse(
      challenge: json['challenge'] as String,
      expiresInSeconds: json['expiresInSeconds'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'challenge': challenge,
    'expiresInSeconds': expiresInSeconds,
  };
}

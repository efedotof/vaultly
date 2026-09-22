class RecoverRequest {
  final String publicKey;
  final String challenge;
  final String signature;

  RecoverRequest({
    required this.publicKey,
    required this.challenge,
    required this.signature,
  });

  factory RecoverRequest.fromJson(Map<String, dynamic> json) {
    return RecoverRequest(
      publicKey: json['publicKey'] as String,
      challenge: json['challenge'] as String,
      signature: json['signature'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'publicKey': publicKey,
    'challenge': challenge,
    'signature': signature,
  };
}

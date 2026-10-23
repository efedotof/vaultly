class PairInitRequest {
  final String initiatorPublicKey; // Base64(X25519 or P-256 pubkey)

  final String initiatorAlgorithm; // "X25519" | "P-256"

  PairInitRequest({
    required this.initiatorPublicKey,
    required this.initiatorAlgorithm,
  });

  factory PairInitRequest.fromJson(Map<String, dynamic> json) {
    return PairInitRequest(
      initiatorPublicKey: json['initiatorPublicKey'] as String,
      initiatorAlgorithm: json['initiatorAlgorithm'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "initiatorPublicKey": initiatorPublicKey,
      "initiatorAlgorithm": initiatorAlgorithm,
    };
  }
}

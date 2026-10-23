class PairInitResponse {
  final String pairingId;
  final DateTime expiresAt;

  PairInitResponse({required this.pairingId, required this.expiresAt});

  factory PairInitResponse.fromJson(Map<String, dynamic> json) {
    return PairInitResponse(
      pairingId: json['pairingId'] as String,
      expiresAt: json['expiresAt'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {"pairingId": pairingId, "expiresAt": expiresAt};
  }
}

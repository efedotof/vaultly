class CheckDuplicateRequest {
  final String? hash;
  final bool? isPublic;

  CheckDuplicateRequest({this.hash, this.isPublic});

  factory CheckDuplicateRequest.fromJson(Map<String, dynamic> json) {
    return CheckDuplicateRequest(
      hash: json['hash'] as String?,
      isPublic: json['isPublic'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (hash != null) 'hash': hash,
    if (isPublic != null) 'isPublic': isPublic,
  };
}

class LinkFileRequest {
  final String? fileContentId;
  final String? fileName;
  final String? folderId;
  final bool? isPublic;

  LinkFileRequest({
    this.fileContentId,
    this.fileName,
    this.folderId,
    this.isPublic,
  });

  factory LinkFileRequest.fromJson(Map<String, dynamic> json) {
    return LinkFileRequest(
      fileContentId: json['fileContentId'] as String?,
      fileName: json['fileName'] as String?,
      folderId: json['folderId'] as String?,
      isPublic: json['isPublic'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (fileContentId != null) 'fileContentId': fileContentId,
    if (fileName != null) 'fileName': fileName,
    if (folderId != null) 'folderId': folderId,
    if (isPublic != null) 'isPublic': isPublic,
  };
}

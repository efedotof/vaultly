class FolderMoveDto {
  final List<String>? fileIds;
  final String? targetFolderId;
  final String? sourceFolderId;
  final bool copy;

  FolderMoveDto({
    this.fileIds,
    this.targetFolderId,
    this.sourceFolderId,
    this.copy = false,
  });

  factory FolderMoveDto.fromJson(Map<String, dynamic> json) {
    return FolderMoveDto(
      fileIds: (json['fileIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      targetFolderId: json['targetFolderId'] as String?,
      sourceFolderId: json['sourceFolderId'] as String?,
      copy: json['copy'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    if (fileIds != null) 'fileIds': fileIds,
    if (targetFolderId != null) 'targetFolderId': targetFolderId,
    if (sourceFolderId != null) 'sourceFolderId': sourceFolderId,
    'copy': copy,
  };
}

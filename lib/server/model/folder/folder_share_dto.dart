class FolderShareDto {
  final String? folderId;
  final List<String> userIds;
  final bool canEdit;
  final bool canDelete;
  final bool canShare;
  final String? message;
  final DateTime? expiresAt;

  FolderShareDto({
    this.folderId,
    required this.userIds,
    this.canEdit = false,
    this.canDelete = false,
    this.canShare = false,
    this.message,
    this.expiresAt,
  });

  factory FolderShareDto.fromJson(Map<String, dynamic> json) {
    return FolderShareDto(
      folderId: json['folderId'] as String?,
      userIds: (json['userIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      canEdit: json['canEdit'] as bool? ?? false,
      canDelete: json['canDelete'] as bool? ?? false,
      canShare: json['canShare'] as bool? ?? false,
      message: json['message'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (folderId != null) 'folderId': folderId,
    'userIds': userIds,
    'canEdit': canEdit,
    'canDelete': canDelete,
    'canShare': canShare,
    if (message != null) 'message': message,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
  };
}

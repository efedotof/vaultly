class FileDto {
  final String? id;
  final String? name;
  final String? originalName;
  final int? size;
  final String? mimeType;
  final bool? isEncrypted;
  final bool? isPublic;
  final bool? isNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? folderId;
  final String? folderName;

  FileDto({
    this.id,
    this.name,
    this.originalName,
    this.size,
    this.mimeType,
    this.isEncrypted,
    this.isPublic,
    this.isNote,
    this.createdAt,
    this.updatedAt,
    this.folderId,
    this.folderName,
  });

  factory FileDto.fromJson(Map<String, dynamic> json) {
    return FileDto(
      id: json['id'] as String?,
      name: json['name'] as String?,
      originalName: json['originalName'] as String?,
      size: json['size'] as int?,
      mimeType: json['mimeType'] as String?,
      isEncrypted: json['isEncrypted'] as bool?,
      isPublic: json['isPublic'] as bool?,
      isNote: json['isNote'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      folderId: json['folderId'] as String?,
      folderName: json['folderName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (name != null) 'name': name,
    if (originalName != null) 'originalName': originalName,
    if (size != null) 'size': size,
    if (mimeType != null) 'mimeType': mimeType,
    if (isEncrypted != null) 'isEncrypted': isEncrypted,
    if (isPublic != null) 'isPublic': isPublic,
    if (isNote != null) 'isNote': isNote,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (folderId != null) 'folderId': folderId,
    if (folderName != null) 'folderName': folderName,
  };
}

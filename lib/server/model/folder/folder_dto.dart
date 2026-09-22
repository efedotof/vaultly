import 'package:vaulth_app/server/model/file/file_dto.dart';
import 'folder_type.dart';

class FolderDto {
  final String? id;
  final String? name;
  final String? path;
  final FolderType? type;
  final bool? isHidden;
  final bool? isLocked;
  final String? allowedUsers;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? parentFolderId;
  final String? parentFolderName;
  final List<FolderDto>? subfolders;
  final List<FileDto>? files;

  FolderDto({
    this.id,
    this.name,
    this.path,
    this.type,
    this.isHidden,
    this.isLocked,
    this.allowedUsers,
    this.createdAt,
    this.updatedAt,
    this.parentFolderId,
    this.parentFolderName,
    this.subfolders,
    this.files,
  });

  factory FolderDto.fromJson(Map<String, dynamic> json) {
    return FolderDto(
      id: json['id'] as String?,
      name: json['name'] as String?,
      path: json['path'] as String?,
      type: json['type'] != null
          ? FolderType.fromString(json['type'] as String)
          : null,
      isHidden: json['isHidden'] as bool?,
      isLocked: json['isLocked'] as bool?,
      allowedUsers: json['allowedUsers'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      parentFolderId: json['parentFolderId'] as String?,
      parentFolderName: json['parentFolderName'] as String?,
      subfolders: (json['subfolders'] as List<dynamic>?)
          ?.map((e) => FolderDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => FileDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (name != null) 'name': name,
    if (path != null) 'path': path,
    if (type != null) 'type': type!.toJson(),
    if (isHidden != null) 'isHidden': isHidden,
    if (isLocked != null) 'isLocked': isLocked,
    if (allowedUsers != null) 'allowedUsers': allowedUsers,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (parentFolderId != null) 'parentFolderId': parentFolderId,
    if (parentFolderName != null) 'parentFolderName': parentFolderName,
    if (subfolders != null)
      'subfolders': subfolders!.map((e) => e.toJson()).toList(),
    if (files != null) 'files': files!.map((e) => e.toJson()).toList(),
  };
}

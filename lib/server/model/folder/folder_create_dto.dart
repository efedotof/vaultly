class FolderCreateDto {
  final String name;
  final String? parentFolderId;
  final bool isHidden;
  final String? hiddenFolderKey;
  final String? password;
  final String? description;

  FolderCreateDto({
    required this.name,
    this.parentFolderId,
    this.isHidden = false,
    this.hiddenFolderKey,
    this.password,
    this.description,
  });

  factory FolderCreateDto.fromJson(Map<String, dynamic> json) {
    return FolderCreateDto(
      name: json['name'] as String,
      parentFolderId: json['parentFolderId'] as String?,
      isHidden: json['isHidden'] as bool? ?? false,
      hiddenFolderKey: json['hiddenFolderKey'] as String?,
      password: json['password'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (parentFolderId != null) 'parentFolderId': parentFolderId,
    'isHidden': isHidden,
    if (hiddenFolderKey != null) 'hiddenFolderKey': hiddenFolderKey,
    if (password != null) 'password': password,
    if (description != null) 'description': description,
  };
}

class FolderAccessDto {
  final String? folderId;
  final String? password;
  final String? hiddenFolderKey;

  FolderAccessDto({this.folderId, this.password, this.hiddenFolderKey});

  factory FolderAccessDto.fromJson(Map<String, dynamic> json) {
    return FolderAccessDto(
      folderId: json['folderId'] as String?,
      password: json['password'] as String?,
      hiddenFolderKey: json['hiddenFolderKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (folderId != null) 'folderId': folderId,
    if (password != null) 'password': password,
    if (hiddenFolderKey != null) 'hiddenFolderKey': hiddenFolderKey,
  };
}

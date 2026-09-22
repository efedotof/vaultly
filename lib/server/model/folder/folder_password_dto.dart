class FolderPasswordDto {
  final String? password;

  FolderPasswordDto({this.password});

  factory FolderPasswordDto.fromJson(Map<String, dynamic> json) {
    return FolderPasswordDto(password: json['password'] as String?);
  }

  Map<String, dynamic> toJson() => {if (password != null) 'password': password};
}

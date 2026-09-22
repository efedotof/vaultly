class FolderUpdateDto {
  final String name;
  final String? description;

  FolderUpdateDto({required this.name, this.description});

  factory FolderUpdateDto.fromJson(Map<String, dynamic> json) {
    return FolderUpdateDto(
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
  };
}

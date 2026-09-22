class FileAccessRequest {
  final bool? isPublic;

  FileAccessRequest({this.isPublic});

  factory FileAccessRequest.fromJson(Map<String, dynamic> json) {
    return FileAccessRequest(isPublic: json['isPublic'] as bool?);
  }

  Map<String, dynamic> toJson() => {if (isPublic != null) 'isPublic': isPublic};
}

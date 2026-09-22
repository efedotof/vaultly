class AddFileToFolderRequest {
  final String? fileId;

  AddFileToFolderRequest({this.fileId});

  factory AddFileToFolderRequest.fromJson(Map<String, dynamic> json) {
    return AddFileToFolderRequest(fileId: json['fileId'] as String?);
  }

  Map<String, dynamic> toJson() => {if (fileId != null) 'fileId': fileId};
}

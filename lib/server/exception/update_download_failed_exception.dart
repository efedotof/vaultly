class UpdateDownloadFailedException implements Exception {
  final String message;

  UpdateDownloadFailedException([String? message])
    : message = message ?? "Ошибка скачивания обновления";
}

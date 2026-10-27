class UpdateCheckFailedException implements Exception {
  final String message;

  UpdateCheckFailedException([String? message])
    : message = message ?? "Ошибка проверки обновления";
}

class NoUpdateRequiredException implements Exception {
  final String message;

  NoUpdateRequiredException([String? message])
    : message = message ?? "Обновление не требуется";
}

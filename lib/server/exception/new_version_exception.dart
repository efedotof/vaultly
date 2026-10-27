class NewVersionException implements Exception {
  final String message;

  NewVersionException([String? message])
    : message = message ?? "Доступна новая версия";
}

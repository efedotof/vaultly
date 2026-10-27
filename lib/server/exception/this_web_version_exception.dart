class ThisWebVersionException implements Exception {
  final String message;

  ThisWebVersionException([String? message])
    : message = message ?? "Вы на вебверсии";
}

class UsernameAlreadyExistsException implements Exception {
  final String message;
  UsernameAlreadyExistsException(this.message);
}

import 'package:get/get.dart';

class AuthErrorException implements Exception {
  final String message;

  AuthErrorException([String? message])
      : message = message ?? 'authorization_error'.tr;

  @override
  String toString() => message;
}
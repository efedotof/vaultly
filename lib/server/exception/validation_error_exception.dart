import 'package:get/get.dart';

class ValidationErrorException implements Exception {
  final String message;

  ValidationErrorException([String? message])
      : message = message ?? 'validation_error'.tr;

  String exceptionInfo() => message;

  @override
  String toString() => message;
}
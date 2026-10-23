import 'package:get/get.dart';

class UnknownErrorException implements Exception {
  final String message;

  UnknownErrorException([String? message])
      : message = message ?? 'unknown_error'.tr;

  String exceptionInfo() => message;

  @override
  String toString() => message;
}
import 'package:get/get.dart';

class RateLimitException implements Exception {
  final String message;

  RateLimitException([String? message])
      : message = message ?? 'try_again_later'.tr;

  String exceptionInfo() => message;

  @override
  String toString() => message;
}
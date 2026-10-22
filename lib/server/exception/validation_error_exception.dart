import 'package:get/get.dart';

class ValidationErrorException implements Exception{
  final String? message;

  ValidationErrorException(this.message);
  
  @override 
  String exceptionInfo() => "validation_error".tr;
}
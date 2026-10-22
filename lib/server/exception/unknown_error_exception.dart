import 'package:get/get.dart';

class UnknownErrorException implements Exception{
  @override 
  String exceptionInfo() => "unknown_error".tr;
}
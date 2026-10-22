import 'package:get/get.dart';

class AuthErrorException implements Exception{
  @override 
  String exceptionInfo() => "authorization_error".tr;
}
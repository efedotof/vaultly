import 'package:get/get.dart';

class RateLimitException implements Exception{
  @override 
  String exceptionInfo() => "try_again_later".tr;
}
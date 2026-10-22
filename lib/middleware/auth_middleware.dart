import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class AuthMiddleware extends GetMiddleware {
  
  @override
  RouteSettings? redirect(String? route) {
    bool isAuth = true;
   
    if(isAuth && route =="/"){
      return const RouteSettings(name:'/main_home');
    } 

    if (!isAuth && route == "/main_home") {
      return const RouteSettings(name: '/');
    }

    return null;
  }
}

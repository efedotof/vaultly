import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PasswordWidget extends StatelessWidget {
  const PasswordWidget({super.key, required this.action});
  final VoidCallback action;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Center(child: Text("Введите пароль")),

        Container(
          padding: EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Color(0xFF525252),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: "пароль",
            ),
          ),
        ),

        OutlinedButton(onPressed: action, child: Text("continue".tr)),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: "Забыли пароль?",
            style: TextStyle(color: Colors.white54),
            children: [
              TextSpan(
                text: " Восстановите по seed-фразе ",
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),

        RichText(
          textAlign: TextAlign.center,

          text: TextSpan(
            text: "Используя приложение вы соглашаетесь с",
            style: TextStyle(color: Colors.white54, fontSize: 10),
            children: [
              TextSpan(
                text: " Политикой конфиденциальности ",
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
              TextSpan(
                text: "и",
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
              TextSpan(
                text: " Пользовательским соглашением",
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

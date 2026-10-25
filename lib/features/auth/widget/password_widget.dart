import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../global_widget/custom_text_field/custom_text_field.dart';

class PasswordWidget extends StatelessWidget {
  const PasswordWidget({
    super.key,
    required this.onSubmit,
    required this.passwordController,
  });
  final ValueChanged<String> onSubmit;

  final TextEditingController passwordController;

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
          child: CustomTextField(
            controller: passwordController,
            onSubmitted: onSubmit,
            isPassword: true,
            hintText: "password".tr,
            textInputAction: TextInputAction.done,
            autofocus: true,
          ),
        ),

        OutlinedButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            onSubmit(passwordController.text);
          },
          child: Text("continue".tr),
        ),

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

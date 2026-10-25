import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/auth/controller/auth_controller.dart';
import 'package:vaulth_app/features/auth/widget/custom_text_field.dart';

class LoginWidget extends StatelessWidget {
  const LoginWidget({
    super.key,
    required this.action,
    required this.usernameController,
  });
  final VoidCallback action;

  final TextEditingController usernameController;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Center(child: Text("welcome".tr)),

        Container(
          padding: EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Color(0xFF525252),
            borderRadius: BorderRadius.circular(10),
          ),

          child: CustomTextField(
            editingAction: () => {
              Get.find<AuthController>().username.value =
                  usernameController.text,
            },
            controller: usernameController,
            isPassword: false,
            hintText: "username".tr,
          ),
        ),

        OutlinedButton(onPressed: action, child: Text("continue".tr)),

        Container(
          width: double.infinity,
          padding: EdgeInsets.all(6),

          decoration: BoxDecoration(
            color: Color(0xFF525252),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              CircleAvatar(),
              const SizedBox(width: 12),
              Text("Войти с QNDid"),
            ],
          ),
        ),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: "Используя приложение вы соглашаетесь с",
            children: [
              TextSpan(text: " Политикой конфиденциальности "),
              TextSpan(text: "и"),
              TextSpan(text: " Пользовательским соглашением"),
            ],
          ),
        ),
      ],
    );
  }
}

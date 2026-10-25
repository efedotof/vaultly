import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/global_widget/custom_text_field/custom_text_field.dart';

class LoginWidget extends StatelessWidget {
  const LoginWidget({
    super.key,
    required this.onSubmit,
    required this.usernameController,
  });
  final ValueChanged<String> onSubmit;

  final TextEditingController usernameController;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Center(child: Text("welcome".tr)),

        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF525252),
            borderRadius: BorderRadius.circular(10),
          ),
          child: CustomTextField(
            controller: usernameController,
            onSubmitted: onSubmit,
            hintText: "username".tr,
            textInputAction: TextInputAction.next,
            autofocus: true,
            keyboardType: TextInputType.text,
          ),
        ),

        OutlinedButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            onSubmit(usernameController.text);
          },
          child: Text("continue".tr),
        ),

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

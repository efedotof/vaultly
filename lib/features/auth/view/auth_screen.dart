import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/auth/controller/auth_controller.dart';

//единый экран авторизации
class AuthScreen extends StatelessWidget {
  @Preview(name: 'Auth Screen Preview')
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(color: Colors.white),
            margin: const EdgeInsets.all(10.0),
            child: Obx(() {
              switch (controller.state.value) {
                case AuthStates.login:
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Добро пожаловать!"),

                      TextField(
                        onChanged: (value) {
                          controller.username.value = value;
                        },
                      ),

                      const SizedBox(height: 20),

                      OutlinedButton(
                        onPressed: () {},
                        child: Text("Продолжить"),
                      ),

                      const SizedBox(height: 20),

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

                      const SizedBox(height: 30),
                    ],
                  );

                case AuthStates.password:
                  return Column(
                    children: [
                      Text(
                        "Введите пароль\n или восстановите через TOTP",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );

                default:
                  return Container();
              }
            }),
          ),
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.12,
            decoration: BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
            ),
            margin: const EdgeInsets.only(left: 10.0, right: 10, top: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownMenu(
                  initialSelection: ['Один', 'Два', 'Три', 'Четыре'].first,
                  onSelected: (String? value) {
                    // Действие при выборе
                  },
                  dropdownMenuEntries: ['Один', 'Два', 'Три', 'Четыре']
                      .map<DropdownMenuEntry<String>>((String value) {
                        return DropdownMenuEntry<String>(
                          value: value,
                          label: value,
                        );
                      })
                      .toList(),
                ),

                IconButton(onPressed: () {}, icon: Icon(Icons.dark_mode)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

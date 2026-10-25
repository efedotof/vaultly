import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/features/auth/controller/auth_controller.dart';
import 'package:vaulth_app/features/auth/widget/widget.dart';
import 'package:vaulth_app/features/global_widget/connection_checher/view/connection_checker.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController baseUrl = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    baseUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF1d3687),
          ),

          Positioned(
            right: 10,
            top: MediaQuery.of(context).size.height * 0.1,
            child: GestureDetector(
              onTap: () => showConfigSheet(),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(11)),
                  color: Color(0xFF43416d),
                ),
                padding: const EdgeInsets.all(10),
                child: Obx(
                  () => Text("Сервер: ${Get.find<Config>().connectStatus}"),
                ),
              ),
            ),
          ),

          Positioned(
            left: 10,
            top: MediaQuery.of(context).size.height * 0.1,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(11)),
                color: Color(0xFF43416d),
              ),
              padding: const EdgeInsets.all(10),
              child: const Text("Язык: русский"),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
                color: Color(0xFF43416d),
              ),
              padding: const EdgeInsets.all(10),
              child: Obx(() {
                switch (controller.state.value) {
                  case AuthStates.login:
                    return LoginWidget(
                      usernameController: usernameController,
                      onSubmit: (text) {
                        controller.username.value = text;
                        controller.goToNext();
                      },
                    );

                  case AuthStates.password:
                    return PasswordWidget(
                      passwordController: passwordController,
                      onSubmit: (text) {
                        controller.password.value = text;
                        controller.login();
                      },
                    );

                  case AuthStates.loading:
                    return const LoadingWidget();
                }
              }),
            ),
          ),

          const ConnectionChecker(),
        ],
      ),
    );
  }
}

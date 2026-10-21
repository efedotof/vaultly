import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/auth/controller/auth_controller.dart';
import 'package:vaulth_app/features/auth/widget/widget.dart';

//единый экран авторизации
class AuthScreen extends StatelessWidget {
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
            color: Color(0xFF1d3687),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,

            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
                color: Color(0xFF43416d),
              ),
              padding: EdgeInsets.all(10),
              child: Obx(() {
                switch (controller.state.value) {
                  case AuthStates.login:
                    return LoginWidget(
                      action: () {
                        controller.goToPassword();
                      },
                    );

                  case AuthStates.password:
                    return PasswordWidget(
                      action: () {
                        controller.login();
                      },
                    );

                  case AuthStates.loading:
                    return LoadingWidget();
                }
              }),
            ),
          ),
        ],
      ),
    );
  }
}

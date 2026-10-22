import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/profile/controller/profile_controller.dart';
import 'package:vaulth_app/features/profile/widget/widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    return Scaffold(
      body: Obx(() {
        switch (profileController.state.value) {
          case ProfileStates.createProfile:
            return CreateProfileWidget(
              onPressed: () {
                
              },
            );
          case ProfileStates.myProfile:
            return MyProfileWidget(onPressed: () {
              Get.toNamed("/main_home");
            });
          case ProfileStates.otherProfile:
            return OtherProfileWidget();
          case ProfileStates.updateProfile:
            return UpdateProfileWidget();
        }
      }),
    );
  }
}

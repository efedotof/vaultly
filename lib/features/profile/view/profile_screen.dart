import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/profile/controller/profile_controller.dart';
import 'package:vaulth_app/features/profile/widget/widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileController>();
    return Scaffold(
      body: Obx(() {
        switch (c.state.value) {
          case ProfileStates.loading:
            return const Center(child: CircularProgressIndicator());

          case ProfileStates.createProfile:
            return CreateProfileWidget(
              onSave:
                  ({
                    required firstName,
                    required lastName,
                    required email,
                    required totpEnabled,
                  }) {
                    c.createProfile(
                      firstName: firstName,
                      lastName: lastName,
                      email: email,
                      totpEnabled: totpEnabled,
                    );
                  },
            );

          case ProfileStates.myProfile:
            return MyProfileWidget(onPressed: () => Get.toNamed('/main_home'));

          case ProfileStates.otherProfile:
            return OtherProfileWidget();

          case ProfileStates.updateProfile:
            return UpdateProfileWidget();
        }
      }),
    );
  }
}

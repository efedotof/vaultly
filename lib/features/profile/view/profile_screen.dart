import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/global_widget/app_status_overlay/view/app_status_overlay.dart';
import 'package:vaulth_app/features/profile/controller/profile_controller.dart';
import 'package:vaulth_app/features/profile/widget/widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileController>();
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Obx(() {
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
                  return MyProfileWidget(
                    onPressed: () =>
                        c.state.value = ProfileStates.updateProfile,
                  );

                case ProfileStates.otherProfile:
                  return OtherProfileWidget();

                case ProfileStates.updateProfile:
                  return UpdateProfileWidget(
                    onSave:
                        ({
                          required firstName,
                          required lastName,
                          required username,
                        }) {
                          c.updateProfile(
                            firstName: firstName,
                            lastName: lastName,
                            usernameInput: username,
                          );
                        },
                    onCancel: () => c.state.value = ProfileStates.myProfile,
                  );
              }
            }),
          ),

            const AppStatusOverlay(),
        ],
      ),
    );
  }
}

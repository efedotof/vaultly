import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/global_widget/app_status_overlay/view/app_status_overlay.dart';
import 'package:vaulth_app/features/profile/controller/profile_controller.dart';

class MyProfileWidget extends StatelessWidget {
  const MyProfileWidget({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF43416d),
        actions: [
          TextButton(onPressed: onPressed, child: const Text('Update')),
        ],
      ),
      backgroundColor: const Color(0xFF1d3687),
      body: Obx(() {
        final avatarUrl = c.avatarUrl;
        return Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.15,
                      width: double.infinity,
                      color: const Color(0xFF43416d),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: CircleAvatar(
                                maxRadius: 35,
                                minRadius: 16,
                                child: ClipOval(
                                  child: avatarUrl.isNotEmpty
                                      ? Image.network(
                                          avatarUrl,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.person),
                                        )
                                      : const Icon(Icons.person),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(c.fullname),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.15,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          color: const Color(0xFF43416d),
                        ),
                        padding: const EdgeInsets.all(11),
                        child: Column(
                          children: [
                            Text(
                              c.username.isEmpty
                                  ? 'Нет авторизации'
                                  : c.username,
                            ),
                            Text(c.email.isEmpty ? 'Нет почты' : c.email),
                            Text('${c.storageUsed}/${c.storageLimit}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
              const AppStatusOverlay(),
          ],
        );
      }),
    );
  }
}

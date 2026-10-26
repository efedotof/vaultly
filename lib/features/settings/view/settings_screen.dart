import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/profile/controller/profile_controller.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text(
          'Ключи останутся на устройстве. При повторном входе '
          'они будут использованы снова.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await Get.find<AuthLocalStorage>().clearAuthData();
    Get.offAllNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileController>();

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => Get.toNamed('/profile/my_profile'),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Obx(() {
                    final avatarUrl = profile.avatarUrl;
                    final name = profile.fullname;
                    final username = profile.username;

                    return Row(
                      children: [
                        CircleAvatar(
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isEmpty ? 'Профиль' : name,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                username.isEmpty ? 'premium' : '@$username',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey,
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: const [
                    ListTile(title: Text('Безопасность')),
                    ListTile(title: Text('Безопасность')),
                    ListTile(title: Text('Безопасность')),
                    ListTile(title: Text('Безопасность')),
                    ListTile(title: Text('Безопасность')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _logout, child: const Text('Выйти')),
              const SizedBox(height: 8),
              const Text('v1.0.13'),
            ],
          ),
        ),
      ),
    );
  }
}

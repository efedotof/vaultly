import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/profile/controller/profile_controller.dart';
import 'package:vaulth_app/features/settings/controller/settings_controller.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double b = bytes.toDouble();
    while (b >= 1024 && i < suffixes.length - 1) {
      b /= 1024;
      i++;
    }
    return '${b.toStringAsFixed(1)} ${suffixes[i]}';
  }

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

    final settingsController = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : Get.put(SettingsController());

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
                                    errorBuilder: (_, _, _) =>
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
                child: const Column(
                  children: [
                    ListTile(title: Text('Безопасность')),
                    ListTile(title: Text('Безопасность')),
                    ListTile(title: Text('Безопасность')),
                    ListTile(title: Text('Безопасность')),
                    ListTile(title: Text('Безопасность')),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey,
                ),
                padding: const EdgeInsets.all(10),
                child: Obx(() {
                  final state = settingsController.state.value;
                  final appVersion = settingsController.appVersion.value;

                  Widget actionWidget;
                  String subtitle = appVersion.isEmpty
                      ? 'Версия неизвестна'
                      : 'v$appVersion';

                  switch (state) {
                    case SettingsState.idle:
                      actionWidget = const Icon(Icons.refresh);
                      break;
                    case SettingsState.checking:
                      actionWidget = const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                      subtitle = 'Проверка обновлений...';
                      break;
                    case SettingsState.updateAvailable:
                      actionWidget = TextButton(
                        onPressed: settingsController.startUpdate,
                        child: const Text(
                          'Скачать',
                          style: TextStyle(color: Colors.blue),
                        ),
                      );
                      subtitle = 'Доступна новая версия';
                      break;
                    case SettingsState.downloadingUpdate:
                      final done = settingsController.downloadedBytes.value;
                      final total = settingsController.totalBytes.value;
                      final pct =
                          (settingsController.downloadProgress.value * 100)
                              .toStringAsFixed(0);

                      subtitle = total > 0
                          ? 'Скачано: $pct% (${_formatBytes(done)} / ${_formatBytes(total)})'
                          : 'Скачивание... (${_formatBytes(done)})';

                      actionWidget = SizedBox(
                        width: 60,
                        child: LinearProgressIndicator(
                          value: total > 0
                              ? settingsController.downloadProgress.value
                              : null,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      );
                      break;
                    case SettingsState.noUpdate:
                      actionWidget = const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      );
                      subtitle = 'Установлена последняя версия';
                      break;
                    case SettingsState.failedUpdate:
                      actionWidget = const Icon(Icons.error, color: Colors.red);
                      subtitle = 'Ошибка проверки (нажмите чтобы повторить)';
                      break;
                    case SettingsState.webVersion:
                      actionWidget = const Icon(
                        Icons.language,
                        color: Colors.grey,
                      );
                      subtitle = 'Веб-версия';
                      break;
                  }

                  final canRetry =
                      state == SettingsState.idle ||
                      state == SettingsState.noUpdate ||
                      state == SettingsState.failedUpdate;

                  return ListTile(
                    leading: const Icon(Icons.system_update),
                    title: const Text('Обновление приложения'),
                    subtitle: Text(subtitle),
                    trailing: actionWidget,
                    onTap: canRetry ? settingsController.checkUpgrade : null,
                  );
                }),
              ),
              const SizedBox(height: 16),

              OutlinedButton(onPressed: _logout, child: const Text('Выйти')),
              const SizedBox(height: 8),

              Obx(() {
                final ver = settingsController.appVersion.value;
                return Text(ver.isEmpty ? 'v...' : 'v$ver');
              }),
            ],
          ),
        ),
      ),
    );
  }
}

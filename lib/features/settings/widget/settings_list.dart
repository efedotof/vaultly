import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/settings/cubit/settings_cubit.dart';
import 'package:vaulth_app/route/app_router.dart';
import 'package:vaulth_app/server/model/user/user_profile_dto/user_profile_dto.dart';

import 'confirm_dialog.dart';
import 'info_row.dart';

class SettingsList extends StatelessWidget {
  final UserProfileDto profile;
  final int? cacheSizeBytes;

  const SettingsList({super.key, required this.profile, this.cacheSizeBytes});

  String _formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double value = bytes.toDouble();
    while (value >= 1024 && i < suffixes.length - 1) {
      value /= 1024;
      i++;
    }
    return '${value.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<bool?> _logout(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Выход',
        content: 'Вы уверены, что хотите выйти?',
        confirmText: 'Выйти',
        isDestructive: true,
        confirmButton: () {
          context.read<SettingsCubit>().logout();
          context.pop();
        },
      ),
    );
  }

  Future<bool?> _confirmClearCache(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Очистить кэш',
        content: 'Все локально сохранённые файлы будут удалены. Продолжить?',
        confirmText: 'Очистить',
        confirmColor: Colors.orange,
        confirmButton: () {
          context.read<SettingsCubit>().clearCache();
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storageUsage =
        (profile.storageUsed != null && profile.storageLimit != null)
        ? profile.storageUsed! / profile.storageLimit!
        : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.1,
      ),
      child: ListView(
        padding: const EdgeInsets.only(
          top: kToolbarHeight + 24,
          left: 20,
          right: 20,
          bottom: 20,
        ),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Профиль',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InfoRow(label: 'Имя', value: profile.firstName),
                  InfoRow(label: 'Фамилия', value: profile.lastName),
                  InfoRow(label: 'Имя пользователя', value: profile.username),
                  InfoRow(label: 'Email', value: profile.email),
                  if (profile.storageLimit != null &&
                      profile.storageUsed != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Хранилище',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${(storageUsage * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: storageUsage > 0.9
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: storageUsage.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          storageUsage > 0.9
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatBytes(profile.storageUsed!),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _formatBytes(profile.storageLimit!),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.devices),
                  title: const Text('Устройства'),
                  subtitle: const Text(
                    'Управление зарегистрированными устройствами',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushRoute(const DeviceRoute()),
                ),
                const Divider(height: 0, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.vpn_key),
                  title: const Text('Ключи'),
                  subtitle: const Text('Управление ключами шифрования'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushRoute(const KeysManagerRoute()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Кэш файлов',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Занято:',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        cacheSizeBytes != null
                            ? _formatBytes(cacheSizeBytes!)
                            : 'вычисляется...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => _confirmClearCache(context),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.orange,
                    ),
                    label: const Text('Очистить кэш'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Выйти из аккаунта'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

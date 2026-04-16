import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/settings/cubit/settings_cubit.dart';

class UpdateSection extends StatelessWidget {
  const UpdateSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (previous, current) {
        return current.maybeWhen(
          loaded: (_, _, _, isChecking, isAvailable, isDownloading, _) => true,
          orElse: () => false,
        );
      },
      builder: (context, state) {
        return state.maybeWhen(
          loaded:
              (
                profile,
                devices,
                cacheSize,
                isChecking,
                isAvailable,
                isDownloading,
                updateInfo,
              ) {
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.system_update,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Обновление приложения',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (isChecking) ...[
                          const Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Проверка обновлений...'),
                            ],
                          ),
                        ] else if (isDownloading) ...[
                          const Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Загрузка обновления...'),
                            ],
                          ),
                        ] else if (isAvailable && updateInfo != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.new_releases,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Доступна версия ${updateInfo.version}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: isDownloading
                                ? null
                                : () async {
                                    final shouldInstall = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text(
                                          'Установить обновление?',
                                        ),
                                        content: const Text(
                                          'Приложение будет перезапущено после установки.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Отмена'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Установить'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (shouldInstall == true &&
                                        context.mounted) {
                                      context
                                          .read<SettingsCubit>()
                                          .downloadAndInstallUpdate();
                                    }
                                  },
                            icon: const Icon(Icons.download),
                            label: const Text('Установить обновление'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'У вас последняя версия',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: isChecking
                                ? null
                                : () => context
                                      .read<SettingsCubit>()
                                      .checkUpdateAvailability(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Проверить обновления'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                        if (isChecking || isDownloading) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Проверить обновления'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }
}

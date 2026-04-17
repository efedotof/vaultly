import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/auth/widget/totp_code_dialog.dart';
import 'package:vaulth_app/features/document_viewer/widget/code_view.dart';
import 'package:vaulth_app/features/settings/cubit/settings_cubit.dart';
import 'package:vaulth_app/route/app_router.dart';
import 'package:vaulth_app/server/model/user/user_profile_dto/user_profile_dto.dart';
import 'package:vaulth_app/theme/theme_app/theme_cubit.dart';
import 'package:vaulth_app/theme/theme_code/code_highlight_theme_cubit.dart';
import 'confirm_dialog.dart';
import 'info_row.dart';
import 'seed_phrase_creation_dialog.dart';
import 'totp_setup_dialog.dart';
import 'update_section.dart';

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

  void _showTotpSetupDialog(
    BuildContext context,
    String qrCodeUrl,
    String secret,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TotpSetupDialog(
        secret: secret,
        username: profile.username ?? "",
        onVerify: (code) {
          context.read<SettingsCubit>().verifyAndEnableTotp(code);
        },
      ),
    );
  }

  void _showTotpDisableDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TotpCodeDialog(
        onSubmit: (code) async {
          await context.read<SettingsCubit>().disableTotp(code);
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showBackupCodesDialog(BuildContext context, List<String> backupCodes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Резервные коды'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Сохраните эти коды в надёжном месте. Они помогут восстановить доступ при утере устройства.',
              ),
              const SizedBox(height: 16),
              ...backupCodes.map(
                (code) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showSeedPhraseCreationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SeedPhraseCreationDialog(),
    );
  }

  void _showThemePickerDialog(BuildContext context, String currentTheme) {
    final themeNames = CodeView.themeMap.keys.toList();

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выберите тему'),
        children: themeNames.map((themeName) {
          return SimpleDialogOption(
            onPressed: () {
              context.read<CodeHighlightThemeCubit>().setTheme(themeName);
              Navigator.pop(context);
            },
            child: Row(
              children: [
                if (themeName == currentTheme)
                  const Icon(Icons.check, size: 20),
                const SizedBox(width: 8),
                Text(themeName),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storageUsage =
        (profile.storageUsed != null && profile.storageLimit != null)
        ? profile.storageUsed! / profile.storageLimit!
        : 0.0;
    final isTotpEnabled = profile.totpEnabled ?? false;

    return BlocListener<SettingsCubit, SettingsState>(
      listener: (context, state) {
        state.whenOrNull(
          totpSetupReady: (qrCodeUrl, secret) {
            _showTotpSetupDialog(context, qrCodeUrl, secret);
          },
          totpEnabled: (backupCodes) {
            _showBackupCodesDialog(context, backupCodes);
            context.read<SettingsCubit>().loadSettingsData();
          },
          totpDisabled: () {
            context.read<SettingsCubit>().loadSettingsData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Двухфакторная аутентификация отключена'),
              ),
            );
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          },
        );
      },
      child: Padding(
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
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    BlocBuilder<ThemeCubit, ThemeState>(
                      builder: (context, state) {
                        return SwitchListTile(
                          secondary: Icon(
                            state.isDark ? Icons.dark_mode : Icons.light_mode,
                          ),
                          title: const Text('Тема приложения'),
                          subtitle: Text(
                            state.isDark ? 'Тёмная тема' : 'Светлая тема',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          value: state.isDark,
                          onChanged: (value) {
                            context.read<ThemeCubit>().setThemeBrightness(
                              value ? Brightness.dark : Brightness.light,
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child:
                          BlocBuilder<
                            CodeHighlightThemeCubit,
                            CodeHighlightThemeState
                          >(
                            builder: (context, state) {
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.code),
                                title: const Text('Тема подсветки'),
                                subtitle: Text(state.themeName),
                                trailing: const Icon(Icons.arrow_drop_down),
                                onTap: () => _showThemePickerDialog(
                                  context,
                                  state.themeName,
                                ),
                              );
                            },
                          ),
                    ),
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
                  SwitchListTile(
                    secondary: const Icon(Icons.security),
                    title: const Text('Двухфакторная аутентификация (TOTP)'),
                    subtitle: Text(
                      isTotpEnabled ? 'Включена' : 'Отключена',
                      style: TextStyle(
                        color: isTotpEnabled ? Colors.green : Colors.grey,
                      ),
                    ),
                    value: isTotpEnabled,
                    onChanged: (enabled) {
                      if (enabled) {
                        context.read<SettingsCubit>().startTotpSetup();
                      } else {
                        _showTotpDisableDialog(context);
                      }
                    },
                  ),
                  if (isTotpEnabled) ...[
                    const Divider(height: 0, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.vpn_key_off),
                      title: const Text('Отключить TOTP'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showTotpDisableDialog(context),
                    ),
                  ],
                  const Divider(height: 0, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.key),
                    title: const Text('Резервная seed-фраза'),
                    subtitle: const Text(
                      'Создать фразу для восстановления доступа',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showSeedPhraseCreationDialog(context),
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
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
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
            const SizedBox(height: 20),

            const UpdateSection(),
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
      ),
    );
  }
}

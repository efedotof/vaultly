import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/keys_manager/widget/widget.dart';
import 'package:vaulth_app/features/settings/cubit/settings_cubit.dart';

@RoutePage()
class KeysManagerScreen extends StatefulWidget {
  const KeysManagerScreen({super.key});

  @override
  State<KeysManagerScreen> createState() => _KeysManagerScreenState();
}

class _KeysManagerScreenState extends State<KeysManagerScreen> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<SettingsCubit>().loadSettingsData();
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showPublicKey() async {
    final publicKey = await context.read<SettingsCubit>().getPublicKey();
    if (!mounted) return;
    if (publicKey != null) {
      showDialog(
        context: context,
        builder: (context) =>
            KeyDialog(title: 'Публичный ключ (PEM)', content: publicKey),
      );
    } else {
      _showSnackBar('Публичный ключ не найден', isError: true);
    }
  }

  Future<void> _showPrivateKey() async {
    _passwordController.clear();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => PasswordInputDialog(
        title: 'Приватный ключ',
        label: 'Пароль для расшифровки',
        controller: _passwordController,
      ),
    );
    if (password != null && password.isNotEmpty) {
      if (!mounted) return;
      final privateKey = await context.read<SettingsCubit>().getPrivateKey(
        password,
      );

      if (!mounted) return;
      if (privateKey != null) {
        showDialog(
          context: context,
          builder: (context) =>
              KeyDialog(title: 'Приватный ключ (PEM)', content: privateKey),
        );
      } else {
        _showSnackBar('Не удалось получить приватный ключ', isError: true);
      }
    }
  }

  Future<void> _showDevicePublicKey() async {
    final publicKey = await context.read<SettingsCubit>().getDevicePublicKey();

    if (!mounted) return;
    if (publicKey != null) {
      showDialog(
        context: context,
        builder: (context) => KeyDialog(
          title: 'Публичный ключ устройства (PEM)',
          content: publicKey,
        ),
      );
    } else {
      _showSnackBar('Публичный ключ устройства не найден', isError: true);
    }
  }

  Future<void> _showDevicePrivateKey() async {
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => PasswordInputDialog(
        title: 'Приватный ключ устройства',
        label: 'Пароль для расшифровки',
        controller: passwordController,
      ),
    );

    passwordController.dispose();

    if (password != null && password.isNotEmpty) {
      if (!mounted) return;
      final privateKey = await context
          .read<SettingsCubit>()
          .getDevicePrivateKeyPEM(password);

      if (!mounted) return;
      if (privateKey != null) {
        showDialog(
          context: context,
          builder: (context) => KeyDialog(
            title: 'Приватный ключ устройства (PEM)',
            content: privateKey,
          ),
        );
      } else {
        _showSnackBar(
          'Не удалось получить приватный ключ устройства',
          isError: true,
        );
      }
    }
  }

  void _clearAllKeys() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Удалить все ключи',
        content:
            'Все сохранённые ключи будут удалены. Это действие необратимо. Продолжить?',
        confirmText: 'Удалить',
        isDestructive: true,
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      context.read<SettingsCubit>().clearAllKeys();
      _showSnackBar('Ключи удалены', isError: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocConsumer<SettingsCubit, SettingsState>(
            listener: (context, state) {
              state.whenOrNull(
                error: (message) => _showSnackBar(message, isError: true),
              );
            },
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: state.maybeWhen(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  loaded: (_, _, _) => Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.1,
                    ),
                    child: KeysList(
                      onShowPublicKey: _showPublicKey,
                      onShowPrivateKey: _showPrivateKey,
                      onShowDevicePublicKey: _showDevicePublicKey,
                      onShowDevicePrivateKey: _showDevicePrivateKey,
                      onClearAllKeys: _clearAllKeys,
                    ),
                  ),
                  error: (message) =>
                      ErrorWidgets(message: message, onRetry: _refresh),
                  orElse: () =>
                      const Center(child: CircularProgressIndicator()),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.046,
            left: 24.0,
            right: 24.0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () => context.maybePop(),
                        ),
                        const SizedBox(width: 10),
                        const Text('Ключи'),
                      ],
                    ),

                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _refresh,
                          tooltip: 'Обновить',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

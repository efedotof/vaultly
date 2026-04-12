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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Ключи'),
        elevation: 0,
        scrolledUnderElevation: 4,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          state.whenOrNull(
            error: (message) => _showSnackBar(message, isError: true),
          );
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: state.when(
              initial: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              loaded: (_, _, _) => KeysList(
                onShowPublicKey: _showPublicKey,
                onShowPrivateKey: _showPrivateKey,
                onShowDevicePublicKey: _showDevicePublicKey,
                onShowDevicePrivateKey: _showDevicePrivateKey,
                onClearAllKeys: _clearAllKeys,
              ),
              error: (message) =>
                  ErrorWidgets(message: message, onRetry: _refresh),
              loggedOut: () => const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}

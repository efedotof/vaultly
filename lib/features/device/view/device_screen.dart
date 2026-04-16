import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/device/widget/widget.dart';
import 'package:vaulth_app/features/settings/cubit/settings_cubit.dart';
import 'package:vaulth_app/server/model/device/device_register_request/device_register_request.dart';
import 'package:vaulth_app/server/model/device/device_response/device_response.dart';
import 'package:vaulth_app/server/model/device/device_update_request/device_update_request.dart';
import 'package:vaulth_app/server/service/key_manager_service.dart';

@RoutePage()
class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _editNameController = TextEditingController();
  final _editTypeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _editNameController.dispose();
    _editTypeController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<SettingsCubit>().loadSettingsData();
  }

  void _showRegisterDialog() {
    _nameController.clear();
    _typeController.clear();
    showDialog(
      context: context,
      builder: (context) => RegisterDeviceDialog(
        nameController: _nameController,
        typeController: _typeController,
        onRegister: () {
          final name = _nameController.text.trim();
          final type = _typeController.text.trim();
          if (name.isNotEmpty && type.isNotEmpty) {
            context.read<SettingsCubit>().registerDevice(
              DeviceRegisterRequest(
                deviceName: name,
                deviceType: type,
                publicKey: context
                    .read<KeyManagerService>()
                    .getPublicKey()
                    .toString(),
                encryptedPrivateKey: "",
                uniqueId: '',
              ),
            );
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showEditDialog(DeviceResponse device) {
    _editNameController.text = device.deviceName ?? '';
    _editTypeController.text = device.deviceType ?? '';
    showDialog(
      context: context,
      builder: (context) => EditDeviceDialog(
        nameController: _editNameController,
        typeController: _editTypeController,
        onSave: () {
          final newName = _editNameController.text.trim();
          if (newName.isNotEmpty) {
            context.read<SettingsCubit>().updateDevice(
              device.id!,
              DeviceUpdateRequest(deviceName: newName, isActive: true),
            );
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _deactivateDevice(String deviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Деактивировать устройство',
        content: 'Устройство будет деактивировано. Вы уверены?',
        confirmText: 'Деактивировать',
      ),
    );
    if (confirmed == true && mounted) {
      context.read<SettingsCubit>().deactivateDevice(deviceId);
    }
  }

  void _deleteDevice(String deviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Удалить устройство',
        content:
            'Устройство будет удалено без возможности восстановления. Вы уверены?',
        confirmText: 'Удалить',
        isDestructive: true,
      ),
    );
    if (confirmed == true && mounted) {
      context.read<SettingsCubit>().deleteDevice(deviceId);
    }
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
                  loaded: (_, devices, _, _, _, _, _) => Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.1,
                    ),
                    child: DevicesList(
                      devices: devices,
                      onEdit: _showEditDialog,
                      onDeactivate: _deactivateDevice,
                      onDelete: _deleteDevice,
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
                        const Text('Устройства'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRegisterDialog,
        label: const Text('Добавить'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vaulth_app/server/model/device/device_response/device_response.dart';

class DevicesList extends StatelessWidget {
  final List<DeviceResponse> devices;
  final Function(DeviceResponse) onEdit;
  final Function(String) onDeactivate;
  final Function(String) onDelete;

  const DevicesList({
    super.key,
    required this.devices,
    required this.onEdit,
    required this.onDeactivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет зарегистрированных устройств',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        top: kToolbarHeight + 24,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.devices,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              device.deviceName ?? 'Без названия',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${device.deviceType ?? 'не указан'} • ID: ${device.id ?? '?'}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit(device);
                    break;
                  case 'deactivate':
                    onDeactivate(device.id!);
                    break;
                  case 'delete':
                    onDelete(device.id!);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Редактировать'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Row(
                    children: [
                      Icon(
                        Icons.power_settings_new,
                        size: 20,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 12),
                      Text('Деактивировать'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Удалить'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

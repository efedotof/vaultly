import 'package:flutter/material.dart';

import 'action_button.dart';

class KeysList extends StatelessWidget {
  final VoidCallback onShowPublicKey;
  final VoidCallback onShowPrivateKey;
  final VoidCallback onShowDevicePublicKey;
  final VoidCallback onShowDevicePrivateKey;
  final VoidCallback onClearAllKeys;

  const KeysList({
    super.key,
    required this.onShowPublicKey,
    required this.onShowPrivateKey,
    required this.onShowDevicePublicKey,
    required this.onShowDevicePrivateKey,
    required this.onClearAllKeys,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
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
                  'Ключи пользователя',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ActionButton(
                  icon: Icons.vpn_key_outlined,
                  label: 'Публичный ключ',
                  onPressed: onShowPublicKey,
                ),
                const SizedBox(height: 8),
                ActionButton(
                  icon: Icons.lock_outline,
                  label: 'Приватный ключ',
                  onPressed: onShowPrivateKey,
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ключи устройства',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ActionButton(
                  icon: Icons.vpn_key_outlined,
                  label: 'Публичный ключ устройства',
                  onPressed: onShowDevicePublicKey,
                ),
                const SizedBox(height: 8),
                ActionButton(
                  icon: Icons.lock_outline,
                  label: 'Приватный ключ устройства',
                  onPressed: onShowDevicePrivateKey,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: onClearAllKeys,
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          label: const Text('Удалить все ключи'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

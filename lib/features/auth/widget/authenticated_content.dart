import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/auth/cubit/auth_cubit.dart';
import 'package:vaulth_app/server/model/auth/auth_response/auth_response.dart';
import 'password_dialog.dart';

class AuthenticatedContent extends StatefulWidget {
  const AuthenticatedContent({
    super.key,
    required this.authResponse,
    required this.deviceNameController,
    required this.deviceTypeController,
    required this.onCheckAuthStatus,
    required this.onLogout,
    required this.onShowSnackBar,
  });

  final AuthResponse authResponse;
  final TextEditingController deviceNameController;
  final TextEditingController deviceTypeController;
  final VoidCallback onCheckAuthStatus;
  final VoidCallback onLogout;
  final void Function(String message, {bool isError}) onShowSnackBar;

  @override
  State<AuthenticatedContent> createState() => _AuthenticatedContentState();
}

class _AuthenticatedContentState extends State<AuthenticatedContent> {
  bool _isRegisteringDevice = false;

  void _registerDevice(AuthResponse authResponse) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordDialog(
        onConfirm: (password) async {
          setState(() => _isRegisteringDevice = true);
          try {
            await context.read<AuthCubit>().registerDevice(
              deviceName: widget.deviceNameController.text.trim(),
              deviceType: widget.deviceTypeController.text.trim(),
              authResponse: authResponse,
              userPassword: password,
            );
            if (mounted) {
              widget.onShowSnackBar('Устройство успешно зарегистрировано');
              widget.deviceNameController.clear();
              widget.deviceTypeController.clear();
            }
          } catch (e) {
            if (mounted) {
              widget.onShowSnackBar(
                'Ошибка регистрации устройства: $e',
                isError: true,
              );
            }
          } finally {
            if (mounted) setState(() => _isRegisteringDevice = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authResponse = widget.authResponse;
    final String tokenPreview = authResponse.accessToken != null
        ? (authResponse.accessToken!.length > 20
              ? '${authResponse.accessToken!.substring(0, 20)}...'
              : authResponse.accessToken!)
        : 'No token';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        'Welcome, ${authResponse.username}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Username: ${authResponse.username}'),
                  const SizedBox(height: 4),
                  Text(
                    'Token: $tokenPreview',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Register Device',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.deviceNameController,
            decoration: const InputDecoration(
              labelText: 'Device Name',
              prefixIcon: Icon(Icons.devices),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.deviceTypeController,
            decoration: const InputDecoration(
              labelText: 'Device Type (e.g., mobile, web)',
              prefixIcon: Icon(Icons.smartphone),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRegisteringDevice
                  ? null
                  : () => _registerDevice(authResponse),
              icon: _isRegisteringDevice
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Register Device'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onCheckAuthStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Status'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

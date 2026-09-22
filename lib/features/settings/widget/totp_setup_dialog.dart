import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vaulth_app/features/settings/cubit/settings_cubit.dart';

class TotpSetupDialog extends StatefulWidget {
  final String secret;
  final String username;
  final Function(String) onVerify;

  const TotpSetupDialog({
    super.key,
    required this.secret,
    required this.username,
    required this.onVerify,
  });

  @override
  State<TotpSetupDialog> createState() => _TotpSetupDialogState();
}

class _TotpSetupDialogState extends State<TotpSetupDialog> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _clearFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }

  String _getCode() {
    return _controllers.map((c) => c.text).join();
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (_getCode().length == 6 && !_isVerifying) {
      _verify();
    }
  }

  void _verify() {
    final code = _getCode();
    if (code.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите 6-значный код')));
      return;
    }
    setState(() => _isVerifying = true);
    widget.onVerify(code);
  }

  String get _otpAuthUrl =>
      'otpauth://totp/Vaultly:${Uri.encodeComponent(widget.username)}?secret=${widget.secret}&issuer=Vaultly';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogPadding = screenWidth < 400 ? 16.0 : 24.0;
    const double maxCellWidth = 56.0;
    const double minCellWidth = 42.0;

    final double availableWidth = screenWidth - (dialogPadding * 2) - 40;
    final double cellWidth = (availableWidth / 6).clamp(
      minCellWidth,
      maxCellWidth,
    );

    return BlocListener<SettingsCubit, SettingsState>(
      listener: (context, state) {
        state.whenOrNull(
          totpEnabled: (_) {
            if (mounted) Navigator.pop(context);
          },
          error: (message) {
            if (mounted) {
              setState(() => _isVerifying = false);
              _clearFields();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message), backgroundColor: Colors.red),
              );
            }
          },
        );
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: EdgeInsets.all(dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Настройка двухфакторной аутентификации',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Отсканируйте QR-код в приложении-аутентификаторе\n(Google Authenticator, Authy и др.)',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: _otpAuthUrl,
                version: QrVersions.auto,
                size: 200,
                gapless: false,
              ),
              const SizedBox(height: 8),
              Text(
                'Или введите секрет вручную:',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              SelectableText(
                widget.secret,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
              ),
              const SizedBox(height: 24),
              Center(
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: cellWidth,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        enabled: !_isVerifying,
                        style: const TextStyle(fontSize: 24),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) => _onCodeChanged(index, value),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isVerifying
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isVerifying ? null : _verify,
                    child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Подтвердить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

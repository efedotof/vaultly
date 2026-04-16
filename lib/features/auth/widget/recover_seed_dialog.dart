import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/auth/cubit/auth_cubit.dart';
import 'package:vaulth_app/server/service/seed_phrase_service.dart';

import 'word_fields.dart';
import 'password_fields.dart';

class RecoverSeedDialog extends StatefulWidget {
  const RecoverSeedDialog({super.key});

  @override
  State<RecoverSeedDialog> createState() => _RecoverSeedDialogState();
}

class _RecoverSeedDialogState extends State<RecoverSeedDialog> {
  static const int _wordCount = 24;

  late final List<TextEditingController> _wordControllers;
  late final List<FocusNode> _wordFocusNodes;

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _wordControllers = List.generate(
      _wordCount,
      (_) => TextEditingController(),
    );
    _wordFocusNodes = List.generate(_wordCount, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _wordControllers) {
      c.dispose();
    }
    for (final f in _wordFocusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getMnemonic() =>
      _wordControllers.map((c) => c.text.trim().toLowerCase()).join(' ');

  bool _isStepValid() {
    if (_currentStep == 0) {
      return SeedPhraseService.validateMnemonic(_getMnemonic());
    } else {
      final p = _passwordController.text;
      final c = _confirmPasswordController.text;
      return p.length >= 6 && p == c;
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      final mnemonic = _getMnemonic();
      if (!SeedPhraseService.validateMnemonic(mnemonic)) {
        setState(() => _error = 'Некорректная seed-фраза. Проверьте слова.');
        return;
      }
      setState(() {
        _currentStep = 1;
        _error = null;
      });
    } else {
      _performRecovery();
    }
  }

  void _previousStep() {
    setState(() {
      _currentStep = 0;
      _error = null;
    });
  }

  Future<void> _performRecovery() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      setState(() => _error = 'Пароль должен содержать не менее 6 символов');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Пароли не совпадают');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthCubit>().recoverAccess(
        mnemonic: _getMnemonic(),
        newPassword: password,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Ошибка восстановления: $e';
        });
      }
    }
  }

  void _onWordChanged(int index, String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.length > 1) {
      for (int i = 0; i < words.length && index + i < _wordCount; i++) {
        _wordControllers[index + i].text = words[i];
      }
      int nextIndex = index + words.length;
      if (nextIndex < _wordCount) {
        _wordFocusNodes[nextIndex].requestFocus();
      } else {
        _wordFocusNodes[_wordCount - 1].unfocus();
      }
      setState(() {});
      return;
    }

    if (_error != null) {
      setState(() => _error = null);
    }
    setState(() {});
  }

  Future<void> _pasteMnemonic() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;

    final words = text.split(RegExp(r'\s+'));
    for (int i = 0; i < words.length && i < _wordCount; i++) {
      _wordControllers[i].text = words[i];
    }
    for (int i = words.length; i < _wordCount; i++) {
      _wordControllers[i].clear();
    }
    setState(() {});
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  void _toggleObscurePassword() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _clearError([String? _]) {
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isStepValid = _isStepValid();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Восстановление доступа',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Шаг ${_currentStep + 1} из 2',
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
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 2,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentStep == 0
                      ? WordFields(
                          key: const ValueKey('words'),
                          wordControllers: _wordControllers,
                          wordFocusNodes: _wordFocusNodes,
                          wordCount: _wordCount,
                          isLoading: _isLoading,
                          onWordChanged: _onWordChanged,
                          onPaste: _pasteMnemonic,
                        )
                      : PasswordFields(
                          key: const ValueKey('password'),
                          passwordController: _passwordController,
                          confirmPasswordController: _confirmPasswordController,
                          obscurePassword: _obscurePassword,
                          isLoading: _isLoading,
                          onToggleObscure: _toggleObscurePassword,
                          onChanged: _clearError,
                        ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep == 1)
                      TextButton(
                        onPressed: _isLoading ? null : _previousStep,
                        child: const Text('Назад'),
                      )
                    else
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                    FilledButton(
                      onPressed: (_isLoading || !isStepValid)
                          ? null
                          : _nextStep,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_currentStep == 0 ? 'Далее' : 'Восстановить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

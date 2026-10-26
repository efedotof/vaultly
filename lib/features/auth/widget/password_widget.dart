import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../global_widget/custom_text_field/custom_text_field.dart';

class PasswordRules {
  static const int minLength = 12;
  static const int maxLength = 64;

  final String value;

  PasswordRules(this.value);

  bool get lengthAtLeastMin => value.length >= minLength;
  bool get lengthAtMostMax => value.length <= maxLength;
  bool get hasLower => RegExp(r'[a-z]').hasMatch(value);
  bool get hasUpper => RegExp(r'[A-Z]').hasMatch(value);
  bool get hasDigit => RegExp(r'\d').hasMatch(value);
  bool get hasSpecial => RegExp(r'[^A-Za-z0-9]').hasMatch(value);

  bool get allValid =>
      lengthAtLeastMin &&
      lengthAtMostMax &&
      hasLower &&
      hasUpper &&
      hasDigit &&
      hasSpecial;

  String get firstFailingMessage {
    if (!lengthAtLeastMin) return 'Минимум $minLength символов';
    if (!lengthAtMostMax) return 'Максимум $maxLength символов';
    if (!hasLower) return 'Нужна строчная буква (a-z)';
    if (!hasUpper) return 'Нужна заглавная буква (A-Z)';
    if (!hasDigit) return 'Нужна цифра (0-9)';
    if (!hasSpecial) return 'Нужен спецсимвол (!@#\$%^&* и др.)';
    return '';
  }
}

class PasswordWidget extends StatelessWidget {
  const PasswordWidget({
    super.key,
    required this.onSubmit,
    required this.passwordController,
  });

  final ValueChanged<String> onSubmit;
  final TextEditingController passwordController;

  void _handleSubmit(BuildContext context) {
    final password = passwordController.text;
    final rules = PasswordRules(password);
    if (!rules.allValid) {
      Get.snackbar(
        'Пароль не соответствует требованиям',
        rules.firstFailingMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    onSubmit(password);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: passwordController,
      builder: (context, value, _) {
        final password = value.text;
        final rules = PasswordRules(password);
        final showError = password.isNotEmpty && !rules.allValid;

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Center(child: Text('Введите пароль')),

            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF525252),
                borderRadius: BorderRadius.circular(10),
                border: showError
                    ? Border.all(color: const Color(0xFFB00020), width: 1.5)
                    : null,
              ),
              child: CustomTextField(
                controller: passwordController,
                onSubmitted: (_) => _handleSubmit(context),
                isPassword: true,
                hintText: 'password'.tr,
                textInputAction: TextInputAction.done,
                autofocus: true,
                hasError: showError,
              ),
            ),

            _RulesList(password: password),

            OutlinedButton(
              onPressed: () => _handleSubmit(context),
              child: Text('continue'.tr),
            ),

            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: 'Забыли пароль?',
                style: const TextStyle(color: Colors.white54),
                children: const [
                  TextSpan(
                    text: ' Восстановите по seed-фразе ',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),

            RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                text: 'Используя приложение вы соглашаетесь с',
                style: TextStyle(color: Colors.white54, fontSize: 10),
                children: [
                  TextSpan(
                    text: ' Политикой конфиденциальности ',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  TextSpan(
                    text: 'и',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  TextSpan(
                    text: ' Пользовательским соглашением',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RulesList extends StatelessWidget {
  const _RulesList({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final rules = PasswordRules(password);
    final started = password.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RuleRow(
            label: 'Минимум ${PasswordRules.minLength} символов',
            valid: rules.lengthAtLeastMin,
            started: started,
          ),
          _RuleRow(
            label: 'Максимум ${PasswordRules.maxLength} символов',
            valid: rules.lengthAtMostMax,
            started: started,
          ),
          _RuleRow(
            label: 'Строчная буква (a-z)',
            valid: rules.hasLower,
            started: started,
          ),
          _RuleRow(
            label: 'Заглавная буква (A-Z)',
            valid: rules.hasUpper,
            started: started,
          ),
          _RuleRow(
            label: 'Цифра (0-9)',
            valid: rules.hasDigit,
            started: started,
          ),
          _RuleRow(
            label: 'Спецсимвол (!@#\$%^&* и др.)',
            valid: rules.hasSpecial,
            started: started,
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.label,
    required this.valid,
    required this.started,
  });

  final String label;
  final bool valid;
  final bool started;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;

    if (!started) {
      color = Colors.white38;
      icon = Icons.radio_button_unchecked;
    } else if (valid) {
      color = const Color(0xFF66BB6A);
      icon = Icons.check_circle;
    } else {
      color = const Color(0xFFEF5350);
      icon = Icons.cancel;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/settings/cubit/settings_cubit.dart';

class SeedPhraseCreationDialog extends StatefulWidget {
  const SeedPhraseCreationDialog({super.key});

  @override
  State<SeedPhraseCreationDialog> createState() =>
      _SeedPhraseCreationDialogState();
}

class _SeedPhraseCreationDialogState extends State<SeedPhraseCreationDialog> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        state.whenOrNull(
          seedReady: (mnemonic, words) {
            Navigator.pop(context);
            _showSeedPhraseResult(context, mnemonic, words);
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.red),
            );
          },
        );
      },
      builder: (context, state) {
        final isLoading = state.maybeWhen(
          seedGenerating: () => true,
          seedUpdating: () => true,
          orElse: () => false,
        );
        return AlertDialog(
          title: const Text('Подтверждение пароля'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Введите ваш пароль для создания резервной seed-фразы',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Введите пароль' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Внимание'),
                            content: const Text(
                              'Создание новой seed-фразы сделает недействительной предыдущую. '
                              'Убедитесь, что вы сохранили новую фразу в надёжном месте.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Отмена'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  context
                                      .read<SettingsCubit>()
                                      .generateAndUpdateSeedPhrase(
                                        _passwordController.text,
                                      );
                                },
                                child: const Text('Продолжить'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  void _showSeedPhraseResult(
    BuildContext context,
    String mnemonic,
    List<String> words,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 500,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Резервная seed-фраза',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Запишите эти 24 слова в правильном порядке и храните в надёжном месте. '
                  'Они позволят восстановить доступ к вашему аккаунту без пароля.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const double minItemWidth = 110.0;
                    int crossAxisCount = (constraints.maxWidth / minItemWidth)
                        .floor();
                    crossAxisCount = crossAxisCount.clamp(2, 4);

                    final double itemWidth =
                        (constraints.maxWidth - (crossAxisCount - 1) * 8) /
                        crossAxisCount;

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(words.length, (index) {
                        return SizedBox(
                          width: itemWidth,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '${index + 1}.',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                  ),
                                  child: Text(
                                    words[index],
                                    style: const TextStyle(fontSize: 13),
                                    softWrap: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: mnemonic));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Seed-фраза скопирована')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Скопировать'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<SettingsCubit>().loadSettingsData();
                      },
                      child: const Text('Готово'),
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

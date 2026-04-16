import 'package:flutter/material.dart';

class WordFields extends StatelessWidget {
  const WordFields({
    super.key,
    required this.wordControllers,
    required this.wordFocusNodes,
    required this.wordCount,
    required this.isLoading,
    required this.onWordChanged,
    required this.onPaste,
  });

  final List<TextEditingController> wordControllers;
  final List<FocusNode> wordFocusNodes;
  final int wordCount;
  final bool isLoading;
  final void Function(int index, String value) onWordChanged;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Введите вашу seed-фразу',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          '$wordCount слов в правильном порядке',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            const double minItemWidth = 110.0;

            int crossAxisCount = (constraints.maxWidth / minItemWidth).floor();
            crossAxisCount = crossAxisCount.clamp(2, 4);

            final double itemWidth =
                (constraints.maxWidth - (crossAxisCount - 1) * 8) /
                crossAxisCount;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(wordCount, (index) {
                return SizedBox(
                  width: itemWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                        child: TextField(
                          controller: wordControllers[index],
                          focusNode: wordFocusNodes[index],
                          textAlign: TextAlign.left,
                          textInputAction: index == wordCount - 1
                              ? TextInputAction.done
                              : TextInputAction.next,
                          textCapitalization: TextCapitalization.none,
                          enabled: !isLoading,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                          onSubmitted: (_) {
                            if (index < wordCount - 1) {
                              FocusScope.of(
                                context,
                              ).requestFocus(wordFocusNodes[index + 1]);
                            } else {
                              wordFocusNodes[index].unfocus();
                            }
                          },
                          onChanged: (value) => onWordChanged(index, value),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: isLoading ? null : onPaste,
          icon: const Icon(Icons.paste, size: 16),
          label: const Text('Вставить из буфера'),
        ),
      ],
    );
  }
}

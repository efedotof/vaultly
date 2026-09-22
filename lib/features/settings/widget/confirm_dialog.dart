import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final bool isDestructive;
  final Color? confirmColor;
  final VoidCallback confirmButton;
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmText,
    this.isDestructive = false,
    this.confirmColor,
    required this.confirmButton,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        confirmColor ??
        (isDestructive ? Theme.of(context).colorScheme.error : null);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(content),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: confirmButton,
                  style: color != null
                      ? FilledButton.styleFrom(backgroundColor: color)
                      : null,
                  child: Text(confirmText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

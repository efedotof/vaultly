import 'package:flutter/material.dart';

import 'file_icon_helper.dart';

class IconPlaceholder extends StatelessWidget {
  const IconPlaceholder({super.key, required this.fileName});
  final String fileName;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          getIconByExtension(fileName),
          color: Theme.of(context).colorScheme.primary,
          size: 48,
        ),
      ),
    );
  }
}

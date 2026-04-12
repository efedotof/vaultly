import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'content_type.dart';
import 'file_icon_helper.dart';

class PreviewContent extends StatelessWidget {
  const PreviewContent({
    super.key,
    required this.data,
    required this.type,
    required this.fileName,
  });
  final Uint8List data;
  final ContentType type;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ContentType.image:
        return Image.memory(
          data,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildIconPlaceholder(context),
        );
      case ContentType.text:
      case ContentType.binary:
        return _buildIconPlaceholder(context);
    }
  }

  Widget _buildIconPlaceholder(BuildContext context) {
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

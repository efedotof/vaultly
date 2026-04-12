import 'package:flutter/material.dart';

class DeletedWidgets extends StatelessWidget {
  const DeletedWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_delete_rounded, size: 64),
          SizedBox(height: 16),
          Text('Папка удалена'),
          SizedBox(height: 8),
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}

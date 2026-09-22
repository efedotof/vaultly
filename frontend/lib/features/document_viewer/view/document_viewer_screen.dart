import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'package:vaulth_app/features/document_viewer/widget/widget.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';

@RoutePage()
class DocumentViewerScreen extends StatelessWidget {
  final FileDto file;

  const DocumentViewerScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return DocumentViewerView(file: file);
  }
}

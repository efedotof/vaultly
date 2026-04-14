// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:open_filex/open_filex.dart';
// import 'package:path_provider/path_provider.dart';

// class OfficeViewer extends StatelessWidget {
//   final Uint8List data;
//   final String fileName;

//   const OfficeViewer({super.key, required this.data, required this.fileName});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.description_outlined,
//               size: 64,
//               color: Theme.of(
//                 context,
//               ).colorScheme.primary.withValues(alpha: 0.5),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               fileName,
//               style: Theme.of(
//                 context,
//               ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Предпросмотр документов Office недоступен внутри приложения.',
//               style: Theme.of(context).textTheme.bodyMedium,
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 24),
//             FilledButton.icon(
//               icon: const Icon(Icons.open_in_browser),
//               label: const Text('Открыть в другом приложении'),
//               onPressed: () => _openExternally(context),
//               style: FilledButton.styleFrom(
//                 minimumSize: const Size(220, 48),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _openExternally(BuildContext context) async {
//     try {
//       final tempDir = await getTemporaryDirectory();
//       final file = File('${tempDir.path}/$fileName');
//       await file.writeAsBytes(data);

//       final result = await OpenFilex.open(file.path);
//       if (!context.mounted) return;
//       if (result.type != ResultType.done) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Не удалось открыть файл: ${result.message}'),
//             backgroundColor: Theme.of(context).colorScheme.error,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Ошибка: $e'),
//           backgroundColor: Theme.of(context).colorScheme.error,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }
// }


import 'package:easy_docs_viewer/easy_docs_viewer.dart';
import 'package:flutter/material.dart';

class OfficeViewer extends StatelessWidget {
  final String publicUrl; 
  const OfficeViewer({super.key, required this.publicUrl});

  @override
  Widget build(BuildContext context) {
    return EasyDocsViewer(url: publicUrl);
  }
}
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveFileWeb(Uint8List data, String fileName) async {
  final blob = html.Blob([data]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

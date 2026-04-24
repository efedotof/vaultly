import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show compute;
import 'package:archive/archive.dart';
import 'package:shirm_crypto/shirm_crypto.dart';
import '../system/shirmps_header.dart';

class _DecryptParams {
  final Uint8List shpsBytes;
  final String privateKeyPem;
  final bool compressed;
  _DecryptParams({
    required this.shpsBytes,
    required this.privateKeyPem,
    required this.compressed,
  });
}

Future<Uint8List> _decryptInIsolate(_DecryptParams params) async {
  final decrypted = await ShirmCrypto.decryptData(
    shpsData: params.shpsBytes,
    privateKeyPem: params.privateKeyPem,
  );

  if (params.compressed) {
    final gzipDecoder = GZipDecoder();
    final decompressed = gzipDecoder.decodeBytes(decrypted);
    return Uint8List.fromList(decompressed);
  }

  return decrypted;
}

class ShirmDecryptionService {
  static Future<Uint8List> decryptShps(
    Uint8List shpsBytes, {
    required String privateKeyPem,
  }) async {
    final header = _extractShirmpsHeader(shpsBytes);
    final compressed = header.compressed;

    return compute(
      _decryptInIsolate,
      _DecryptParams(
        shpsBytes: shpsBytes,
        privateKeyPem: privateKeyPem,
        compressed: compressed,
      ),
    );
  }

  static Future<void> decryptShpsToFile(
    Uint8List shpsBytes, {
    required String outputPath,
    required String privateKeyPem,
  }) async {
    final decrypted = await decryptShps(
      shpsBytes,
      privateKeyPem: privateKeyPem,
    );
    await File(outputPath).writeAsBytes(decrypted);
  }

  static Future<void> decryptFileToFile(
    File inputFile,
    File outputFile, {
    required String privateKeyPem,
  }) async {
    final shpsData = await inputFile.readAsBytes();
    await decryptShpsToFile(
      shpsData,
      outputPath: outputFile.path,
      privateKeyPem: privateKeyPem,
    );
  }

  static Stream<Uint8List> decryptShpsChunked({
    required Stream<Uint8List> encryptedDataStream,
    ShirmpsHeader? header,
    int? headerLength,
    required String privateKeyPem,
    bool readHeaderFromStream = true,
  }) {
    throw UnsupportedError(
      'Chunked decryption is not supported on native platform',
    );
  }

  static ShirmpsHeader _extractShirmpsHeader(Uint8List shpsBytes) {
    final byteData = shpsBytes.buffer.asByteData(
      shpsBytes.offsetInBytes,
      shpsBytes.length,
    );
    final headerLength = byteData.getInt32(0, Endian.big);
    if (headerLength <= 0 || headerLength > 20 * 1024) {
      throw Exception('Invalid header length: $headerLength');
    }
    final headerBytes = shpsBytes.sublist(4, 4 + headerLength);
    return ShirmpsHeader.fromJsonBytes(headerBytes);
  }
}

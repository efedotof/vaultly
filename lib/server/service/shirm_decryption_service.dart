import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shirm_crypto/shirm_crypto.dart';

class ShirmDecryptionService {
  static Future<Uint8List> decryptShps(
    Uint8List shpsBytes, {
    required String privateKeyPem,
  }) async {
    try {
      final result = await ShirmCrypto.decryptData(
        shpsData: shpsBytes,
        privateKeyPem: privateKeyPem,
      );
      return result;
    } catch (_) {
      rethrow;
    }
  }

  static Future<void> decryptShpsToFile(
    Uint8List shpsBytes, {
    required String outputPath,
    required String privateKeyPem,
  }) async {
    try {
      await ShirmCrypto.decryptDataToFile(
        shpsData: shpsBytes,
        outputPath: outputPath,
        privateKeyPem: privateKeyPem,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> decryptFileToFile(
    File inputFile,
    File outputFile, {
    required String privateKeyPem,
  }) async {
    try {
      final shpsData = await inputFile.readAsBytes();
      await decryptShpsToFile(
        shpsData,
        outputPath: outputFile.path,
        privateKeyPem: privateKeyPem,
      );
    } catch (_) {
      rethrow;
    }
  }
}

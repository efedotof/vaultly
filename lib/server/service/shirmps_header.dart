import 'dart:convert';
import 'package:flutter/foundation.dart';

class ShirmpsHeader {
  static const String version = "1.0";
  static const String algorithm = "AES-256-GCM";
  static const String keyEncryption = "RSA-OAEP";

  DateTime creationDate;
  String? originalFileName;
  int? originalFileSize;
  String? encryptedKey;
  String? iv;
  String? signature;
  Map<String, String>? metadata;
  String? keyOwner;
  String? userId;

  ShirmpsHeader({DateTime? creationDate})
    : creationDate = creationDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'version': version,
      'algorithm': algorithm,
      'keyEncryption': keyEncryption,
      'creationDate': creationDate.toIso8601String(),
      'originalFileName': originalFileName,
      'originalFileSize': originalFileSize,
      'encryptedKey': encryptedKey,
      'iv': iv,
      'metadata': metadata,
      'keyOwner': keyOwner,
      'userId': userId,
    };
    if (signature != null) map['signature'] = signature;
    if (kDebugMode) {
      debugPrint('[ShirmpsHeader] toJson called');
    }
    return map;
  }

  static ShirmpsHeader fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      debugPrint('[ShirmpsHeader] fromJson called');
    }
    final header = ShirmpsHeader(
      creationDate: DateTime.parse(json['creationDate'] as String),
    );
    header.originalFileName = json['originalFileName'] as String?;
    header.originalFileSize = json['originalFileSize'] as int?;
    header.encryptedKey = json['encryptedKey'] as String?;
    header.iv = json['iv'] as String?;
    header.signature = json['signature'] as String?;
    header.metadata = (json['metadata'] as Map?)?.cast<String, String>();
    header.keyOwner = json['keyOwner'] as String?;
    header.userId = json['userId'] as String?;
    return header;
  }

  Uint8List toJsonBytes() {
    final bytes = utf8.encode(jsonEncode(toJson()));
    if (kDebugMode) {
      debugPrint('[ShirmpsHeader] toJsonBytes size: ${bytes.length} bytes');
    }
    return Uint8List.fromList(bytes);
  }

  static ShirmpsHeader fromJsonBytes(Uint8List bytes) {
    if (kDebugMode) {
      debugPrint('[ShirmpsHeader] fromJsonBytes size: ${bytes.length} bytes');
    }
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return fromJson(json);
  }
}

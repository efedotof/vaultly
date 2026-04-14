import 'dart:convert';
import 'dart:math';
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
    return map;
  }

  static ShirmpsHeader fromJson(Map<String, dynamic> json) {
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
    return Uint8List.fromList(bytes);
  }

  static ShirmpsHeader fromJsonBytes(Uint8List bytes) {
    try {
      final jsonString = utf8.decode(bytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(json);
    } catch (e) {
      rethrow;
    }
  }
}

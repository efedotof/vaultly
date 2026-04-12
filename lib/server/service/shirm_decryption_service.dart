import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/api.dart'
    show AEADParameters, KeyParameter, PrivateKeyParameter;
import 'shirmps_header.dart';

class ShirmDecryptionService {
  static Uint8List decryptShps(
    Uint8List shpsBytes, {
    required RSAPrivateKey privateKey,
  }) {
    final byteData = shpsBytes.buffer.asByteData(
      shpsBytes.offsetInBytes,
      shpsBytes.length,
    );
    final headerLength = byteData.getInt32(0, Endian.big);
    if (headerLength <= 0 || headerLength > 20 * 1024) {
      throw Exception('Invalid header length: $headerLength');
    }
    final headerBytes = shpsBytes.sublist(4, 4 + headerLength);
    final header = ShirmpsHeader.fromJsonBytes(headerBytes);
    final encryptedAesKey = base64.decode(header.encryptedKey!);
    final aesKeyBytes = _rsaOaepDecrypt(encryptedAesKey, privateKey);
    final iv = base64.decode(header.iv!);
    final encryptedData = shpsBytes.sublist(4 + headerLength);
    final decryptedData = _aesGcmDecrypt(encryptedData, aesKeyBytes, iv);

    return decryptedData;
  }

  static Uint8List _rsaOaepDecrypt(
    Uint8List encrypted,
    RSAPrivateKey privateKey,
  ) {
    final cipher = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return cipher.process(encrypted);
  }

  static Uint8List _aesGcmDecrypt(
    Uint8List ciphertext,
    Uint8List key,
    Uint8List iv,
  ) {
    final keyParam = KeyParameter(key);
    final gcm = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(keyParam, 128, iv, Uint8List(0)));

    final plaintext = Uint8List(gcm.getOutputSize(ciphertext.length));
    final len = gcm.processBytes(
      ciphertext,
      0,
      ciphertext.length,
      plaintext,
      0,
    );
    gcm.doFinal(plaintext, len);
    return plaintext;
  }
}

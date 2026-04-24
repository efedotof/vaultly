import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pointycastle/export.dart' as pc;
import 'package:basic_utils/basic_utils.dart';
import 'package:webcrypto/webcrypto.dart' as web;

class RsaKeyGeneratorWeb {
  static Future<({String publicKeyPem, String privateKeyPem})>
  generate() async {
    if (kIsWeb) {
      return _generateWeb();
    } else {
      return _generateNative();
    }
  }

  static ({String publicKeyPem, String privateKeyPem}) _generateNative() {
    final secureRandom = _getSecureRandom();
    final params = pc.RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64);
    final generator = pc.RSAKeyGenerator()
      ..init(pc.ParametersWithRandom(params, secureRandom));
    final pair = generator.generateKeyPair();
    final publicKey = pair.publicKey as pc.RSAPublicKey;
    final privateKey = pair.privateKey as pc.RSAPrivateKey;
    return (
      publicKeyPem: CryptoUtils.encodeRSAPublicKeyToPem(publicKey),
      privateKeyPem: CryptoUtils.encodeRSAPrivateKeyToPem(privateKey),
    );
  }

  static Future<({String publicKeyPem, String privateKeyPem})>
  _generateWeb() async {
    final keyPair = await web.RsaOaepPrivateKey.generateKey(
      2048,
      BigInt.from(65537),
      web.Hash.sha256,
    );

    final publicSpki = await keyPair.publicKey.exportSpkiKey();
    final publicPem = _spkiToPem(publicSpki);

    final privatePkcs8 = await keyPair.privateKey.exportPkcs8Key();
    final privatePem = _pkcs8ToPem(privatePkcs8);

    return (publicKeyPem: publicPem, privateKeyPem: privatePem);
  }

  static String _spkiToPem(Uint8List spki) {
    final b64 = base64Encode(spki);
    return '-----BEGIN PUBLIC KEY-----\n$b64\n-----END PUBLIC KEY-----';
  }

  static String _pkcs8ToPem(Uint8List pkcs8) {
    final b64 = base64Encode(pkcs8);
    return '-----BEGIN PRIVATE KEY-----\n$b64\n-----END PRIVATE KEY-----';
  }

  static pc.SecureRandom _getSecureRandom() {
    final secureRandom = pc.FortunaRandom();
    final seed = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seed)));
    return secureRandom;
  }
}

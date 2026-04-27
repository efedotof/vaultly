import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:webcrypto/webcrypto.dart' as web;
import '../system/shirmps_header.dart';

class ShirmEncryptionService {
  static const int defaultChunkSize = 1024 * 1024;

  static Future<Uint8List> encryptBytes(
    Uint8List originalBytes, {
    required String publicKeyPem,
    required String userId,
    required String keyOwner,
    String? privateKeyPem,
    String? originalFileName,
    bool compress = false,
  }) async {
    Uint8List dataToEncrypt = originalBytes;
    if (compress) {
      final gzipEncoder = GZipEncoder();
      dataToEncrypt = Uint8List.fromList(gzipEncoder.encode(originalBytes));
    }

    final aesKey = _generateRandomBytes(32);
    final iv = _generateRandomBytes(12);

    final encryptedData = await _aesGcmEncrypt(dataToEncrypt, aesKey, iv);
    final publicKey = await _importPublicKeyFromPem(publicKeyPem);
    final encryptedKey = await publicKey.encryptBytes(aesKey);

    final header = ShirmpsHeader(creationDate: DateTime.now())
      ..originalFileName = originalFileName ?? 'file.bin'
      ..originalFileSize = originalBytes.length
      ..encryptedKey = base64.encode(encryptedKey)
      ..iv = base64.encode(iv)
      ..metadata = {}
      ..keyOwner = keyOwner
      ..userId = userId;

    if (compress) {
      header.metadata!['compressed'] = 'true';
    }

    final headerBytes = header.toJsonBytes();
    final headerLength = headerBytes.length;
    final result = Uint8List(4 + headerBytes.length + encryptedData.length);
    final byteData = ByteData.view(result.buffer);
    byteData.setInt32(0, headerLength, Endian.big);
    result.setAll(4, headerBytes);
    result.setAll(4 + headerBytes.length, encryptedData);

    return result;
  }

  static Future<({Uint8List header, Stream<Uint8List> encryptedChunks})>
  encryptBytesChunked(
    Stream<Uint8List> plaintextStream, {
    required String publicKeyPem,
    required String userId,
    required String keyOwner,
    String? originalFileName,
    required int originalSize,
    bool compress = false,
    int chunkSize = defaultChunkSize,
  }) async {
    final aesKey = _generateRandomBytes(32);
    final masterIv = _generateRandomBytes(12);

    final publicKey = await _importPublicKeyFromPem(publicKeyPem);
    final encryptedKey = await publicKey.encryptBytes(aesKey);

    final List<String> chunkIvs = [];
    final List<int> encryptedChunkSizes = [];
    final chunkController = StreamController<Uint8List>();

    Stream<Uint8List> dataToEncrypt = plaintextStream;
    int finalSize = originalSize;
    if (compress) {
      final allData = await plaintextStream.reduce(
        (a, b) => Uint8List.fromList([...a, ...b]),
      );
      final compressed = GZipEncoder().encode(allData);
      dataToEncrypt = Stream.value(Uint8List.fromList(compressed));
      finalSize = compressed.length;
    }

    int chunkIndex = 0;

    await for (final chunk in _chunkStream(dataToEncrypt, chunkSize)) {
      final iv = _generateRandomBytes(12);
      chunkIvs.add(base64.encode(iv));
      final encryptedChunk = await _aesGcmEncrypt(chunk, aesKey, iv);
      chunkController.add(encryptedChunk);
      encryptedChunkSizes.add(encryptedChunk.length);

      chunkIndex++;
    }
    await chunkController.close();

    final header = ShirmpsHeader(creationDate: DateTime.now())
      ..originalFileName = originalFileName ?? 'file.bin'
      ..originalFileSize = finalSize
      ..encryptedKey = base64.encode(encryptedKey)
      ..iv = base64.encode(masterIv)
      ..metadata = {
        'chunked': 'true',
        'chunkSize': chunkSize.toString(),
        'chunkCount': chunkIndex.toString(),
        'chunkIvs': jsonEncode(chunkIvs),
        'encryptedChunkSizes': jsonEncode(encryptedChunkSizes),
        if (compress) 'compressed': 'true',
      }
      ..keyOwner = keyOwner
      ..userId = userId;

    final headerBytes = header.toJsonBytes();
    final headerLength = headerBytes.length;
    final headerPacket = Uint8List(4 + headerBytes.length);
    final byteData = ByteData.view(headerPacket.buffer);
    byteData.setInt32(0, headerLength, Endian.big);
    headerPacket.setAll(4, headerBytes);

    return (header: headerPacket, encryptedChunks: chunkController.stream);
  }

  static Stream<Uint8List> _chunkStream(
    Stream<Uint8List> stream,
    int chunkSize,
  ) async* {
    List<int> buffer = [];
    await for (final data in stream) {
      buffer.addAll(data);
      while (buffer.length >= chunkSize) {
        yield Uint8List.fromList(buffer.sublist(0, chunkSize));
        buffer = buffer.sublist(chunkSize);
      }
    }
    if (buffer.isNotEmpty) {
      yield Uint8List.fromList(buffer);
    }
  }

  static Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Future<web.RsaOaepPublicKey> _importPublicKeyFromPem(
    String pem,
  ) async {
    final b64 = _pemToBase64(pem);
    final spki = base64Decode(b64);
    return await web.RsaOaepPublicKey.importSpkiKey(spki, web.Hash.sha256);
  }

  static String _pemToBase64(String pem) {
    return pem
        .replaceFirst(RegExp(r'-----BEGIN [A-Z ]+-----'), '')
        .replaceFirst(RegExp(r'-----END [A-Z ]+-----'), '')
        .replaceAll(RegExp(r'\s'), '');
  }

  static Future<Uint8List> _aesGcmEncrypt(
    Uint8List plaintext,
    Uint8List key,
    Uint8List iv,
  ) async {
    final secretKey = await web.AesGcmSecretKey.importRawKey(key);
    return await secretKey.encryptBytes(plaintext, iv);
  }
}

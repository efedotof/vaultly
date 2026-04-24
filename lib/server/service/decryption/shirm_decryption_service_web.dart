import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:webcrypto/webcrypto.dart' as web;
import 'package:archive/archive.dart';
import '../system/shirmps_header.dart';

class ShirmDecryptionService {
  static Future<Uint8List> decryptShps(
    Uint8List shpsBytes, {
    required String privateKeyPem,
  }) async {
    try {
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

      if (header.encryptedKey == null || header.iv == null) {
        throw Exception('Missing encryptedKey or iv');
      }

      final encryptedAesKey = base64.decode(header.encryptedKey!);
      final iv = base64.decode(header.iv!);

      Uint8List? aesKeyBytes;
      final errors = <Exception>[];

      for (final hash in [web.Hash.sha256, web.Hash.sha1]) {
        try {
          final privateKey = await _importRsaOaepPrivateKey(
            privateKeyPem,
            hash,
          );
          aesKeyBytes = await privateKey.decryptBytes(encryptedAesKey);
          break;
        } catch (e) {
          errors.add(Exception('Failed with hash $hash: $e'));
        }
      }

      if (aesKeyBytes == null) {
        throw Exception(
          'Failed to decrypt AES key with any hash. Errors: $errors',
        );
      }

      final encryptedData = shpsBytes.sublist(4 + headerLength);
      final aesKey = await web.AesGcmSecretKey.importRawKey(aesKeyBytes);
      final decryptedData = await aesKey.decryptBytes(encryptedData, iv);

      if (header.metadata?['compressed'] == 'true' || header.compressed) {
        try {
          final gzipDecoder = GZipDecoder();
          final decompressed = gzipDecoder.decodeBytes(decryptedData);
          return Uint8List.fromList(decompressed);
        } catch (e) {
          throw Exception('Failed to decompress gzip data: $e');
        }
      }

      return decryptedData;
    } catch (e) {
      rethrow;
    }
  }

  static Stream<Uint8List> decryptShpsChunked({
    required Stream<Uint8List> encryptedDataStream,
    ShirmpsHeader? header,
    int? headerLength,
    required String privateKeyPem,
    bool readHeaderFromStream = true,
  }) async* {
    Stream<Uint8List> remainingStream = encryptedDataStream;
    ShirmpsHeader effectiveHeader;

    if (readHeaderFromStream) {
      final headerLenBuffer = await _readExactly(encryptedDataStream, 4);
      final actualHeaderLength = ByteData.view(
        headerLenBuffer.buffer,
      ).getInt32(0, Endian.big);
      if (actualHeaderLength <= 0 || actualHeaderLength > 20 * 1024) {
        throw Exception('Invalid header length: $actualHeaderLength');
      }

      final headerBytes = await _readExactly(
        encryptedDataStream,
        actualHeaderLength,
      );
      effectiveHeader = ShirmpsHeader.fromJsonBytes(headerBytes);
      remainingStream = encryptedDataStream;
    } else {
      if (header == null) {
        throw ArgumentError(
          'Header must be provided when readHeaderFromStream is false',
        );
      }
      effectiveHeader = header;
      if (headerLength != null) {
        await _readExactly(encryptedDataStream, headerLength);
        remainingStream = encryptedDataStream;
      }
    }

    final isChunked = effectiveHeader.metadata?['chunked'] == 'true';
    if (!isChunked) {
      throw Exception(
        'Not a chunked file. For non-chunked files, use decryptShps (but beware of memory limits for large files).',
      );
    }

    final chunkCount = effectiveHeader.metadata!['chunkCount'] as int;
    final chunkIvsBase64 = (effectiveHeader.metadata!['chunkIvs'] as List)
        .cast<String>();
    final encryptedAesKey = base64.decode(effectiveHeader.encryptedKey!);

    Uint8List? aesKeyBytes;
    for (final hash in [web.Hash.sha256, web.Hash.sha1]) {
      try {
        final privateKey = await _importRsaOaepPrivateKey(privateKeyPem, hash);
        aesKeyBytes = await privateKey.decryptBytes(encryptedAesKey);
        break;
      } catch (_) {}
    }
    if (aesKeyBytes == null) throw Exception('Failed to decrypt AES key');
    final aesKey = await web.AesGcmSecretKey.importRawKey(aesKeyBytes);

    final List<int>? compressedBuffer =
        effectiveHeader.metadata?['compressed'] == 'true' ? [] : null;

    final encryptedChunkSizes =
        effectiveHeader.metadata!['encryptedChunkSizes'] as List<dynamic>?;
    if (encryptedChunkSizes == null ||
        encryptedChunkSizes.length != chunkCount) {
      throw Exception('Missing encrypted chunk sizes in metadata');
    }

    final List<int> sizes = encryptedChunkSizes.cast<int>();

    for (int i = 0; i < chunkCount; i++) {
      final iv = base64.decode(chunkIvsBase64[i]);
      final encryptedChunk = await _readExactly(remainingStream, sizes[i]);
      final decryptedChunk = await aesKey.decryptBytes(encryptedChunk, iv);
      if (compressedBuffer != null) {
        compressedBuffer.addAll(decryptedChunk);
      } else {
        yield decryptedChunk;
      }
    }

    if (compressedBuffer != null) {
      final decompressed = GZipDecoder().decodeBytes(
        Uint8List.fromList(compressedBuffer),
      );
      yield Uint8List.fromList(decompressed);
    }
  }

  static Future<web.RsaOaepPrivateKey> _importRsaOaepPrivateKey(
    String pem,
    web.Hash hash,
  ) async {
    final b64 = pem
        .replaceFirst('-----BEGIN PRIVATE KEY-----', '')
        .replaceFirst('-----END PRIVATE KEY-----', '')
        .replaceFirst('-----BEGIN RSA PRIVATE KEY-----', '')
        .replaceFirst('-----END RSA PRIVATE KEY-----', '')
        .replaceAll(RegExp(r'\s'), '');
    final keyData = base64Decode(b64);
    return await web.RsaOaepPrivateKey.importPkcs8Key(keyData, hash);
  }

  static Future<Uint8List> _readExactly(
    Stream<Uint8List> stream,
    int length,
  ) async {
    final completer = Completer<Uint8List>();
    List<int> buffer = [];
    int received = 0;
    StreamSubscription<Uint8List>? subscription;
    subscription = stream.listen(
      (data) {
        buffer.addAll(data);
        received += data.length;
        if (received >= length) {
          subscription?.cancel();
          completer.complete(Uint8List.fromList(buffer.sublist(0, length)));
        }
      },
      onError: (err) {
        if (!completer.isCompleted) completer.completeError(err);
      },
      onDone: () {
        if (!completer.isCompleted && received < length) {
          completer.completeError(
            Exception('Stream ended before reading $length bytes'),
          );
        }
      },
    );
    return completer.future;
  }
}

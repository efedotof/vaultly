import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import '../shirm_crypto_bindings_generated.dart';

class CryptoWorkerPool {
  CryptoWorkerPool._({int maxSize = 4}) : _maxSize = maxSize;

  static final CryptoWorkerPool instance = CryptoWorkerPool._();

  factory CryptoWorkerPool.custom({int maxSize = 4}) =>
      CryptoWorkerPool._(maxSize: maxSize);

  final int _maxSize;
  final List<_CryptoWorker> _idle = [];
  final Set<_CryptoWorker> _busy = {};
  final List<Completer<_CryptoWorker>> _waiters = [];
  int _spawned = 0;
  bool _disposed = false;

  Future<_CryptoWorker> _acquire() async {
    if (_disposed) throw StateError('Pool disposed');
    if (_idle.isNotEmpty) {
      final w = _idle.removeLast();
      _busy.add(w);
      return w;
    }
    if (_spawned < _maxSize) {
      _spawned++;
      final w = await _CryptoWorker.spawn();
      _busy.add(w);
      return w;
    }
    final c = Completer<_CryptoWorker>();
    _waiters.add(c);
    return c.future;
  }

  void _release(_CryptoWorker w) {
    if (_disposed) {
      w.dispose();
      return;
    }
    _busy.remove(w);
    if (_waiters.isNotEmpty) {
      final waiter = _waiters.removeAt(0);
      _busy.add(w);
      waiter.complete(w);
    } else {
      _idle.add(w);
    }
  }

  Future<Uint8List> encryptFile({
    required String inputPath,
    required String publicKeyPem,
    String? privateKeyPem,
    required String userId,
    required String keyOwner,
    String? originalFileName,
    bool compress = false,
  }) async {
    final w = await _acquire();
    try {
      return await w.encryptFile(
        inputPath: inputPath,
        publicKeyPem: publicKeyPem,
        privateKeyPem: privateKeyPem,
        userId: userId,
        keyOwner: keyOwner,
        originalFileName: originalFileName,
        compress: compress,
      );
    } finally {
      _release(w);
    }
  }

  Future<Uint8List> decryptData({
    required Uint8List shpsData,
    required String privateKeyPem,
  }) async {
    final w = await _acquire();
    try {
      return await w.decryptData(
        shpsData: shpsData,
        privateKeyPem: privateKeyPem,
      );
    } finally {
      _release(w);
    }
  }

  Future<void> clearKeyCache() async {
    final all = [..._idle, ..._busy];
    for (final w in all) {
      w.clearKeyCache();
    }
  }

  void dispose() {
    _disposed = true;
    for (final w in [..._idle, ..._busy]) {
      w.dispose();
    }
    _idle.clear();
    _busy.clear();
    for (final waiter in _waiters) {
      if (!waiter.isCompleted) {
        waiter.completeError(StateError('Pool disposed'));
      }
    }
    _waiters.clear();
  }
}


class _CryptoWorker {
  final ReceivePort _receivePort = ReceivePort();
  final Map<int, Completer<dynamic>> _pending = {};
  final Completer<SendPort> _initCompleter = Completer<SendPort>();
  late final SendPort _sendPort;
  int _nextId = 0;
  bool _disposed = false;

  _CryptoWorker._() {
    _receivePort.listen(_onMessage);
  }

  static Future<_CryptoWorker> spawn() async {
    final w = _CryptoWorker._();
    await Isolate.spawn(_workerMain, w._receivePort.sendPort);
    w._sendPort = await w._initCompleter.future;
    return w;
  }

  void _onMessage(dynamic msg) {
    if (msg is! Map) return;
    if (msg.containsKey('init') && !_initCompleter.isCompleted) {
      _initCompleter.complete(msg['sendPort'] as SendPort);
      return;
    }
    final id = msg['id'] as int?;
    if (id == null) return;
    final c = _pending.remove(id);
    if (c != null && !c.isCompleted) {
      if (msg.containsKey('error')) {
        c.completeError(Exception(msg['error']));
      } else {
        c.complete(msg['result']);
      }
    }
  }

  Future<Uint8List> encryptFile({
    required String inputPath,
    required String publicKeyPem,
    String? privateKeyPem,
    required String userId,
    required String keyOwner,
    String? originalFileName,
    bool compress = false,
  }) {
    final id = _nextId++;
    final c = Completer<Uint8List>();
    _pending[id] = c;
    _sendPort.send({
      'id': id,
      'op': 'encryptFile',
      'inputPath': inputPath,
      'publicKeyPem': publicKeyPem,
      'privateKeyPem': privateKeyPem,
      'userId': userId,
      'keyOwner': keyOwner,
      'originalFileName': originalFileName,
      'compress': compress,
    });
    return c.future;
  }

  Future<Uint8List> decryptData({
    required Uint8List shpsData,
    required String privateKeyPem,
  }) {
    final id = _nextId++;
    final c = Completer<Uint8List>();
    _pending[id] = c;
    _sendPort.send({
      'id': id,
      'op': 'decryptData',
      'shpsData': shpsData,
      'privateKeyPem': privateKeyPem,
    });
    return c.future;
  }

  void clearKeyCache() {
    _sendPort.send({'op': 'clearKeyCache', 'id': -1});
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _sendPort.send({'op': 'dispose', 'id': -1});
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(StateError('Worker disposed'));
    }
    _pending.clear();
    _receivePort.close();
  }
}



void _workerMain(SendPort initSendPort) {
  final receivePort = ReceivePort();
  initSendPort.send({'init': true, 'sendPort': receivePort.sendPort});

  final dylib = _loadLibrary();
  final bindings = ShirmCryptoBindings(dylib);

  receivePort.listen((msg) {
    if (msg is! Map) return;
    final op = msg['op'] as String?;
    if (op == 'dispose') {
      receivePort.close();
      return;
    }
    if (op == 'clearKeyCache') {
      bindings.shirm_crypto_clear_key_cache();
      return;
    }

    final id = msg['id'] as int;

    try {
      switch (op) {
        case 'encryptFile':
          final result = _doEncryptFile(bindings, msg);
          initSendPort.send({'id': id, 'result': result});
          break;
        case 'decryptData':
          final result = _doDecryptData(bindings, msg);
          initSendPort.send({'id': id, 'result': result});
          break;
        default:
          initSendPort.send({'id': id, 'error': 'Unknown op: $op'});
      }
    } catch (e) {
      initSendPort.send({'id': id, 'error': e.toString()});
    }
  });
}

Uint8List _doEncryptFile(ShirmCryptoBindings bindings, Map msg) {
  final arena = Arena();
  try {
    final resultPtr = bindings.shirm_encrypt_file(
      (msg['inputPath'] as String).toNativeUtf8(allocator: arena).cast(),
      (msg['publicKeyPem'] as String).toNativeUtf8(allocator: arena).cast(),
      (msg['privateKeyPem'] as String?)
              ?.toNativeUtf8(allocator: arena)
              .cast() ??
          nullptr.cast(),
      (msg['userId'] as String).toNativeUtf8(allocator: arena).cast(),
      (msg['keyOwner'] as String).toNativeUtf8(allocator: arena).cast(),
      ((msg['originalFileName'] as String?) ?? '')
          .toNativeUtf8(allocator: arena)
          .cast(),
      (msg['compress'] as bool) ? 1 : 0,
      nullptr,
      nullptr,
    );
    final result = resultPtr.ref;
    if (result.error != nullptr) {
      final err = result.error.cast<Utf8>().toDartString();
      bindings.shirm_free_encrypt_result(resultPtr);
      throw Exception(err);
    }
    final data = Uint8List.fromList(result.data.asTypedList(result.size));
    bindings.shirm_free_encrypt_result(resultPtr);
    return data;
  } finally {
    arena.releaseAll();
  }
}

Uint8List _doDecryptData(ShirmCryptoBindings bindings, Map msg) {
  final arena = Arena();
  try {
    final shpsData = msg['shpsData'] as Uint8List;
    final dataPtr = arena<Uint8>(shpsData.length);
    dataPtr.asTypedList(shpsData.length).setAll(0, shpsData);

    final resultPtr = bindings.shirm_decrypt_data(
      dataPtr,
      shpsData.length,
      (msg['privateKeyPem'] as String).toNativeUtf8(allocator: arena).cast(),
      nullptr,
      nullptr,
    );
    final result = resultPtr.ref;
    if (result.error != nullptr) {
      final err = result.error.cast<Utf8>().toDartString();
      bindings.shirm_free_decrypt_result(resultPtr);
      throw Exception(err);
    }
    final data = Uint8List.fromList(result.data.asTypedList(result.size));
    bindings.shirm_free_decrypt_result(resultPtr);
    return data;
  } finally {
    arena.releaseAll();
  }
}

DynamicLibrary _loadLibrary() {
  if (Platform.isMacOS || Platform.isIOS) return DynamicLibrary.process();
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('libshirm_crypto.so');
  }
  if (Platform.isWindows) return DynamicLibrary.open('shirm_crypto.dll');
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}
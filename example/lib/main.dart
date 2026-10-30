import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:basic_utils/basic_utils.dart';
import 'package:shirm_crypto/shirm_cache.dart';
import 'package:shirm_crypto/shirm_crypto.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Готов к тестированию';
  String _result = '';
  bool _isLoading = false;

  String? _publicKeyPem;
  String? _privateKeyPem;
  Uint8List? _encryptedData;
  String? _selectedFilePath;
  String? _lastEncryptedFilePath;

  StreamSubscription<Uint8List>? _streamSub;

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ShirmCrypto FFI Test v0.0.2')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Статус: $_status',
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ключи: ${_publicKeyPem != null ? "сгенерированы" : "нет"}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateKeys,
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('1. Сгенерировать RSA-ключи'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _selectAndEncryptFile,
                  icon: const Icon(Icons.lock),
                  label: const Text('2. Зашифровать (в память, через пул)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _selectAndEncryptFileStreaming,
                  icon: const Icon(Icons.stream),
                  label: const Text('3. Зашифровать (потоково, в файл)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: (_isLoading || _lastEncryptedFilePath == null)
                      ? null
                      : _startCancellableStream,
                  icon: const Icon(Icons.cancel_schedule_send),
                  label: const Text('4. Тест отмены стрима (авто через 500ms)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _streamSub == null ? null : _cancelStream,
                  icon: const Icon(Icons.stop_circle),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                  ),
                  label: const Text('Отменить текущий стрим'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _decryptLastData,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('5. Расшифровать (в память)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: (_isLoading || _lastEncryptedFilePath == null)
                      ? null
                      : _decryptLastFileStreaming,
                  icon: const Icon(Icons.lock_open_outlined),
                  label: const Text('6. Расшифровать (потоково, в файл)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _clearKeyCache,
                  icon: const Icon(Icons.refresh),
                  label: const Text('7. Сбросить кэш ключей во всех воркерах'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testParallelEncrypt,
                  icon: const Icon(Icons.grid_view),
                  label: const Text('8. Параллельно 4 шифрования (тест пула)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testCache,
                  icon: const Icon(Icons.storage),
                  label: const Text('9. Тест кэша (save/load/stream)'),
                ),
                const SizedBox(height: 20),
                const Divider(),
                if (_selectedFilePath != null)
                  Text(
                    'Выбранный файл: ${path.basename(_selectedFilePath!)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                if (_lastEncryptedFilePath != null)
                  Text(
                    'Зашифрованный файл: '
                    '${path.basename(_lastEncryptedFilePath!)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                const SizedBox(height: 10),
                Text(_result),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generateKeys() async {
    setState(() {
      _isLoading = true;
      _status = 'Генерация ключей...';
    });
    try {
      final keyPair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
      _publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(
        keyPair.publicKey as RSAPublicKey,
      );
      _privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(
        keyPair.privateKey as RSAPrivateKey,
      );
      setState(() {
        _status = 'Ключи сгенерированы (2048 бит)';
        _result = '✅ Готово. Публичный ключ:\n'
            '${_publicKeyPem!.substring(0, 100)}...';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка генерации ключей';
        _result = '❌ $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectAndEncryptFile() async {
    if (_publicKeyPem == null) {
      setState(() => _result = '❌ Сначала сгенерируйте ключи!');
      return;
    }

    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    setState(() {
      _isLoading = true;
      _status = 'Шифрование (через пул воркеров)...';
      _selectedFilePath = filePath;
      _result = '';
    });

    try {
      final sw = Stopwatch()..start();
      final encryptedBytes = await ShirmCrypto.encryptFile(
        inputPath: filePath,
        publicKeyPem: _publicKeyPem!,
        privateKeyPem: _privateKeyPem,
        userId: 'test-user',
        keyOwner: 'test-owner',
        originalFileName: path.basename(filePath),
        compress: true,
      );
      sw.stop();

      _encryptedData = encryptedBytes;
      final originalSize = await File(filePath).length();
      setState(() {
        _status = 'Файл зашифрован успешно!';
        _result = '✅ Шифрование завершено (через пул).\n'
            'Время: ${sw.elapsedMilliseconds} ms\n'
            'Исходный размер: $originalSize байт\n'
            'Зашифрованный: ${encryptedBytes.length} байт\n'
            'Данные в памяти — можно дешифровать (шаг 5).';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка шифрования';
        _result = '❌ $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectAndEncryptFileStreaming() async {
    if (_publicKeyPem == null) {
      setState(() => _result = '❌ Сначала сгенерируйте ключи!');
      return;
    }

    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    final inputPath = result.files.single.path!;
    final inputFile = File(inputPath);
    final dir = await getApplicationDocumentsDirectory();
    final outputPath =
        '${dir.path}/${path.basenameWithoutExtension(inputPath)}.shps';

    setState(() {
      _isLoading = true;
      _status = 'Потоковое шифрование файла...';
      _selectedFilePath = inputPath;
      _result = '';
    });

    try {
      final sw = Stopwatch()..start();
      await ShirmCrypto.encryptFileToFile(
        inputPath: inputPath,
        outputPath: outputPath,
        publicKeyPem: _publicKeyPem!,
        privateKeyPem: _privateKeyPem,
        userId: 'test-user',
        keyOwner: 'test-owner',
        originalFileName: path.basename(inputPath),
        compress: true,
      );
      sw.stop();

      _lastEncryptedFilePath = outputPath;
      final originalSize = await inputFile.length();
      final encryptedSize = await File(outputPath).length();
      setState(() {
        _status = 'Потоковое шифрование завершено!';
        _result = '✅ Файл зашифрован (потоково).\n'
            'Время: ${sw.elapsedMilliseconds} ms\n'
            'Исходный размер: $originalSize байт\n'
            'Зашифрованный: $encryptedSize байт\n'
            'Файл: $outputPath';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка потокового шифрования';
        _result = '❌ $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startCancellableStream() async {
    if (_lastEncryptedFilePath == null || _privateKeyPem == null) return;

    final inputPath = _lastEncryptedFilePath!;
    final dir = await getApplicationDocumentsDirectory();
    final outputPath = '${dir.path}/cancellable_test.out';

    setState(() {
      _isLoading = true;
      _status = 'Запуск стрима (авто-отмена через 500 ms)...';
      _result = '';
    });

    try {
      final file = File(outputPath);
      final sink = file.openWrite();
      var bytesWritten = 0;
      final sw = Stopwatch()..start();

      final encryptedData = await File(inputPath).readAsBytes();
      final stream = ShirmCrypto.decryptDataStream(
        shpsData: encryptedData,
        privateKeyPem: _privateKeyPem!,
      );

      _streamSub = stream.listen(
        (chunk) {
          sink.add(chunk);
          bytesWritten += chunk.length;
        },
        onError: (e) {
          setState(() {
            _status = 'Ошибка стрима';
            _result = '❌ $e';
          });
        },
        onDone: () async {
          await sink.close();
          sw.stop();
          if (_streamSub != null) {
            setState(() {
              _isLoading = false;
              _status = 'Стрим завершён (успел до отмены)';
              _result = '✅ Размер: $bytesWritten байт\n'
                  'Время: ${sw.elapsedMilliseconds} ms';
              _streamSub = null;
            });
          }
        },
        cancelOnError: true,
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (_streamSub != null && mounted) {
          _cancelStream();
        }
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка';
        _result = '❌ $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelStream() async {
    if (_streamSub == null) return;
    await _streamSub!.cancel();
    _streamSub = null;
    setState(() {
      _isLoading = false;
      _status = 'Стрим отменён';
      _result = '⏹ Отмена сработала — изолят должен остановиться';
    });
  }

  Future<void> _decryptLastData() async {
    if (_encryptedData == null) {
      setState(() => _result = '❌ Нет зашифрованных данных (шаг 2)');
      return;
    }
    if (_privateKeyPem == null) {
      setState(() => _result = '❌ Отсутствует приватный ключ');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Дешифрование данных...';
    });

    try {
      final sw = Stopwatch()..start();
      final decryptedBytes = await ShirmCrypto.decryptData(
        shpsData: _encryptedData!,
        privateKeyPem: _privateKeyPem!,
      );
      sw.stop();

      String preview;
      try {
        preview = String.fromCharCodes(decryptedBytes.take(500).toList());
      } catch (_) {
        preview = '[бинарные данные]';
      }

      setState(() {
        _status = 'Дешифрование успешно';
        _result = '✅ Размер: ${decryptedBytes.length} байт\n'
            'Время: ${sw.elapsedMilliseconds} ms\n'
            'Предпросмотр:\n$preview';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка дешифрования';
        _result = '❌ $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _decryptLastFileStreaming() async {
    if (_lastEncryptedFilePath == null) {
      setState(() => _result = '❌ Нет зашифрованного файла (шаг 3)');
      return;
    }
    if (_privateKeyPem == null) {
      setState(() => _result = '❌ Отсутствует приватный ключ');
      return;
    }

    final inputPath = _lastEncryptedFilePath!;
    final dir = await getApplicationDocumentsDirectory();
    final outputPath =
        '${dir.path}/${path.basenameWithoutExtension(inputPath)}.decrypted';

    setState(() {
      _isLoading = true;
      _status = 'Потоковое дешифрование файла...';
    });

    try {
      final sw = Stopwatch()..start();
      final encryptedData = await File(inputPath).readAsBytes();
      await ShirmCrypto.decryptDataToFile(
        shpsData: encryptedData,
        outputPath: outputPath,
        privateKeyPem: _privateKeyPem!,
      );
      sw.stop();

      final decryptedSize = await File(outputPath).length();
      setState(() {
        _status = 'Потоковое дешифрование завершено';
        _result = '✅ Файл: $outputPath\n'
            'Размер: $decryptedSize байт\n'
            'Время: ${sw.elapsedMilliseconds} ms';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка потокового дешифрования';
        _result = '❌ $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearKeyCache() async {
    try {
      await CryptoWorkerPool.instance.clearKeyCache();
      setState(() {
        _status = 'Кэш ключей сброшен';
        _result = '✅ shirm_crypto_clear_key_cache() вызван во всех воркерах';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка сброса кэша';
        _result = '❌ $e';
      });
    }
  }

  Future<void> _testParallelEncrypt() async {
    if (_publicKeyPem == null) {
      setState(() => _result = '❌ Сначала сгенерируйте ключи!');
      return;
    }

    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    setState(() {
      _isLoading = true;
      _status = 'Параллельное шифрование (4 задачи)...';
      _result = '';
    });

    try {
      final sw = Stopwatch()..start();
      final futures = List.generate(
        4,
        (i) => ShirmCrypto.encryptFile(
          inputPath: filePath,
          publicKeyPem: _publicKeyPem!,
          privateKeyPem: _privateKeyPem,
          userId: 'user-$i',
          keyOwner: 'owner-$i',
          originalFileName: 'parallel_$i.bin',
          compress: true,
        ),
      );
      final results = await Future.wait(futures);
      sw.stop();

      setState(() {
        _status = 'Параллельное шифрование завершено';
        _result = '✅ ${results.length} задач выполнено\n'
            'Wall clock: ${sw.elapsedMilliseconds} ms\n'
            'Размеры: ${results.map((r) => r.length).join(", ")}\n\n'
            'Примечание: первый вызов инициализирует воркеры '
            '(~50–100 ms × N), последующие — переиспользуют.';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка';
        _result = '❌ $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCache() async {
    setState(() {
      _isLoading = true;
      _status = 'Тест кэша...';
      _result = '';
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = '${dir.path}/test_cache';
      final cache = await ShirmCache.init(cacheDir);

      try {
        final data1 = Uint8List.fromList(
          List.generate(1000, (i) => i % 256),
        );
        await cache.save('file1', data1, originalName: 'test1.bin');
        final loaded1 = await cache.load('file1');
        final ok1 = _bytesEqual(data1, loaded1);

        final data2 = Uint8List.fromList(
          List.generate(500 * 1000, (i) => i % 256),
        );
        final stream = Stream.fromIterable([
          data2.sublist(0, 200 * 1000),
          data2.sublist(200 * 1000, 400 * 1000),
          data2.sublist(400 * 1000),
        ]);
        await cache.saveStream('file2', stream, originalName: 'test2.bin');

        final loaded2 = BytesBuilder();
        await for (final chunk in cache.loadStream('file2')) {
          loaded2.add(chunk);
        }
        final ok2 = _bytesEqual(data2, loaded2.takeBytes());

        final meta = await cache.getAllMetadata();

        setState(() {
          _status = 'Тест кэша завершён';
          _result = '✅ save/load: ${ok1 ? "OK" : "FAIL"}\n'
              '✅ saveStream/loadStream: ${ok2 ? "OK" : "FAIL"}\n'
              'Файлов в кэше: ${meta.length}\n'
              'Метаданные: $meta';
        });

        await cache.clear();
      } finally {
        cache.close();
      }
    } catch (e) {
      setState(() {
        _status = 'Ошибка кэша';
        _result = '❌ $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

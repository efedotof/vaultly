import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:basic_utils/basic_utils.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ShirmCrypto FFI Test')),
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
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateKeys,
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Сгенерировать RSA-ключи'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _selectAndEncryptFile,
                  icon: const Icon(Icons.lock),
                  label: const Text('Выбрать файл и зашифровать (в память)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _selectAndEncryptFileStreaming,
                  icon: const Icon(Icons.stream),
                  label: const Text('Выбрать файл и зашифровать (потоково)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _decryptLastData,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Расшифровать последние данные (в память)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isLoading || _lastEncryptedFilePath == null
                      ? null
                      : _decryptLastFileStreaming,
                  icon: const Icon(Icons.lock_open_outlined),
                  label: const Text('Расшифровать последний файл (потоково)'),
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
                    'Зашифрованный файл: ${path.basename(_lastEncryptedFilePath!)}',
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
        _result =
            '✅ Готово. Публичный ключ:\n${_publicKeyPem!.substring(0, 100)}...';
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

    final result = await FilePicker.pickFiles();
    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    setState(() {
      _isLoading = true;
      _status = 'Шифрование файла...';
      _selectedFilePath = filePath;
      _result = '';
    });

    try {
      final encryptedBytes = await ShirmCrypto.encryptFile(
        inputPath: filePath,
        publicKeyPem: _publicKeyPem!,
        privateKeyPem: _privateKeyPem,
        userId: 'test-user',
        keyOwner: 'test-owner',
        originalFileName: path.basename(filePath),
        compress: true,
      );

      _encryptedData = encryptedBytes;
      final originalSize = await File(filePath).length();
      setState(() {
        _status = 'Файл зашифрован успешно!';
        _result =
            '✅ Шифрование завершено.\n'
            'Исходный размер: $originalSize байт\n'
            'Зашифрованный размер: ${encryptedBytes.length} байт\n'
            'Данные сохранены в памяти для последующего дешифрования.';
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

    final result = await FilePicker.pickFiles();
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

      _lastEncryptedFilePath = outputPath;
      final originalSize = await inputFile.length();
      final encryptedSize = await File(outputPath).length();
      setState(() {
        _status = 'Потоковое шифрование завершено!';
        _result =
            '✅ Файл зашифрован (потоково).\n'
            'Исходный размер: $originalSize байт\n'
            'Зашифрованный размер: $encryptedSize байт\n'
            'Результат сохранён в: $outputPath';
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

  Future<void> _decryptLastData() async {
    if (_encryptedData == null) {
      setState(() => _result = '❌ Нет зашифрованных данных для дешифрования');
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
      final decryptedBytes = await ShirmCrypto.decryptData(
        shpsData: _encryptedData!,
        privateKeyPem: _privateKeyPem!,
      );

      String preview;
      try {
        preview = String.fromCharCodes(decryptedBytes.take(500).toList());
      } catch (_) {
        preview = '[бинарные данные]';
      }

      setState(() {
        _status = 'Дешифрование успешно';
        _result =
            '✅ Размер расшифрованных данных: ${decryptedBytes.length} байт\n'
            'Предпросмотр (первые 500 символов):\n$preview';
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
      setState(() => _result = '❌ Нет зашифрованного файла для дешифрования');
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
      final encryptedData = await File(inputPath).readAsBytes();
      await ShirmCrypto.decryptDataToFile(
        shpsData: encryptedData,
        outputPath: outputPath,
        privateKeyPem: _privateKeyPem!,
      );

      final decryptedSize = await File(outputPath).length();
      setState(() {
        _status = 'Потоковое дешифрование завершено';
        _result =
            '✅ Расшифрованный файл сохранён в: $outputPath\nРазмер: $decryptedSize байт';
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
}

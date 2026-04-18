import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:basic_utils/basic_utils.dart';
import 'package:shirm_crypto/shirm_crypto.dart';

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

  // Сгенерированная пара ключей для теста
  String? _publicKeyPem;
  String? _privateKeyPem;
  Uint8List? _encryptedData;
  String? _selectedFilePath;

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
                  label: const Text('Выбрать файл и зашифровать'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _decryptLastData,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Расшифровать последние данные'),
                ),
                const SizedBox(height: 20),
                const Divider(),
                if (_selectedFilePath != null)
                  Text('Выбранный файл: ${path.basename(_selectedFilePath!)}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
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
          keyPair.publicKey as RSAPublicKey);
      _privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(
          keyPair.privateKey as RSAPrivateKey);
      setState(() {
        _status = 'Ключи сгенерированы (2048 бит)';
        _result = '✅ Готово. Публичный ключ:\n${_publicKeyPem!.substring(0, 100)}...';
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
        privateKeyPem: _privateKeyPem, // добавляем подпись (если есть)
        userId: 'test-user',
        keyOwner: 'test-owner',
        originalFileName: path.basename(filePath),
        compress: true,
      );

      _encryptedData = encryptedBytes;
      final originalSize = await File(filePath).length();
      setState(() {
        _status = 'Файл зашифрован успешно!';
        _result = '✅ Шифрование завершено.\n'
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

      // Показываем первые 500 байт как текст (если это текст)
      String preview;
      try {
        preview = String.fromCharCodes(decryptedBytes.take(500).toList());
      } catch (_) {
        preview = '[бинарные данные]';
      }

      setState(() {
        _status = 'Дешифрование успешно';
        _result = '✅ Размер расшифрованных данных: ${decryptedBytes.length} байт\n'
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
}
# 🧬 shirm_crypto_c – нативная реализация шифрования SHIRMPS на чистом C

Эта ветка содержит полную реализацию Flutter FFI-плагина `shirm_crypto` на **языке C** с использованием OpenSSL и zlib. Код оптимизирован для высокой производительности и минимальных накладных расходов при работе с криптографией.

## 🔐 Возможности

- **Шифрование файлов** (AES-256-GCM + RSA-OAEP)
- **Сжатие GZIP** (опционально)
- **Цифровая подпись** (RSA-PSS) для проверки целостности
- **Потоковая обработка** с callback-уведомлениями о прогрессе
- Поддержка платформ: **macOS**, **Windows**, **Android**

## 📦 Зависимости

- OpenSSL (libcrypto, libssl)
- zlib

## 🛠️ Сборка и использование

Плагин полностью совместим с Flutter FFI и собирается стандартными средствами:

- **macOS**: CocoaPods (см. `macos/shirm_crypto.podspec`)
- **Windows**: CMake (см. `windows/CMakeLists.txt`)
- **Android**: Gradle + CMake (см. `android/build.gradle`)

Привязки Dart генерируются через `ffigen`:

```bash
dart run ffigen --config ffigen.yaml* For iOS and MacOS: Xcode, via CocoaPods.
  * See the documentation in ios/shirm_crypto.podspec.
  * See the documentation in macos/shirm_crypto.podspec.
* For Linux and Windows: CMake.
  * See the documentation in linux/CMakeLists.txt.
  * See the documentation in windows/CMakeLists.txt.
```
## 📄 Основные файлы

| Файл | Описание |
|------|----------|
| `src/shirm_crypto.c` | Основная реализация на C |
| `src/shirm_crypto.h` | Публичное API (экспортируемые функции) |
| `lib/shirm_crypto.dart` | Dart-обёртка для вызова нативных функций |
| `lib/shirm_crypto_bindings_generated.dart` | Сгенерированные привязки FFI |

## 🚀 Производительность

Благодаря использованию чистого C и прямых вызовов OpenSSL скорость шифрования сопоставима с нативными утилитами, а отсутствие промежуточных слоёв (например, JSON-парсинга через C++) снижает потребление памяти.
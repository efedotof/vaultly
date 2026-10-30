# Changelog

Все значимые изменения в проекте `shirm_crypto`.
Формат — по мотивам [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/),
версионирование — [SemVer](https://semver.org/lang/ru/).

## [0.0.2] — 2026-10-30

Критический релиз: устранены уязвимости, утечки памяти и баги потоковой
обработки, из-за которых шифрование/расшифровка с `compress: true` не
работали end-to-end.

### 1 — Ошибки безопасности

#### 1.1. Ручной парсинг JSON через `strstr`

В файлах `shirm_crypto_stream.c` (`shirm_decrypt_stream_init`) и
`shirm_crypto_shps.c` (`shirm_decrypt_data`) заголовок `.shps` разбирался
через `strstr`. Любая кавычка в `originalFileName`, `keyOwner` или `userId`
ломала разбор, что открывало путь к подделке заголовка, обходу проверок и —
в связке с 1.2 — к переполнению буфера.

**Исправлено.** Добавлена вендорная копия `third_party/jsmn/jsmn.h`
(single-header, public domain). Разбор вынесен в общую функцию
`shps_parse_header()` (`internal/shirm_crypto_shps_internal.h`), используется
и в стриме, и в `shirm_decrypt_data`. Никаких `strstr` в парсинге не осталось.

#### 1.2. Переполнение буфера при сборке заголовка

`build_header()` аллоцировал `malloc(4096)` и писал через `sprintf`. Имя
файла или `userId` длиннее ~2 KB гарантированно приводили к heap overflow.
JSON не экранировался — кавычка или `\` в имени ломали заголовок.

**Исправлено.**
- Все строки проходят через `shps_json_escape()` (экранирует `"`, `\`, `\n`,
  `\r`, `\t`, `\b`, `\f`, control-символы → `\u00XX`).
- Размер считается двухпроходным `snprintf(NULL, 0, …)`, буфер аллоцируется
  точно по размеру.

#### 1.3. Утечка памяти в Dart-изолятах

В `shirm_crypto_worker.dart` каждый вызов `toNativeUtf8()` аллоцировал
C-строку без последующего `free`. При каждом encrypt/decrypt через изолят
утекало ~200–500 байт на строку.

**Исправлено.** Все `toNativeUtf8()` переведены на `Arena` (`package:ffi`),
освобождение — единым `arena.releaseAll()` в `finally`. Дополнительно:
- `*errorPtrPtr` (`strdup` из C) теперь освобождается через
  `_sendErrorAndFree()`, раньше указатель терялся.
- Per-iteration скрэтч (`outChunkPtr`, `outChunkSizePtr`) освобождается сразу
  после использования.
- `chunkPtr` (C-шный `malloc`) освобождается через `calloc.free()`.

#### 1.4. Рекурсия в потоковой расшифровке

`shirm_decrypt_stream_process()` при `updateSize == 0` (файл из одного
16-байтного GCM-тега) делал рекурсивный вызов
`return shirm_decrypt_stream_process(...)` — риск stack overflow на
специально сконструированном входе.

**Исправлено.** Рекурсия заменена на `while (1)` цикл с `continue` — тот же
сценарий теперь просто переходит на следующую итерацию.

#### 1.5. Отсутствие распаковки в стриме

Encrypt-стрим сжимал данные через `deflate(Z_SYNC_FLUSH)`, но decrypt-стрим
их не распаковывал — возвращал gzip-байты. Пользователь с `compress: true`
получал сжатый файл после «успешной» расшифровки.

**Исправлено.**
- `shirm_decrypt_stream_init()` инициализирует `inflateInit2(&zStream, 47)`
  (auto gzip/zlib) при `compressed == "true"`.
- В `shirm_decrypt_stream_process()` каждый расшифрованный чанк проходит через
  `decrypt_inflate_append()`, вывод накапливается в `outBuf` и отдаётся
  чанками.
- На FINAL-стадии выполняется `inflate(Z_FINISH)`, флаг `inflateDone`
  защищает от повторного вызова после `Z_STREAM_END`.

### 2 — Дополнительные исправления (обнаружены при имплементации)

#### 2.1. GCM-тег не устанавливался в потоковой расшифровке

`shirm_decrypt_stream_process()` пропускал последние 16 байт
(`updateSize = chunkSize - 16`), но никогда не вызывал
`EVP_CIPHER_CTX_ctrl(EVP_CTRL_GCM_SET_TAG, …)`. `EVP_DecryptFinal_ex`
сравнивал с нулевым тегом → **authentication failed** на любом стриме.

**Исправлено.** В `ShirmDecryptStream` добавлены поля `tagPtr` (указывает
на последние 16 байт входа) и `authDone`. На FINAL-стадии перед
`EVP_DecryptFinal_ex` вызывается `SET_TAG`.

#### 2.2. gzip-поток не завершался (`Z_FINISH`)

Encrypt-стрим использовал только `deflate(Z_SYNC_FLUSH)` и на EOF сразу
переходил к `EVP_EncryptFinal_ex`. Gzip-trailer (CRC32 + ISIZE) не
записывался → `inflate` на другом конце возвращал `Z_DATA_ERROR`. Без этого
фикса исправление 1.5 не работало.

**Исправлено.** На EOF вызывается `deflate(Z_FINISH)`; результат шифруется
отдельным чанком, `zFinishDone` защищает от повторного вызова.
`deflateInit2` перенесён в `shirm_encrypt_stream_init` — теперь пустой файл
с `compress=1` тоже даёт валидный gzip-поток.

#### 2.3. Отсутствие распаковки в `shirm_decrypt_data` (non-stream)

`shirm_decrypt_data()` корректно парсил `compressed` из заголовка, но не
вызывал `gzip_decompress()` — возвращал gzip-байты. Симметрично 1.5, но
для не-потокового пути.

**Исправлено.** После `aes_gcm_decrypt()` при `hdr.compressed` вызывается
`gzip_decompress()`.

#### 2.4. Конфликт linkage в `jsmn.h`

Объявления `jsmn_init` / `jsmn_parse` были extern, а определения — `static`
(`JSMN_API` определялся ниже объявлений). GCC/Clang падали с
`error: static declaration of 'jsmn_init' follows non-static declaration`.

**Исправлено.** `JSMN_API` убран полностью, везде `static` — объявления и
определения консистентны. Поле `parent` в `jsmntok_t` сделано безусловным
(без `#ifdef JSMN_PARENT_LINKS`), инициализируется в `-1` в
`jsmn_alloc_token`.

#### 2.5. `tagPtr` мог указывать за пределы буфера

`shirm_decrypt_stream_init()` присваивал
`s->tagPtr = shpsData + shpsSize - 16` без проверки, что в буфере вообще
есть место под GCM-тег. Если `shpsSize < 4 + hlen + 16` (например, обрезанный
`.shps` или сконструированный `{"a":"b"}` — `hlen = 9`, `shpsSize = 13`),
`s->tagPtr` уходил на `shpsData - 3`. При последующем
`EVP_CTRL_GCM_SET_TAG` OpenSSL читал 16 байт по этому адресу — UB /
segfault / аутентификация на мусоре.

**Исправлено.** После проверки `shpsSize >= 4 + hlen` добавлена проверка
`shpsSize >= 4 + hlen + 16`. При несоответствии —
`error = "Data too short (missing GCM tag)"`. Теперь `tagPtr` гарантированно
указывает внутрь буфера, `SET_TAG` читает только валидные байты.

#### 2.6. Underflow `chunkSize - 16` при коротком хвосте

В `shirm_decrypt_stream_process()` на последнем чанке
`updateSize = isLast ? (chunkSize - 16) : chunkSize`. Если после заголовка
оставалось 1–15 байт, `chunkSize < 16` и `chunkSize - 16` уходил в
underflow → `updateSize ≈ 18 эксабайт` → `malloc` возвращал `NULL` с
невнятной ошибкой `"malloc failed"`.

**Исправлено.** Перед вычислением `updateSize` добавлена защитная проверка
`if (isLast && chunkSize < 16)` → `error = "Data too short (truncated
ciphertext)"`. С фиксом 2.5 эта ветка уже недостижима, но оставлена как
дополнительный рубеж на случай будущих рефакторингов.

#### 2.7. Бесконечный цикл `inflate(Z_FINISH)` на усечённом gzip

В FINAL-стадии `while (!s->inflateDone)` вызывал
`inflate(&zStream, Z_FINISH)` и на `Z_BUF_ERROR` делал `continue`. Если
gzip-поток усечён (`avail_in == 0`, но `Z_STREAM_END` не наступил), zlib
возвращал `Z_BUF_ERROR` без прогресса, `produced == 0`, и цикл крутился
бесконечно.

**Исправлено.** `Z_BUF_ERROR` разбит на два случая:
- `produced == 0` → `error = "inflate finish failed (truncated stream)"`,
  выход с ошибкой.
- `produced > 0` → `continue` (нужно больше места в `outBuf`, `realloc` на
  верху итерации справится).

Также `zret != Z_OK` при `produced > 0` теперь трактуется как реальная
ошибка, а не как «нужно ещё раз».

### 3 — Совместимость

- Формат `.shps` не изменился: заголовок + шифротекст + 16-байтный GCM-тег.
- C API не изменился: все функции из `shirm_crypto.h` сохранили сигнатуры.
- Dart API не изменился: методы `ShirmCrypto.*` работают как раньше.
- Файлы, зашифрованные старой версией с `compress=true`, теперь
  **корректно расшифровываются** (раньше возвращали gzip-байты).
- Старые зашифрованные файлы, сделанные **stream-путём**, могут не
  расшифроваться — gzip-trailer в них отсутствовал (см. 2.2).
- Повреждённые/усечённые `.shps` теперь возвращают осмысленные ошибки
  (`"Data too short (missing GCM tag)"`, `"Data too short (truncated
  ciphertext)"`, `"inflate finish failed (truncated stream)"`) вместо
  segfault, `"malloc failed"` или зависания.

### 4 — Изменённые файлы

**Добавлены:**
- `third_party/jsmn/jsmn.h` — single-header JSON-парсер.
- `internal/shirm_crypto_shps_internal.h` — общий разбор заголовка `.shps`.

**Изменены:**
- `shirm_crypto_shps.c` — `shps_json_escape`, `shps_parse_header`,
  `shps_free_header`, `build_header`, `shirm_decrypt_data` (+распаковка).
- `shirm_crypto_stream.c` — `ShirmEncryptStream` (+`eofReached`, `zFinishDone`),
  `ShirmDecryptStream` (+`inflateDone`, `tagPtr`, `authDone`, `outBuf*`),
  `decrypt_inflate_append`, переписанные `*_stream_process`, защитные
  проверки в `shirm_decrypt_stream_init` / `shirm_decrypt_stream_process`
  (см. 2.5–2.7).
- `shirm_crypto_worker.dart` — Arena, `_sendErrorAndFree`, ручное
  освобождение per-iteration скрэтча.
- `CMakeLists.txt` — `${CMAKE_CURRENT_SOURCE_DIR}/third_party` в
  `target_include_directories`.

**Не изменены (API-совместимы):**
- `shirm_crypto.h`
- `shirm_crypto_utils.c`
- `shirm_crypto_cache.c`
- `shirm_crypto_bindings_generated.dart` (регенерация не нужна)
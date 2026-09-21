# Vaultly Backend - Конфиденциальность как стандарт

[![Java](https://img.shields.io/badge/Java-21-red?logo=openjdk)](https://openjdk.org)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.x-green?logo=springboot)](https://spring.io)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue?logo=postgresql)](https://www.postgresql.org)
[![MinIO](https://img.shields.io/badge/MinIO-S3--compatible-orange?logo=minio)](https://min.io)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue?logo=docker)](https://docs.docker.com/compose/)
[![License](https://img.shields.io/badge/License-Proprietary-lightgrey)](LICENSE)

Серверная часть Vaultly - облачного хранилища нового поколения со сквозным шифрованием (E2EE). Сервер спроектирован по принципу **нулевого разглашения (Zero-Knowledge)**: он никогда не видит пользовательские данные в открытом виде и не имеет ключей для их расшифровки.

> Клиентская часть (Flutter) находится в ветке [`frontend`](https://github.com/efedotof/vaultly/tree/frontend).

---

## Архитектура

| Компонент | Технологии | Назначение |
| :--- | :--- | :--- |
| **REST API** | Spring Boot 3, Spring Security | Аутентификация, управление файлами и папками, сессии, TOTP |
| **База данных** | PostgreSQL 16 | Метаданные, пользователи, права доступа, ключи устройств |
| **Хранение файлов** | S3 API (MinIO / AWS S3 / Beget Cloud) | Хранение зашифрованных `.shps` контейнеров |
| **Миграции** | Flyway | Версионирование схемы БД |
| **Криптография** | `javax.crypto`, `java.security` | Протокол SHPS, управление ключами |
| **Развёртывание** | Docker, Docker Compose | Контейнеризация всего стека одной командой |

---

## Протокол шифрования SHPS (Shirmps Protocol)

Сердце безопасности Vaultly - собственный формат файлов `.shps`, реализующий гибридное шифрование. Каждый файл, покидающий устройство клиента, упаковывается в криптографический контейнер, который сервер может лишь хранить, но не читать.

### Структура SHPS-контейнера

Файл `.shps` состоит из трёх логических частей:

1. **Заголовок (Header)** - 4 байта длины + JSON с метаданными и зашифрованным сессионным ключом.
2. **Зашифрованное тело** - данные, зашифрованные **AES-256-GCM**.
3. **Тег аутентификации** - встроен в поток GCM.

```java
// Ключевые поля заголовка (ShirmpsHeader)
private String version = "1.0";
private String algorithm = "AES-256-GCM";
private String keyEncryption = "RSA-OAEP";
private String encryptedKey;       // AES-ключ, зашифрованный RSA
private String iv;                 // Вектор инициализации для AES-GCM
private String signature;          // Цифровая подпись (SHA256withRSA)
private String keyOwner;           // "user" или "server"
private Map<String, String> metadata; // Сжатие GZIP, уровень компрессии
```

### Процесс шифрования (гибридная схема)

1. **Генерация сессионного ключа**: случайный 256-битный ключ AES.
2. **Сжатие (опционально)**: GZIP для уменьшения трафика.
3. **Шифрование данных**: `AES/GCM/NoPadding` с 12-байтным IV. GCM обеспечивает аутентификацию и целостность.
4. **Шифрование ключа**: сессионный AES-ключ зашифровывается `RSA-2048 OAEP (SHA-256)` публичным ключом получателя.
5. **Подпись**: SHA-256 от исходных данных подписывается приватным ключом отправителя.

### Режимы работы ключей

| Режим | `keyOwner` | Сценарий использования |
| :--- | :--- | :--- |
| **Приватный файл** | `"user"` | AES-ключ зашифрован публичным ключом пользователя. Только владелец может расшифровать. Сервер хранит непрозрачный блоб. |
| **Публичный доступ** | `"server"` | AES-ключ зашифрован публичным ключом сервера. Сервер расшифровывает файл для отдачи по временной ссылке. |

### Потоковая обработка

Бэкенд использует `CipherInputStream` / `CipherOutputStream` для потоковой обработки. Это позволяет работать с файлами в десятки гигабайт без загрузки в ОП.

### Модель данных и безопасность ключей

БД спроектирована так, чтобы даже при компрометации SQL-дампа злоумышленник не получил доступ к содержимому файлов.

- **`users`** - публичный ключ RSA, зашифрованный приватный ключ (защищён паролем пользователя и `salt`), `storage_used`, `storage_limit`, `totp_enabled`.
- **`devices`** - уникальный ID устройства и его публичный ключ. Приватный ключ пользователя синхронизируется между устройствами зашифрованным публичным ключом устройства.
- **`files`** - `s3_key` на `.shps`-объект, `is_public`, `is_note`, `folder_id`.
- **`temp_file_access`** - токены публичного доступа с ограничением по времени и количеству скачиваний. Пароль на ссылку хранится в виде хэша.

### Управление ключами сервера

Пара ключей сервера загружается из `.pem`-файлов, пути к которым задаются в `.env`. Используется строго `OAEPWithSHA-256AndMGF1Padding`. При старте приложение проверяет валидность пары тестовым шифрованием/дешифрованием.

```java
// ServerKeyService: загрузка ключей и проверка пары
Cipher cipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
cipher.init(Cipher.ENCRYPT_MODE, serverPublicKey);
byte[] encrypted = cipher.doFinal(testData);
cipher.init(Cipher.DECRYPT_MODE, serverPrivateKey);
byte[] decrypted = cipher.doFinal(encrypted);
```

---

## Быстрый старт

Вся инфраструктура поднимается одной командой. Docker Compose разворачивает:
- **`vaultly`** - приложение (Spring Boot)
- **`postgres`** - база данных (PostgreSQL 16)
- **`minio`** - S3-совместимое хранилище
- **`minio-init`** - одноразовый контейнер, создающий бакет и настраивающий политики доступа

### Требования

- **Docker** ≥ 24.0
- **Docker Compose** ≥ 2.20 (плагин `docker compose`, не старый `docker-compose`)
- Свободные порты: `8085`, `5432`, `9000`, `9001`

### 1. Клонирование

```bash
git clone -b backend https://github.com/efedotof/vaultly.git
cd vaultly
```

### 2. Настройка `.env`

Создайте файл `.env` в корне проекта (рядом с `docker-compose.yml`). Пример минимально необходимого:

```dotenv
# --- Приложение ---
SERVER_PORT=8085
APP_BASE_URL=http://localhost:8085
ENCRYPTION_MASTER_KEY=<base64-ключ-32-байта>

# --- База данных ---
DB_USERNAME=postgres
DB_PASSWORD=<надёжный-пароль>

# --- S3 / MinIO ---
S3_REGION=us-east-1
S3_ACCESS_KEY=<access-key>
S3_SECRET_KEY=<secret-key>
S3_BUCKET=vaultly
S3_PUBLIC_URL=http://localhost:9000/vaultly

# --- Ключи сервера (пути внутри контейнера) ---
SERVER_PRIVATE_KEY_PATH=keys/server_private.key
SERVER_PUBLIC_KEY_PATH=keys/server_public.key
```

> **Важно:** `S3_ACCESS_KEY` / `S3_SECRET_KEY` используются одновременно как root-креды MinIO и как ключи S3 для приложения. MinIO создаёт root-пользователя **один раз** при первом старте и хранит его в volume. Если поменять значения после первого `up` - приложение не сможет авторизоваться. Сброс: `docker compose down -v && docker compose up -d --build`.

> **Compose не разрешает точки в именах переменных.** Поэтому в `.env` переменная называется `APP_BASE_URL`, а не `app.base-url`. Внутри контейнера она мапится на свойство Spring через `application.properties`: `app.base-url=${APP_BASE_URL}`.

### 3. Генерация ключей сервера

Ключи должны лежать в `./keys/` - этот каталог монтируется в контейнер read-only:

```bash
mkdir -p keys
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out keys/server_private.key
openssl rsa -in keys/server_private.key -pubout -out keys/server_public.key
```

При старте приложение проверяет пару тестовым шифрованием/дешифрованием. Если ключи невалидны - контейнер упадёт с понятной ошибкой `server key pair is invalid`.

### 4. Запуск

```bash
docker compose up -d --build
```

Порядок старта:

1. `postgres` → ждёт `pg_isready`.
2. `minio` → ждёт `mc ready`.
3. `minio-init` → создаёт бакет `vaultly`, настраивает анонимный `download`, завершается.
4. `vaultly` → стартует, Flyway накатывает миграции из `classpath:db/migration`.

### 5. Проверка

```bash
# статус
docker compose ps

# логи приложения
docker compose logs -f vaultly

# health-check
curl http://localhost:8085/actuator/health
```

- **API:** http://localhost:8085
- **MinIO S3 API:** http://localhost:9000
- **MinIO Console:** http://localhost:9001 (логин/пароль = `S3_ACCESS_KEY` / `S3_SECRET_KEY`)

---

## Управление

```bash
# остановить без потери данных
docker compose down

# остановить и стереть всё (БД + файлы MinIO)
docker compose down -v

# пересобрать только приложение
docker compose up -d --build vaultly

# shell внутри контейнера
docker compose exec vaultly sh

# psql внутри контейнера БД
docker compose exec postgres psql -U postgres -d vaultly

# посмотреть итоговую конфигурацию (что реально уходит в контейнеры)
docker compose config
```

---

## Переменные окружения

Compose автоматически читает `.env` из директории проекта. Значения вида `${VAR}` в `docker-compose.yml` подставляются на этапе старта. Два значения **намеренно переопределяются** в compose, потому что `localhost` внутри контейнера - это сам контейнер:

| Переменная | В `.env` | Внутри контейнера `vaultly` | Причина |
| :--- | :--- | :--- | :--- |
| `DB_URL` | `jdbc:postgresql://localhost:5432/vaultly_test` | `jdbc:postgresql://postgres:5432/vaultly` | Хост - имя сервиса `postgres` |
| `S3_ENDPOINT` | `http://<host>:9000` | `http://minio:9000` | Хост - имя сервиса `minio` |
| `S3_PUBLIC_URL` | `http://<host>:9000/vaultly` | без изменений | Отдаётся браузеру в presigned-ссылках |

---

## Локальный запуск без Docker (для разработки в IDE)

Если нужно гонять бэкенд прямо из IDE:

1. **Поднимите только инфраструктуру:**
   ```bash
   docker compose up -d postgres minio minio-init
   ```

2. **В `.env` укажите адреса, доступные с хоста:**
   ```dotenv
   DB_URL=jdbc:postgresql://localhost:5432/vaultly
   S3_ENDPOINT=http://localhost:9000
   S3_PUBLIC_URL=http://localhost:9000/vaultly
   ```

3. **Запустите приложение:**
   ```bash
   ./mvnw spring-boot:run
   ```

4. **Остановите инфраструктуру:**
   ```bash
   docker compose down
   ```

---

## Troubleshooting

| Проблема | Решение |
| :--- | :--- |
| `pull access denied for minio/minio` | Образы MinIO переехали с Docker Hub на Quay.io. В `docker-compose.yml` должны быть `quay.io/minio/minio` и `quay.io/minio/mc`. |
| `invalid interpolation format for ${app.base-url}` | Compose не разрешает точки в именах переменных. Используйте `APP_BASE_URL`. |
| `server key pair is invalid` | Ключи в `./keys/` отсутствуют или нечитаемы. Проверьте `ls -la keys/`. |
| `Unauthorized` при обращении к MinIO | Ключи `S3_ACCESS_KEY` / `S3_SECRET_KEY` менялись после первого старта. Сброс: `docker compose down -v && docker compose up -d --build`. |
| Flyway падает на `validate-on-migrate` | Изменённые миграции после применения. Либо откатите файл, либо сбросьте БД: `docker compose down -v`. |
| Приложение не видит переменные | Проверьте: `docker compose config`. Пустое значение = переменная не найдена в `.env` (опечатка в имени). |

---

## Структура проекта

```
vaultly/
├── docker-compose.yml
├── Dockerfile
├── .env
├── .env.example
├── pom.xml
├── mvnw
├── keys/                        # ключи сервера (не коммитить!)
│   ├── server_private.key
│   └── server_public.key
├── src/main/java/com/efedotov/vaultly/
│   ├── controller/
│   ├── service/                 # бизнес-логика, SHPS, ключи
│   ├── repository/
│   ├── model/
│   ├── dto/
│   ├── security/                # SessionAuthFilter, JWT-подобная авторизация
│   └── shirmps/                 # ShirmpsHeader, SHPS-структуры
├── src/main/resources/
│   ├── application.properties
│   └── db/migration/            # Flyway-миграции
├── uploads/                     # локальное файловое хранилище
├── temp/
└── logs/
```

---

## Безопасность - что НЕ коммитить

Файл `.gitignore` должен содержать:

```
.env
keys/
logs/
uploads/
temp/
target/
```

Никогда не коммитьте:
- `ENCRYPTION_MASTER_KEY` и любые ключи из `.env`.
- Приватные ключи сервера (`keys/server_private.key`).
- Реальные пароли БД и S3-креды.

---
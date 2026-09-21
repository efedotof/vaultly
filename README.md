# Vaultly Backend - конфиденциальность как стандарт

> **Это бета-версия.** Основная ветка backend: [backend](https://github.com/efedotof/vaultly/tree/backend).  
> Клиентская часть (Flutter): [frontend](https://github.com/efedotof/vaultly/tree/frontend).

Серверная часть Vaultly - облачного хранилища со сквозным шифрованием (E2EE). Сервер работает по принципу **Zero-Knowledge**: он не видит пользовательские данные в открытом виде и не имеет ключей для их расшифровки.

## Архитектура

| Компонент | Технологии | Назначение |
| :--- | :--- | :--- |
| REST API | Spring Boot 3, Spring Security | Аутентификация, файлы, папки, сессии, TOTP |
| База данных | PostgreSQL 16 | Метаданные, пользователи, права, ключи устройств |
| Хранение файлов | S3 API (MinIO / AWS S3 / Beget Cloud) | Зашифрованные `.shps`-контейнеры |
| Миграции | Flyway | Версионирование схемы БД |
| Криптография | `javax.crypto`, `java.security` | Протокол SHPS, управление ключами |
| Развёртывание | Docker, Docker Compose | Контейнеризация стека |

## Протокол SHPS

Формат `.shps` реализует гибридное шифрование. Сервер хранит контейнер, но не может прочитать его содержимое.

Структура `.shps`:

1. **Header** - 4 байта длины + JSON с метаданными и зашифрованным сессионным ключом.
2. **Зашифрованное тело** - данные после AES-256-GCM.
3. **Тег аутентификации** - встроен в GCM.

Ключевые поля заголовка:

- `version`
- `algorithm`
- `keyEncryption`
- `encryptedKey`
- `iv`
- `signature`
- `keyOwner`
- `metadata`

Процесс шифрования:

1. Генерация случайного 256-битного AES-ключа.
2. Опциональное GZIP-сжатие.
3. Шифрование данных `AES/GCM/NoPadding` с 12-байтным IV.
4. Шифрование AES-ключа через `RSA-2048 OAEP (SHA-256)`.
5. Подпись SHA-256 приватным ключом отправителя.

Режимы ключей:

| Режим | `keyOwner` | Сценарий |
| :--- | :--- | :--- |
| Приватный файл | `"user"` | Расшифровать может только владелец |
| Публичный доступ | `"server"` | Сервер отдаёт файл по временной ссылке |

Для больших файлов используется потоковая обработка через `CipherInputStream` / `CipherOutputStream`.

## Модель данных и ключи

- `users` - публичный RSA-ключ, зашифрованный приватный ключ, `storage_used`, `storage_limit`, `totp_enabled`.
- `devices` - ID устройства и публичный ключ.
- `files` - `s3_key`, `is_public`, `is_note`, `folder_id`.
- `temp_file_access` - токены публичного доступа с ограничением по времени и скачиваниям.

Ключи сервера загружаются из `.pem`-файлов, пути задаются в `.env`. Используется `OAEPWithSHA-256AndMGF1Padding`. При старте ключевая пара проверяется тестовым шифрованием/дешифрованием.

## Быстрый старт
Клонирование:

```bash
git clone -b backend https://github.com/efedotof/vaultly.git
cd vaultly
```

Создайте `.env`:

```dotenv
SERVER_PORT=8085
APP_BASE_URL=http://localhost:8085
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
ENCRYPTION_MASTER_KEY=<base64-ключ-32-байта>

DB_USERNAME=postgres
DB_PASSWORD=<надёжный-пароль>

S3_REGION=us-east-1
S3_ACCESS_KEY=<access-key>
S3_SECRET_KEY=<secret-key>
S3_BUCKET=vaultly
S3_PUBLIC_URL=http://localhost:9000/vaultly

SERVER_PRIVATE_KEY_PATH=keys/server_private.key
SERVER_PUBLIC_KEY_PATH=keys/server_public.key

LOG_LEVEL_VAULTLY=INFO
LOG_LEVEL_SPRING_WEB=INFO
LOG_LEVEL_SPRING_SEC=INFO
LOG_LEVEL_HIKARI=INFO

TRUST_FORWARDED_HEADERS=false
```

> `S3_ACCESS_KEY` / `S3_SECRET_KEY` создаются MinIO один раз при первом старте. После смены значений нужен сброс: `docker compose down -v && docker compose up -d --build`.

Генерация ключей сервера:

```bash
mkdir -p keys
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out keys/server_private.key
openssl rsa -in keys/server_private.key -pubout -out keys/server_public.key
```

Запуск:

```bash
docker compose up -d --build
```

Проверка:

```bash
docker compose ps
docker compose logs -f vaultly
curl http://localhost:8085/actuator/health
```

Доступы:

- API: http://localhost:8085
- MinIO S3 API: http://localhost:9000
- MinIO Console: http://localhost:9001

## Управление

```bash
docker compose down
docker compose down -v
docker compose up -d --build vaultly
docker compose exec vaultly sh
docker compose exec postgres psql -U postgres -d vaultly
docker compose config
```

## Переменные окружения

Compose читает `.env` из корня проекта. Внутри контейнера `localhost` указывает на сам контейнер, поэтому часть адресов переопределяется:

| Переменная | В `.env` | В контейнере `vaultly` |
| :--- | :--- | :--- |
| `DB_URL` | `jdbc:postgresql://localhost:5432/vaultly_test` | `jdbc:postgresql://postgres:5432/vaultly` |
| `S3_ENDPOINT` | `http://<host>:9000` | `http://minio:9000` |
| `S3_PUBLIC_URL` | `http://<host>:9000/vaultly` | без изменений |

## Локальный запуск без Docker

```bash
docker compose up -d postgres minio minio-init
```

В `.env`:

```dotenv
DB_URL=jdbc:postgresql://localhost:5432/vaultly
S3_ENDPOINT=http://localhost:9000
S3_PUBLIC_URL=http://localhost:9000/vaultly
```

Запуск:

```bash
./mvnw spring-boot:run
```

Остановка инфраструктуры:

```bash
docker compose down
```

## Troubleshooting

| Проблема | Решение |
| :--- | :--- |
| `pull access denied for minio/minio` | Использовать `quay.io/minio/minio` и `quay.io/minio/mc`. |
| `invalid interpolation format for ${app.base-url}` | Compose не разрешает точки в именах переменных. Используйте `APP_BASE_URL`. |
| `server key pair is invalid` | Проверить `ls -la keys/`. |
| `Unauthorized` при обращении к MinIO | Сбросить: `docker compose down -v && docker compose up -d --build`. |
| Flyway падает на `validate-on-migrate` | Откатить миграцию или сбросить БД: `docker compose down -v`. |
| Приложение не видит переменные | Проверить `docker compose config`. |

## Структура проекта

```text
vaultly/
├── docker-compose.yml
├── Dockerfile
├── .env
├── .env.example
├── pom.xml
├── mvnw
├── keys/
│   ├── server_private.key
│   └── server_public.key
├── src/main/java/com/efedotov/vaultly/
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── model/
│   ├── dto/
│   ├── security/
│   └── shirmps/
├── src/main/resources/
│   ├── application.properties
│   └── db/migration/
├── uploads/
├── temp/
└── logs/
```

## Безопасность - что не коммитить

`.gitignore` должен содержать:

```text
.env
keys/
logs/
uploads/
temp/
target/
```

Никогда не коммитьте:

- `ENCRYPTION_MASTER_KEY` и любые ключи из `.env`;
- приватные ключи сервера (`keys/server_private.key`);
- реальные пароли БД и S3-креды.

## Изменения

1. Исправлена ошибка восстановления доступа через `/api/auth/recover`, теперь требуется подпись challenge.
2. Исправлена ошибка добавления файла в чужую папку, теперь проверяется владелец файла.
3. Исправлена ошибка удаления чужих файлов через `deleteFolderRecursive`, теперь учитываются общие ссылки S3.
4. Исправлена ошибка загрузки файла в чужую папку через `createFileLink`, теперь проверяется владелец папки.
5. Исправлена ошибка временных ссылок, пароль проверяется до инкремента скачиваний.
6. Исправлена ошибка логирования токена сессии в `deleteSession`, токен больше не пишется в логи.
7. Исправлена ошибка хранения пароля временной ссылки, теперь используется BCrypt или Argon2.
8. Исправлена ошибка `GlobalExceptionHandler`, внутренние сообщения не уходят наружу, `SecurityException` даёт 403.
9. Исправлена ошибка CORS, теперь используется whitelist origins.
10. Исправлена ошибка доступа к профилю через `GET /api/users/{id}`, эндпоинт закрыт или ограничен.
11. Исправлена ошибка `shareFolder`, теперь проверяется право шаринга у пользователя.
12. Исправлена ошибка паролей папок, теперь используется `PasswordEncoder`.
13. Исправлена ошибка сравнения паролей, теперь сравнение constant-time.
14. Исправлена ошибка `ShpsSecurityService`, запуск java с путём к ключу убран.
15. Исправлена ошибка хранения токенов сессий, теперь хранится SHA-256.
16. Исправлена ошибка login, теперь единое сообщение `Invalid credentials`.
17. Исправлена ошибка login, `loginFailed` вызывается и для несуществующих пользователей.
18. Исправлена ошибка валидации, `@Valid` добавлен на `register`, `login` и `updateKeys`.
19. Исправлена ошибка политики пароля, требования к сложности усилены.
20. Исправлена ошибка DEBUG логов в проде, уровень убран или разнесён по профилям.
21. Исправлена ошибка анонимного чтения S3, для приватных файлов теперь presigned-only.
22. Исправлена ошибка `LoginAttemptService`, добавлена эвикция и поддержка кластера.
23. Исправлена ошибка учёта storage, Java и DB-триггер синхронизированы.
24. Исправлена ошибка метаданных S3, `originalFilename` теперь URL-энкодится.
25. Исправлена ошибка `EntryPoint` и `AccessDeniedHandler`, теперь возвращаются 401 и 403 с JSON.
26. Исправлена ошибка Jackson, default typing явно отключён.
27. Исправлена ошибка `UserKeyService`, dead code с приватными ключами удалён.
28. Исправлена ошибка `getFolderTree`, добавлена `@Transactional(readOnly = true)`.
29. Исправлена ошибка `updateKeys` и `updateRecoveryKeys`, формат ключа валидируется.
30. Исправлена ошибка кэша `UserKeyService`, кэш сбрасывается после `updateKeys`.
31. Исправлена ошибка `setFilePublic`, теперь проверяется или обновляется `FileContent.isPublic`.
32. Исправлена ошибка `DeviceService.getEncryptedPrivateKey`, `readOnly` убран.
33. Исправлена ошибка BCrypt, strength увеличен до 12.
34. Исправлена ошибка XFF, теперь доверяем только прокси или берём последний IP.
35. Исправлена ошибка `ipSucceeded`, IP-лимит больше не сбрасывается по успеху.
36. Исправлена ошибка `streamDecryptedFile`, слот `maxDownloads` резервируется атомарно до стрима.
37. Исправлена ошибка `TotpRequiredException`, ответ стал нейтральным или используется pre-auth.
38. Исправлена ошибка `RecoveryChallengeService`, challenge привязан к `publicKeyHash`.
39. Исправлена ошибка пароля папки, добавлен rate-limit.
40. Исправлена ошибка `loginWithTotp`, `isActive` проверяется до TOTP.
41. Исправлена ошибка `shareFolder`, добавлена защита от null `userIds`.
42. Исправлена ошибка `createFolder`, `isPrivate` убран или реализован.
43. Исправлена ошибка `getFolderTree`, скрытые папки фильтруются.
44. Исправлена ошибка схемы, для `folders.parent_folder_id` добавлен FK.
45. Исправлена ошибка `DotenvConfig`, `.env` больше не грузится дважды.
46. Исправлена ошибка `updateNoteContent`, перезапись S3 по тому же ключу убрана.
47. Исправлена ошибка `ShirmpsProtocol`, мёртвый класс удалён.
48. Исправлена ошибка `parseJsonStringArray`, теперь используется Jackson.
49. Исправлена ошибка `extractHeader`, поток закрывается через try-with-resources.
50. Исправлена ошибка `uploadShpsFile`, добавлена проверка null filename.
51. Исправлена ошибка `uploadFileWithMultipart`, метод сделан private.
52. Исправлена ошибка `getDecryptionMetadataForTempAccess`, token и file валидируются.
53. Исправлена ошибка `BadPaddingException`, обработка улучшена.
54. Исправлена ошибка Jackson 2 и 3, зависимости приведены к одному варианту.
55. Исправлена ошибка `updateNoteContent`, добавлена оптимистичная блокировка `@Version`.
56. Исправлена ошибка S3 `getObjectKeyFromUrl`, ключ определяется корректно.
57. Исправлена ошибка `folder_passwords.algorithm`, значение используется или убрано.
58. Исправлена ошибка `ShirmpsHeader`, `ObjectMapper` создаётся один раз.
59. Исправлена ошибка `EncryptionService`, используется `StandardCharsets.UTF_8`.
60. Исправлена ошибка `ShpsSecurityService`, проверка подписи server-encrypted исправлена.
61. Исправлена ошибка `AuthService.normalizePublicKey`, формат ключа согласован.
62. Исправлена ошибка `createTempLink`, `baseUrl` проверяется.
63. Исправлена ошибка `TempAccessController`, null principal даёт 401.
64. Исправлена ошибка `TotpService`, BCrypt для backup codes приведён к 12.
65. Исправлена ошибка `EncryptionService.decrypt`, сообщение об ошибке сохраняется.
66. Исправлена ошибка `FileService.createNote`, дублирование `addFileToFolder` убрано.
67. Исправлена ошибка dedup leak при чтении чужих файлов через `contentHash`: `checkDuplicate` не возвращает UUID, `linkExistingFile` проверяет владельца, `uploadShpsFile` делает dedup только для своих файлов.
68. Исправлена ошибка отсутствия `/api/auth/login/totp` в `permitAll`, теперь 2FA работает.
69. Исправлена ошибка отсутствия rate-limit на `/api/auth/register`, теперь используется IP-лимит.
70. Исправлена ошибка отсутствия rate-limit на `/temp-access/{token}/metadata`, теперь учитываются неверные пароли.
71. Исправлена ошибка фиктивного BCrypt-хэша, теперь используется реальный хэш для выравнивания времени.
72. Исправлена ошибка `CustomUserDetails.isEnabled`, теперь возвращается реальный статус `isActive`.
73. Исправлена ошибка каскадного удаления `User`, `Folder` и `File`, каскад ограничен или убран.
74. Исправлена ошибка каскада `Folder.files` и `Folder.subfolders`, `orphanRemoval` убран, cascade ограничен.
75. Исправлена ошибка `checkFolderAccess`, теперь проверяется `isDeleted`.
76. Исправлена ошибка `checkHiddenFolderKey` без rate-limit, теперь используется лимит попыток.
77. Исправлена ошибка размера страницы без ограничения, теперь `size` не больше 100.
78. Исправлена ошибка S3-orphans при rollback, теперь S3 удаляется при ошибке или используется outbox.
79. Исправлена ошибка `getDecryptionMetadata` с `BadPadding` и дублированием, теперь вызывается `FileService`.
80. Исправлена ошибка `ServerKeyService.loadKeys`, теперь при отсутствии ключа бросается исключение.
81. Исправлена ошибка `moveFiles`, теперь проверяется владелец файла.
82. Исправлена ошибка DTO без ограничений длины, добавлены `Size` и `Pattern`.
83. Исправлена ошибка `RegisterRequest.password`, ограничение приведено к 64 для BCrypt.
84. Исправлена ошибка `contentHash` без валидации, теперь проверяется формат SHA-256.
85. Исправлена ошибка race на дубликат имени папки, добавлен partial unique index.
86. Исправлена ошибка `S3Service.deleteFile`, теперь null `objectKey` обрабатывается.
87. Исправлена ошибка `SessionAuthFilter`, теперь удалённый пользователь не даёт 500.
88. Исправлена ошибка `createNote` и `updateNoteContent`, теперь null filename проверяется.
89. Исправлена ошибка `getDecryptionMetadataForUser`, добавлена `Transactional readOnly`.
90. Исправлена ошибка `FileRepository.findByIdAndUserId`, добавлен `JOIN FETCH`.
91. Исправлена ошибка отсутствия обработчика `OptimisticLockingFailureException`, теперь 409.
92. Исправлена ошибка `File.version` без `Builder.Default`, теперь значение по умолчанию 0.
93. Исправлена ошибка утечки памяти `PreAuthTokenService` и `RecoveryChallengeService`, добавлен `Scheduled`.
94. Исправлена ошибка soft-delete папки, теперь S3 чистится с учётом ссылок.
95. Исправлена ошибка неиспользуемых `S3AsyncClient` и `S3TransferManager`, бины удалены.
96. Исправлена ошибка `RegisterRequest.username` без `Pattern`, добавлен шаблон.
97. Исправлена ошибка `setupTotp`, `plainSecret` убран из JSON.
98. Исправлена ошибка `hasActivePassword`, теперь проверяется доступ к папке.
99. Исправлена ошибка `FileContent.file_content_id` без индекса, индекс добавлен.
100. Исправлена ошибка `getFolderFiles` без пагинации, добавлена пагинация.
101. Исправлена ошибка `AccessLevel.ordinal`, теперь явные веса.
102. Исправлена ошибка N+1 при `checkFolderAccess`, теперь пользователь передаётся или кэшируется.
103. Исправлена ошибка мёртвого кода, неиспользуемые классы и методы удалены.
104. Исправлена ошибка legacy ключа `javax.persistence.validation.mode`, заменён на `jakarta`.
105. Исправлена ошибка `AuthResponse.refreshToken`, поле убрано или реализовано.
106. Исправлена ошибка `FolderAccess.expiresAt`, теперь устанавливается или убрано.
107. Исправлена ошибка log injection через username, добавлен санитайз.
108. Исправлена ошибка `EncryptionService.decrypt`, сообщение `IllegalArgumentException` сохраняется.
109. Исправлена ошибка `EncryptionService.encrypt`, убран устаревший catch.
110. Исправлена ошибка `updateNoteContent`, S3-orphan теперь обрабатывается строже.
111. Исправлена ошибка `server.error.include`, теперь явно заданы `never`.
112. Исправлена ошибка `TotpService.backupCodeEncoder`, strength приведён к 12.
113. Исправлена ошибка `getFolderTree`, теперь защита от цикла.
114. Исправлена ошибка `extractHeader`, теперь вызывается `validateHeader`.
115. Исправлена ошибка `uploadShpsFile`, теперь проверяется GCM-целостность.
116. Исправлена ошибка `FileDto.s3Url`, поле убрано или документировано.
117. Исправлена ошибка email при регистрации, теперь заполняется или поле убрано.
118. Исправлена ошибка V1 и V3 с V4, миграции проверены на orphan-данные.
119. Исправлена ошибка `validatePublicKeyFormat`, ReDoS снижен.
120. Исправлена ошибка `AuthController.login`, username больше не логируется на INFO.
121. Исправлена ошибка `S3Config` с пустыми ключами, теперь приложение не стартует.
122. Исправлена ошибка `TotpService.verifyBackupCode`, стоимость BCrypt снижена или ограничена.
123. Исправлена ошибка `SessionAuthFilter`, INFO-логи убраны.
124. Исправлена ошибка `getFolderFiles`, добавлена сортировка.
125. Исправлена ошибка `checkFolderPassword`, теперь различаются неверный пароль и блокировка.
126. Исправлена ошибка `FolderAccess.expiresAt`, `deactivateExpiredAccesses` теперь вызывается.
127. Исправлена ошибка `moveFiles`, противоречие с `addFileToFolder` устранено.
128. Исправлена ошибка `LoginAttemptService.ipSucceeded`, метод удалён или вызывается.
129. Исправлена ошибка `FolderCreateDto.description`, добавлено ограничение длины.
130. Исправлена ошибка `loginWithTotp`, теперь вызывается `ipFailed`.
#include "shirm_crypto.h"
#include "internal/shirm_crypto_common.h"
#include "internal/shirm_crypto_cache_internal.h"
#include <dirent.h>
#include <sys/stat.h>
#include <sqlite3.h>
#include <errno.h>

void generate_key_nonce(unsigned char *key, unsigned char *nonce)
{
    RAND_bytes(key, 32);
    RAND_bytes(nonce, 12);
}

void create_directory(const char *path)
{
#ifdef _WIN32
    _mkdir(path);
#else
    mkdir(path, 0755);
#endif
}

void *shirm_cache_init(const char *cacheDir, char **error)
{
    ShirmCache *cache = (ShirmCache *)calloc(1, sizeof(ShirmCache));
    if (!cache)
    {
        if (error)
            *error = strdup("Memory allocation failed");
        return NULL;
    }
    cache->cache_dir = strdup(cacheDir);
    create_directory(cacheDir);

    char db_path[2048];
    snprintf(db_path, sizeof(db_path), "%s/cache_metadata.db", cacheDir);
    if (sqlite3_open(db_path, &cache->db) != SQLITE_OK)
    {
        if (error)
            *error = strdup(sqlite3_errmsg(cache->db));
        free(cache->cache_dir);
        free(cache);
        return NULL;
    }
    sqlite3_exec(cache->db, "PRAGMA synchronous = FULL", NULL, NULL, NULL);
    sqlite3_exec(cache->db, "PRAGMA journal_mode = WAL", NULL, NULL, NULL);

    const char *create_sql =
        "CREATE TABLE IF NOT EXISTS cache_metadata ("
        "id TEXT PRIMARY KEY,"
        "original_name TEXT,"
        "timestamp INTEGER,"
        "key BLOB,"
        "nonce BLOB"
        ");";
    char *errmsg = NULL;
    if (sqlite3_exec(cache->db, create_sql, NULL, NULL, &errmsg) != SQLITE_OK)
    {
        if (error)
            *error = errmsg;
        sqlite3_close(cache->db);
        free(cache->cache_dir);
        free(cache);
        return NULL;
    }
    return cache;
}

int shirm_cache_save(void *cache, const char *fileId,
                     const uint8_t *data, size_t dataSize,
                     const char *originalName, char **error)
{
    ShirmCache *c = (ShirmCache *)cache;
    unsigned char key[32], nonce[12];
    generate_key_nonce(key, nonce);

    size_t encrypted_len = 0;
    unsigned char *encrypted = aes_gcm_encrypt_simple(data, dataSize, key, nonce, &encrypted_len);
    if (!encrypted)
    {
        if (error)
            *error = strdup("Encryption failed");
        return 0;
    }

    char file_path[2048];
    snprintf(file_path, sizeof(file_path), "%s/%s.enc", c->cache_dir, fileId);
    FILE *f = fopen(file_path, "wb");
    if (!f)
    {
        free(encrypted);
        if (error)
            *error = strdup("Cannot create cache file");
        return 0;
    }
    size_t written = fwrite(encrypted, 1, encrypted_len, f);
    fflush(f);
#ifdef _WIN32
    _commit(fileno(f));
#else
    fsync(fileno(f));
#endif
    fclose(f);
    if (written != encrypted_len)
    {
        free(encrypted);
        if (error)
            *error = strdup("Failed to write complete cache file");
        return 0;
    }
    free(encrypted);

    sqlite3_stmt *stmt;
    const char *insert_sql = "INSERT OR REPLACE INTO cache_metadata (id, original_name, timestamp, key, nonce) VALUES (?, ?, ?, ?, ?)";
    if (sqlite3_prepare_v2(c->db, insert_sql, -1, &stmt, NULL) != SQLITE_OK)
    {
        if (error)
            *error = strdup(sqlite3_errmsg(c->db));
        return 0;
    }
    sqlite3_bind_text(stmt, 1, fileId, -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 2, originalName, -1, SQLITE_STATIC);
    sqlite3_bind_int64(stmt, 3, (sqlite3_int64)time(NULL));
    sqlite3_bind_blob(stmt, 4, key, 32, SQLITE_STATIC);
    sqlite3_bind_blob(stmt, 5, nonce, 12, SQLITE_STATIC);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    if (rc != SQLITE_DONE)
    {
        if (error)
            *error = strdup(sqlite3_errmsg(c->db));
        return 0;
    }

    return 1;
}

uint8_t *shirm_cache_load(void *cache, const char *fileId, size_t *outSize, char **error)
{
    ShirmCache *c = (ShirmCache *)cache;

    sqlite3_stmt *stmt;
    const char *select_sql = "SELECT key, nonce FROM cache_metadata WHERE id = ?";
    if (sqlite3_prepare_v2(c->db, select_sql, -1, &stmt, NULL) != SQLITE_OK)
    {
        if (error)
            *error = strdup(sqlite3_errmsg(c->db));
        return NULL;
    }
    sqlite3_bind_text(stmt, 1, fileId, -1, SQLITE_STATIC);
    if (sqlite3_step(stmt) != SQLITE_ROW)
    {
        sqlite3_finalize(stmt);
        if (error)
            *error = strdup("File not found in cache");
        return NULL;
    }

    unsigned char key[32], nonce[12];
    const unsigned char *key_blob = sqlite3_column_blob(stmt, 0);
    const unsigned char *nonce_blob = sqlite3_column_blob(stmt, 1);
    size_t key_len = sqlite3_column_bytes(stmt, 0);
    size_t nonce_len = sqlite3_column_bytes(stmt, 1);
    if (key_len != 32 || nonce_len != 12)
    {
        sqlite3_finalize(stmt);
        if (error)
            *error = strdup("Invalid key/nonce in metadata");
        return NULL;
    }
    memcpy(key, key_blob, 32);
    memcpy(nonce, nonce_blob, 12);
    sqlite3_finalize(stmt);

    char file_path[2048];
    snprintf(file_path, sizeof(file_path), "%s/%s.enc", c->cache_dir, fileId);
    FILE *f = fopen(file_path, "rb");
    if (!f)
    {
        if (error)
            *error = strdup("Cache file missing");
        return NULL;
    }
    fseek(f, 0, SEEK_END);
    long encrypted_len = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (encrypted_len < 16)
    {
        fclose(f);
        if (error)
            *error = strdup("Encrypted file too small");
        return NULL;
    }
    unsigned char *encrypted = (unsigned char *)malloc(encrypted_len);
    if (!encrypted)
    {
        fclose(f);
        if (error)
            *error = strdup("malloc failed");
        return NULL;
    }
    size_t read_bytes = fread(encrypted, 1, encrypted_len, f);
    fclose(f);
    if (read_bytes != (size_t)encrypted_len)
    {
        free(encrypted);
        if (error)
            *error = strdup("Failed to read full encrypted file");
        return NULL;
    }

    size_t plain_len = 0;
    unsigned char *plain = aes_gcm_decrypt_simple(encrypted, encrypted_len, key, nonce, &plain_len);
    free(encrypted);
    if (!plain)
    {
        if (error)
            *error = strdup("Decryption failed");
        return NULL;
    }
    *outSize = plain_len;
    return plain;
}

int shirm_cache_has(void *cache, const char *fileId)
{
    ShirmCache *c = (ShirmCache *)cache;
    sqlite3_stmt *stmt;
    const char *sql = "SELECT 1 FROM cache_metadata WHERE id = ?";
    if (sqlite3_prepare_v2(c->db, sql, -1, &stmt, NULL) != SQLITE_OK)
        return 0;
    sqlite3_bind_text(stmt, 1, fileId, -1, SQLITE_STATIC);
    int exists = (sqlite3_step(stmt) == SQLITE_ROW);
    sqlite3_finalize(stmt);
    return exists;
}

int shirm_cache_delete(void *cache, const char *fileId, char **error)
{
    ShirmCache *c = (ShirmCache *)cache;
    char file_path[2048];
    snprintf(file_path, sizeof(file_path), "%s/%s.enc", c->cache_dir, fileId);
    remove(file_path);

    sqlite3_stmt *stmt;
    const char *sql = "DELETE FROM cache_metadata WHERE id = ?";
    if (sqlite3_prepare_v2(c->db, sql, -1, &stmt, NULL) != SQLITE_OK)
    {
        if (error)
            *error = strdup(sqlite3_errmsg(c->db));
        return 0;
    }
    sqlite3_bind_text(stmt, 1, fileId, -1, SQLITE_STATIC);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return (rc == SQLITE_DONE);
}

int shirm_cache_clear(void *cache, char **error)
{
    ShirmCache *c = (ShirmCache *)cache;
#ifdef _WIN32
    WIN32_FIND_DATA findData;
    HANDLE hFind;
    char searchPath[4096];
    snprintf(searchPath, sizeof(searchPath), "%s*.enc", c->cache_dir);
    hFind = FindFirstFile(searchPath, &findData);
    if (hFind != INVALID_HANDLE_VALUE)
    {
        do
        {
            char fullPath[4096];
            snprintf(fullPath, sizeof(fullPath), "%s%s", c->cache_dir, findData.cFileName);
            remove(fullPath);
        } while (FindNextFile(hFind, &findData));
        FindClose(hFind);
    }
#else
    DIR *dir = opendir(c->cache_dir);
    if (dir)
    {
        struct dirent *entry;
        while ((entry = readdir(dir)) != NULL)
        {
            if (strstr(entry->d_name, ".enc") != NULL)
            {
                char fullPath[4096];
                snprintf(fullPath, sizeof(fullPath), "%s/%s", c->cache_dir, entry->d_name);
                remove(fullPath);
            }
        }
        closedir(dir);
    }
#endif
    char *errmsg = NULL;
    if (sqlite3_exec(c->db, "DELETE FROM cache_metadata", NULL, NULL, &errmsg) != SQLITE_OK)
    {
        if (error)
            *error = errmsg;
        return 0;
    }
    return 1;
}

char *shirm_cache_get_all_metadata(void *cache, char **error)
{
    ShirmCache *c = (ShirmCache *)cache;
    sqlite3_stmt *stmt;
    const char *sql = "SELECT id, original_name, timestamp FROM cache_metadata";
    if (sqlite3_prepare_v2(c->db, sql, -1, &stmt, NULL) != SQLITE_OK)
    {
        if (error)
            *error = strdup(sqlite3_errmsg(c->db));
        return NULL;
    }
    char *json = malloc(1024);
    strcpy(json, "{\"files\":[");
    int first = 1;
    while (sqlite3_step(stmt) == SQLITE_ROW)
    {
        const char *id = (const char *)sqlite3_column_text(stmt, 0);
        const char *name = (const char *)sqlite3_column_text(stmt, 1);
        int64_t ts = sqlite3_column_int64(stmt, 2);
        char entry[512];
        snprintf(entry, sizeof(entry), "%s{\"id\":\"%s\",\"originalName\":\"%s\",\"timestamp\":%lld}",
                 first ? "" : ",", id, name ? name : "", (long long)ts);
        first = 0;
        json = realloc(json, strlen(json) + strlen(entry) + 1);
        strcat(json, entry);
    }
    sqlite3_finalize(stmt);
    json = realloc(json, strlen(json) + 20);
    strcat(json, "]}");
    return json;
}

void shirm_free(void *ptr)
{
    if (ptr)
        free(ptr);
}

void shirm_cache_close(void *cache)
{
    if (cache)
    {
        ShirmCache *c = (ShirmCache *)cache;
        if (c->db)
        {
            sqlite3_exec(c->db, "PRAGMA wal_checkpoint(TRUNCATE)", NULL, NULL, NULL);
            sqlite3_close(c->db);
        }
        if (c->cache_dir)
            free(c->cache_dir);
        free(c);
    }
}

struct ShirmCacheSaveStream
{
    ShirmCache *cache;
    char fileId[256];
    char originalName[256];
    FILE *tempFile;
    EVP_CIPHER_CTX *cipherCtx;
    unsigned char key[32];
    unsigned char nonce[12];
    int finished;
    char tempFilePath[2048];
};

ShirmCacheSaveStream *shirm_cache_save_stream_init(void *cache, const char *fileId,
                                                   const char *originalName, char **error)
{
    ShirmCache *c = (ShirmCache *)cache;
    ShirmCacheSaveStream *stream = (ShirmCacheSaveStream *)calloc(1, sizeof(ShirmCacheSaveStream));
    if (!stream)
    {
        if (error)
            *error = strdup("Memory allocation failed");
        return NULL;
    }
    stream->cache = c;
    strncpy(stream->fileId, fileId, sizeof(stream->fileId) - 1);
    if (originalName)
        strncpy(stream->originalName, originalName, sizeof(stream->originalName) - 1);

    generate_key_nonce(stream->key, stream->nonce);

    snprintf(stream->tempFilePath, sizeof(stream->tempFilePath), "%s/tmp_%s.enc", c->cache_dir, fileId);
    stream->tempFile = fopen(stream->tempFilePath, "wb");
    if (!stream->tempFile)
    {
        free(stream);
        if (error)
            *error = strdup("Cannot create temporary cache file");
        return NULL;
    }

    stream->cipherCtx = EVP_CIPHER_CTX_new();
    if (!stream->cipherCtx)
    {
        fclose(stream->tempFile);
        free(stream);
        if (error)
            *error = strdup("EVP_CIPHER_CTX_new failed");
        return NULL;
    }
    if (EVP_EncryptInit_ex(stream->cipherCtx, EVP_aes_256_gcm(), NULL,
                           stream->key, stream->nonce) != 1)
    {
        EVP_CIPHER_CTX_free(stream->cipherCtx);
        fclose(stream->tempFile);
        free(stream);
        if (error)
            *error = strdup("EVP_EncryptInit_ex failed");
        return NULL;
    }
    stream->finished = 0;
    return stream;
}

int shirm_cache_save_stream_write(ShirmCacheSaveStream *stream,
                                  const uint8_t *chunk, size_t chunkSize, char **error)
{
    if (!stream || stream->finished)
        return 0;
    if (chunkSize == 0)
        return 1;

    unsigned char *encBuf = (unsigned char *)malloc(chunkSize + EVP_MAX_BLOCK_LENGTH);
    if (!encBuf)
    {
        if (error)
            *error = strdup("Encryption buffer allocation failed");
        return -1;
    }
    int encLen = 0;
    if (EVP_EncryptUpdate(stream->cipherCtx, encBuf, &encLen, chunk, (int)chunkSize) != 1)
    {
        free(encBuf);
        if (error)
            *error = strdup("EVP_EncryptUpdate failed");
        return -1;
    }
    fwrite(encBuf, 1, encLen, stream->tempFile);
    free(encBuf);
    return 1;
}

int shirm_cache_save_stream_finish(ShirmCacheSaveStream *stream, char **error)
{
    if (!stream || stream->finished)
        return 0;
    unsigned char finalBuf[EVP_MAX_BLOCK_LENGTH];
    int finalLen = 0;
    if (EVP_EncryptFinal_ex(stream->cipherCtx, finalBuf, &finalLen) != 1)
    {
        if (error)
            *error = strdup("EVP_EncryptFinal_ex failed");
        return -1;
    }
    fwrite(finalBuf, 1, finalLen, stream->tempFile);
    unsigned char tag[16];
    if (EVP_CIPHER_CTX_ctrl(stream->cipherCtx, EVP_CTRL_GCM_GET_TAG, 16, tag) != 1)
    {
        if (error)
            *error = strdup("Failed to get GCM tag");
        return -1;
    }
    fwrite(tag, 1, 16, stream->tempFile);
    fflush(stream->tempFile);
#ifdef _WIN32
    _commit(fileno(stream->tempFile));
#else
    fsync(fileno(stream->tempFile));
#endif
    fclose(stream->tempFile);
    stream->tempFile = NULL;

    char finalPath[2048];
    snprintf(finalPath, sizeof(finalPath), "%s/%s.enc", stream->cache->cache_dir, stream->fileId);
    if (rename(stream->tempFilePath, finalPath) != 0)
    {
        if (error)
            *error = strdup("Failed to rename cache file");
        return -1;
    }

    sqlite3_stmt *stmt;
    const char *insert_sql = "INSERT OR REPLACE INTO cache_metadata (id, original_name, timestamp, key, nonce) VALUES (?, ?, ?, ?, ?)";
    if (sqlite3_prepare_v2(stream->cache->db, insert_sql, -1, &stmt, NULL) != SQLITE_OK)
    {
        if (error)
            *error = strdup(sqlite3_errmsg(stream->cache->db));
        return -1;
    }
    sqlite3_bind_text(stmt, 1, stream->fileId, -1, SQLITE_STATIC);
    sqlite3_bind_text(stmt, 2, stream->originalName, -1, SQLITE_STATIC);
    sqlite3_bind_int64(stmt, 3, (sqlite3_int64)time(NULL));
    sqlite3_bind_blob(stmt, 4, stream->key, 32, SQLITE_STATIC);
    sqlite3_bind_blob(stmt, 5, stream->nonce, 12, SQLITE_STATIC);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    if (rc != SQLITE_DONE)
    {
        if (error)
            *error = strdup(sqlite3_errmsg(stream->cache->db));
        return -1;
    }
    stream->finished = 1;
    return 1;
}

void shirm_cache_save_stream_free(ShirmCacheSaveStream *stream)
{
    if (stream)
    {
        if (stream->cipherCtx)
            EVP_CIPHER_CTX_free(stream->cipherCtx);
        if (stream->tempFile)
            fclose(stream->tempFile);
        free(stream);
    }
}

struct ShirmCacheLoadStream
{
    ShirmCache *cache;
    FILE *encFile;
    EVP_CIPHER_CTX *cipherCtx;
    unsigned char key[32];
    unsigned char nonce[12];
    int finished;
    size_t totalEncryptedSize;
    size_t processed;
};

ShirmCacheLoadStream *shirm_cache_load_stream_init(void *cache, const char *fileId, char **error)
{
    ShirmCache *c = (ShirmCache *)cache;
    ShirmCacheLoadStream *stream = (ShirmCacheLoadStream *)calloc(1, sizeof(ShirmCacheLoadStream));
    if (!stream)
    {
        if (error)
            *error = strdup("Memory allocation failed");
        return NULL;
    }
    stream->cache = c;

    sqlite3_stmt *stmt;
    const char *select_sql = "SELECT key, nonce FROM cache_metadata WHERE id = ?";
    if (sqlite3_prepare_v2(c->db, select_sql, -1, &stmt, NULL) != SQLITE_OK)
    {
        free(stream);
        if (error)
            *error = strdup(sqlite3_errmsg(c->db));
        return NULL;
    }
    sqlite3_bind_text(stmt, 1, fileId, -1, SQLITE_STATIC);
    if (sqlite3_step(stmt) != SQLITE_ROW)
    {
        sqlite3_finalize(stmt);
        free(stream);
        if (error)
            *error = strdup("File not found in cache");
        return NULL;
    }
    const unsigned char *key = sqlite3_column_blob(stmt, 0);
    const unsigned char *nonce = sqlite3_column_blob(stmt, 1);
    size_t key_len = sqlite3_column_bytes(stmt, 0);
    size_t nonce_len = sqlite3_column_bytes(stmt, 1);
    if (key_len != 32 || nonce_len != 12)
    {
        sqlite3_finalize(stmt);
        free(stream);
        if (error)
            *error = strdup("Invalid key/nonce in metadata");
        return NULL;
    }
    memcpy(stream->key, key, 32);
    memcpy(stream->nonce, nonce, 12);
    sqlite3_finalize(stmt);

    char file_path[2048];
    snprintf(file_path, sizeof(file_path), "%s/%s.enc", c->cache_dir, fileId);
    stream->encFile = fopen(file_path, "rb");
    if (!stream->encFile)
    {
        free(stream);
        if (error)
            *error = strdup("Cache file missing");
        return NULL;
    }
    fseek(stream->encFile, 0, SEEK_END);
    stream->totalEncryptedSize = ftell(stream->encFile);
    fseek(stream->encFile, 0, SEEK_SET);

    stream->cipherCtx = EVP_CIPHER_CTX_new();
    if (!stream->cipherCtx)
    {
        fclose(stream->encFile);
        free(stream);
        if (error)
            *error = strdup("EVP_CIPHER_CTX_new failed");
        return NULL;
    }
    if (EVP_DecryptInit_ex(stream->cipherCtx, EVP_aes_256_gcm(), NULL,
                           stream->key, stream->nonce) != 1)
    {
        EVP_CIPHER_CTX_free(stream->cipherCtx);
        fclose(stream->encFile);
        free(stream);
        if (error)
            *error = strdup("EVP_DecryptInit_ex failed");
        return NULL;
    }
    stream->finished = 0;
    stream->processed = 0;
    return stream;
}

int shirm_cache_load_stream_read(ShirmCacheLoadStream *stream,
                                 uint8_t **out_chunk, size_t *out_chunkSize, char **error)
{
    if (!stream || stream->finished)
        return 0;

    size_t remaining = stream->totalEncryptedSize - stream->processed;
    if (remaining == 0)
    {
        unsigned char finalBuf[EVP_MAX_BLOCK_LENGTH];
        int finalLen = 0;
        if (EVP_DecryptFinal_ex(stream->cipherCtx, finalBuf, &finalLen) != 1)
        {
            if (error)
                *error = strdup("EVP_DecryptFinal_ex failed (authentication failed)");
            return -1;
        }
        if (finalLen > 0)
        {
            *out_chunk = (uint8_t *)malloc(finalLen);
            if (!*out_chunk)
            {
                if (error)
                    *error = strdup("malloc final chunk failed");
                return -1;
            }
            memcpy(*out_chunk, finalBuf, finalLen);
            *out_chunkSize = finalLen;
        }
        else
        {
            *out_chunk = NULL;
            *out_chunkSize = 0;
        }
        stream->finished = 1;
        return 1;
    }

    size_t chunkSize = remaining > (1024 * 1024) ? 1024 * 1024 : remaining;
    int isLast = (chunkSize == remaining);
    size_t readSize = isLast ? (chunkSize - 16) : chunkSize;
    if (readSize == 0)
    {
        stream->processed += remaining;
        return shirm_cache_load_stream_read(stream, out_chunk, out_chunkSize, error);
    }

    unsigned char *encBuf = (unsigned char *)malloc(readSize);
    if (!encBuf)
    {
        if (error)
            *error = strdup("Read buffer allocation failed");
        return -1;
    }
    size_t bytesRead = fread(encBuf, 1, readSize, stream->encFile);
    if (bytesRead != readSize)
    {
        free(encBuf);
        if (error)
            *error = strdup("Failed to read from cache file");
        return -1;
    }
    stream->processed += bytesRead;

    unsigned char *decBuf = (unsigned char *)malloc(readSize + EVP_MAX_BLOCK_LENGTH);
    if (!decBuf)
    {
        free(encBuf);
        if (error)
            *error = strdup("Decryption buffer allocation failed");
        return -1;
    }
    int decLen = 0;
    if (EVP_DecryptUpdate(stream->cipherCtx, decBuf, &decLen, encBuf, (int)bytesRead) != 1)
    {
        free(encBuf);
        free(decBuf);
        if (error)
            *error = strdup("EVP_DecryptUpdate failed");
        return -1;
    }
    free(encBuf);

    *out_chunk = decBuf;
    *out_chunkSize = decLen;
    return 1;
}

void shirm_cache_load_stream_free(ShirmCacheLoadStream *stream)
{
    if (stream)
    {
        if (stream->cipherCtx)
            EVP_CIPHER_CTX_free(stream->cipherCtx);
        if (stream->encFile)
            fclose(stream->encFile);
        free(stream);
    }
}
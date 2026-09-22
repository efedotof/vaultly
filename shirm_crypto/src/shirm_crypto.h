#ifndef SHIRM_CRYPTO_H
#define SHIRM_CRYPTO_H

#include <stdint.h>
#include <stddef.h>

#if defined(_WIN32)
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C"
{
#endif

    typedef struct
    {
        uint8_t *data;
        size_t size;
        char *error;
    } EncryptResult;

    typedef struct
    {
        uint8_t *data;
        size_t size;
        char *error;
    } DecryptResult;

    typedef void (*ProgressCallback)(int percent, void *userData);
    typedef void (*DataCallback)(const uint8_t *chunk, size_t chunkSize, void *userData);

    typedef struct ShirmEncryptStream ShirmEncryptStream;
    FFI_PLUGIN_EXPORT ShirmEncryptStream *shirm_encrypt_stream_init(
        const char *inputPath,
        const char *publicKeyPem,
        const char *privateKeyPem,
        const char *userId,
        const char *keyOwner,
        const char *originalFileName,
        int compress,
        ProgressCallback progressCallback,
        void *userData,
        char **error);
    FFI_PLUGIN_EXPORT int shirm_encrypt_stream_process(
        ShirmEncryptStream *stream,
        uint8_t **out_chunk,
        size_t *out_chunk_size,
        char **error);
    FFI_PLUGIN_EXPORT void shirm_encrypt_stream_free(ShirmEncryptStream *stream);

    typedef struct ShirmDecryptStream ShirmDecryptStream;
    FFI_PLUGIN_EXPORT ShirmDecryptStream *shirm_decrypt_stream_init(
        const uint8_t *shpsData,
        size_t shpsSize,
        const char *privateKeyPem,
        ProgressCallback progressCallback,
        void *userData,
        char **error);
    FFI_PLUGIN_EXPORT int shirm_decrypt_stream_process(
        ShirmDecryptStream *stream,
        uint8_t **out_chunk,
        size_t *out_chunk_size,
        char **error);
    FFI_PLUGIN_EXPORT void shirm_decrypt_stream_free(ShirmDecryptStream *stream);

    FFI_PLUGIN_EXPORT EncryptResult *shirm_encrypt_file(
        const char *inputPath,
        const char *publicKeyPem,
        const char *privateKeyPem,
        const char *userId,
        const char *keyOwner,
        const char *originalFileName,
        int compress,
        ProgressCallback progressCallback,
        void *userData);
    FFI_PLUGIN_EXPORT DecryptResult *shirm_decrypt_data(
        const uint8_t *shpsData,
        size_t shpsSize,
        const char *privateKeyPem,
        ProgressCallback progressCallback,
        void *userData);
    FFI_PLUGIN_EXPORT void shirm_free_encrypt_result(EncryptResult *result);
    FFI_PLUGIN_EXPORT void shirm_free_decrypt_result(DecryptResult *result);

    FFI_PLUGIN_EXPORT void *shirm_cache_init(const char *cacheDir, char **error);
    FFI_PLUGIN_EXPORT int shirm_cache_save(void *cache, const char *fileId,
                                           const uint8_t *data, size_t dataSize,
                                           const char *originalName, char **error);
    FFI_PLUGIN_EXPORT uint8_t *shirm_cache_load(void *cache, const char *fileId,
                                                size_t *outSize, char **error);
    FFI_PLUGIN_EXPORT int shirm_cache_has(void *cache, const char *fileId);
    FFI_PLUGIN_EXPORT int shirm_cache_delete(void *cache, const char *fileId, char **error);
    FFI_PLUGIN_EXPORT int shirm_cache_clear(void *cache, char **error);
    FFI_PLUGIN_EXPORT char *shirm_cache_get_all_metadata(void *cache, char **error);
    FFI_PLUGIN_EXPORT void shirm_free(void *ptr);
    FFI_PLUGIN_EXPORT void shirm_cache_close(void *cache);

    typedef struct ShirmCacheSaveStream ShirmCacheSaveStream;
    FFI_PLUGIN_EXPORT ShirmCacheSaveStream *shirm_cache_save_stream_init(
        void *cache, const char *fileId, const char *originalName, char **error);
    FFI_PLUGIN_EXPORT int shirm_cache_save_stream_write(
        ShirmCacheSaveStream *stream, const uint8_t *chunk, size_t chunkSize, char **error);
    FFI_PLUGIN_EXPORT int shirm_cache_save_stream_finish(ShirmCacheSaveStream *stream, char **error);
    FFI_PLUGIN_EXPORT void shirm_cache_save_stream_free(ShirmCacheSaveStream *stream);

    typedef struct ShirmCacheLoadStream ShirmCacheLoadStream;
    FFI_PLUGIN_EXPORT ShirmCacheLoadStream *shirm_cache_load_stream_init(
        void *cache, const char *fileId, char **error);
    FFI_PLUGIN_EXPORT int shirm_cache_load_stream_read(
        ShirmCacheLoadStream *stream, uint8_t **out_chunk, size_t *out_chunkSize, char **error);
    FFI_PLUGIN_EXPORT void shirm_cache_load_stream_free(ShirmCacheLoadStream *stream);

#ifdef __cplusplus
}
#endif

#endif
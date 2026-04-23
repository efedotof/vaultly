#include "shirm_crypto.h"
#include "internal/shirm_crypto_common.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

struct ShirmEncryptStream
{
    FILE *inputFile;
    EVP_CIPHER_CTX *cipherCtx;
    unsigned char *readBuffer;
    size_t readBufferSize;
    int compress;
    int headerWritten;
    int finished;
    unsigned char *headerData;
    size_t headerSize;
    ProgressCallback progressCallback;
    void *userData;
    size_t totalRead;
    size_t originalSize;
    unsigned char aesKey[32];
    unsigned char iv[12];
    z_stream zStream;
    int zStreamInitialized;
    unsigned char *compressBuffer;
    size_t compressBufferSize;
};

struct ShirmDecryptStream
{
    const unsigned char *inputData;
    size_t inputSize;
    size_t inputOffset;
    EVP_CIPHER_CTX *cipherCtx;
    int headerParsed;
    int finished;
    int compressed;
    z_stream zStream;
    int zStreamInitialized;
    ProgressCallback progressCallback;
    void *userData;
    size_t totalProcessed;
    size_t totalEncryptedSize;
};

ShirmEncryptStream *shirm_encrypt_stream_init(
    const char *inputPath,
    const char *publicKeyPem,
    const char *privateKeyPem,
    const char *userId,
    const char *keyOwner,
    const char *originalFileName,
    int compress,
    ProgressCallback progressCallback,
    void *userData,
    char **error)
{

    ShirmEncryptStream *stream = (ShirmEncryptStream *)calloc(1, sizeof(ShirmEncryptStream));
    if (!stream)
    {
        if (error)
            *error = strdup("Memory allocation failed");
        return NULL;
    }

    stream->compress = compress;
    stream->progressCallback = progressCallback;
    stream->userData = userData;
    stream->readBufferSize = 1024 * 1024;
    stream->zStreamInitialized = 0;

    stream->inputFile = fopen(inputPath, "rb");
    if (!stream->inputFile)
    {
        free(stream);
        if (error)
            *error = strdup("Cannot open input file");
        return NULL;
    }

    fseek(stream->inputFile, 0, SEEK_END);
    stream->originalSize = ftell(stream->inputFile);
    fseek(stream->inputFile, 0, SEEK_SET);

    if (!generate_random_bytes(stream->aesKey, 32) || !generate_random_bytes(stream->iv, 12))
    {
        fclose(stream->inputFile);
        free(stream);
        if (error)
            *error = strdup("Failed to generate random bytes");
        return NULL;
    }

    EVP_PKEY *pubKey = load_public_key_from_pem(publicKeyPem);
    if (!pubKey)
    {
        fclose(stream->inputFile);
        free(stream);
        if (error)
            *error = strdup("Failed to load public key");
        return NULL;
    }

    unsigned char *encryptedKey = NULL;
    size_t encryptedKey_len = 0;
    if (!rsa_oaep_encrypt(stream->aesKey, 32, pubKey, &encryptedKey, &encryptedKey_len))
    {
        EVP_PKEY_free(pubKey);
        fclose(stream->inputFile);
        free(stream);
        if (error)
            *error = strdup("RSA encryption failed");
        return NULL;
    }
    EVP_PKEY_free(pubKey);

    unsigned char *signature = NULL;
    size_t signature_len = 0;
    if (privateKeyPem && *privateKeyPem)
    {
        EVP_PKEY *privKey = load_private_key_from_pem(privateKeyPem);
        if (privKey)
        {
            EVP_PKEY_free(privKey);
        }
    }

    const char *origName = originalFileName ? originalFileName : "";
    stream->headerData = build_header(origName, stream->originalSize,
                                      encryptedKey, encryptedKey_len,
                                      stream->iv, keyOwner, userId, compress,
                                      signature, signature_len,
                                      &stream->headerSize);
    free(encryptedKey);
    if (signature)
        free(signature);

    stream->cipherCtx = EVP_CIPHER_CTX_new();
    if (!stream->cipherCtx)
    {
        free(stream->headerData);
        fclose(stream->inputFile);
        free(stream);
        if (error)
            *error = strdup("EVP_CIPHER_CTX_new failed");
        return NULL;
    }
    if (EVP_EncryptInit_ex(stream->cipherCtx, EVP_aes_256_gcm(), NULL,
                           stream->aesKey, stream->iv) != 1)
    {
        free(stream->headerData);
        EVP_CIPHER_CTX_free(stream->cipherCtx);
        fclose(stream->inputFile);
        free(stream);
        if (error)
            *error = strdup("EVP_EncryptInit_ex failed");
        return NULL;
    }

    stream->readBuffer = (unsigned char *)malloc(stream->readBufferSize);
    if (!stream->readBuffer)
    {
        free(stream->headerData);
        EVP_CIPHER_CTX_free(stream->cipherCtx);
        fclose(stream->inputFile);
        free(stream);
        if (error)
            *error = strdup("Read buffer allocation failed");
        return NULL;
    }

    if (compress)
    {
        stream->compressBufferSize = stream->readBufferSize * 2;
        stream->compressBuffer = (unsigned char *)malloc(stream->compressBufferSize);
        if (!stream->compressBuffer)
        {
            free(stream->headerData);
            free(stream->readBuffer);
            EVP_CIPHER_CTX_free(stream->cipherCtx);
            fclose(stream->inputFile);
            free(stream);
            if (error)
                *error = strdup("Compress buffer allocation failed");
            return NULL;
        }
    }

    stream->headerWritten = 0;
    stream->finished = 0;
    return stream;
}

int shirm_encrypt_stream_process(
    ShirmEncryptStream *stream,
    uint8_t **out_chunk,
    size_t *out_chunk_size,
    char **error)
{

    if (!stream || !out_chunk || !out_chunk_size)
        return -1;

    if (!stream->headerWritten)
    {
        *out_chunk = (uint8_t *)malloc(stream->headerSize);
        if (!*out_chunk)
        {
            if (error)
                *error = strdup("malloc header chunk failed");
            return -1;
        }
        memcpy(*out_chunk, stream->headerData, stream->headerSize);
        *out_chunk_size = stream->headerSize;
        stream->headerWritten = 1;
        return 1;
    }

    if (stream->finished)
        return 0;

    size_t bytesRead = fread(stream->readBuffer, 1, stream->readBufferSize, stream->inputFile);
    if (bytesRead == 0)
    {
        unsigned char finalBuf[EVP_MAX_BLOCK_LENGTH + 16];
        int finalLen = 0;
        if (EVP_EncryptFinal_ex(stream->cipherCtx, finalBuf, &finalLen) != 1)
        {
            if (error)
                *error = strdup("EVP_EncryptFinal_ex failed");
            return -1;
        }
        unsigned char tag[16];
        if (EVP_CIPHER_CTX_ctrl(stream->cipherCtx, EVP_CTRL_GCM_GET_TAG, 16, tag) != 1)
        {
            if (error)
                *error = strdup("Failed to get GCM tag");
            return -1;
        }
        size_t total = finalLen + 16;
        *out_chunk = (uint8_t *)malloc(total);
        if (!*out_chunk)
        {
            if (error)
                *error = strdup("malloc final chunk failed");
            return -1;
        }
        memcpy(*out_chunk, finalBuf, finalLen);
        memcpy(*out_chunk + finalLen, tag, 16);
        *out_chunk_size = total;

        if (stream->progressCallback)
            stream->progressCallback(100, stream->userData);
        stream->finished = 1;
        return 1;
    }

    stream->totalRead += bytesRead;
    unsigned char *dataToEncrypt = stream->readBuffer;
    size_t dataToEncryptLen = bytesRead;

    if (stream->compress)
    {
        if (!stream->zStreamInitialized)
        {
            memset(&stream->zStream, 0, sizeof(z_stream));
            if (deflateInit2(&stream->zStream, Z_DEFAULT_COMPRESSION, Z_DEFLATED,
                             16 + MAX_WBITS, 8, Z_DEFAULT_STRATEGY) != Z_OK)
            {
                if (error)
                    *error = strdup("deflateInit2 failed");
                return -1;
            }
            stream->zStreamInitialized = 1;
        }
        stream->zStream.next_in = stream->readBuffer;
        stream->zStream.avail_in = (uInt)bytesRead;
        stream->zStream.next_out = stream->compressBuffer;
        stream->zStream.avail_out = (uInt)stream->compressBufferSize;
        int ret = deflate(&stream->zStream, Z_SYNC_FLUSH);
        if (ret < 0)
        {
            if (error)
                *error = strdup("deflate failed");
            return -1;
        }
        dataToEncrypt = stream->compressBuffer;
        dataToEncryptLen = stream->compressBufferSize - stream->zStream.avail_out;
    }

    int outLen = (int)dataToEncryptLen + EVP_MAX_BLOCK_LENGTH;
    unsigned char *encBuf = (unsigned char *)malloc(outLen);
    if (!encBuf)
    {
        if (error)
            *error = strdup("Encryption buffer allocation failed");
        return -1;
    }
    int encLen = 0;
    if (EVP_EncryptUpdate(stream->cipherCtx, encBuf, &encLen,
                          dataToEncrypt, (int)dataToEncryptLen) != 1)
    {
        free(encBuf);
        if (error)
            *error = strdup("EVP_EncryptUpdate failed");
        return -1;
    }

    *out_chunk = encBuf;
    *out_chunk_size = encLen;

    if (stream->progressCallback)
    {
        int percent = (int)(stream->totalRead * 100 / stream->originalSize);
        if (percent > 100)
            percent = 100;
        stream->progressCallback(percent, stream->userData);
    }
    return 1;
}

void shirm_encrypt_stream_free(ShirmEncryptStream *stream)
{
    if (stream)
    {
        if (stream->inputFile)
            fclose(stream->inputFile);
        if (stream->cipherCtx)
            EVP_CIPHER_CTX_free(stream->cipherCtx);
        if (stream->headerData)
            free(stream->headerData);
        if (stream->readBuffer)
            free(stream->readBuffer);
        if (stream->compressBuffer)
            free(stream->compressBuffer);
        if (stream->zStreamInitialized)
            deflateEnd(&stream->zStream);
        free(stream);
    }
}

ShirmDecryptStream *shirm_decrypt_stream_init(
    const unsigned char *shpsData,
    size_t shpsSize,
    const char *privateKeyPem,
    ProgressCallback progressCallback,
    void *userData,
    char **error)
{

    if (shpsSize < 4)
    {
        if (error)
            *error = strdup("Data too short");
        return NULL;
    }

    ShirmDecryptStream *stream = (ShirmDecryptStream *)calloc(1, sizeof(ShirmDecryptStream));
    if (!stream)
    {
        if (error)
            *error = strdup("Memory allocation failed");
        return NULL;
    }

    stream->inputData = shpsData;
    stream->inputSize = shpsSize;
    stream->progressCallback = progressCallback;
    stream->userData = userData;

    uint32_t headerLen_net;
    memcpy(&headerLen_net, shpsData, 4);
    uint32_t headerLen = ntohl(headerLen_net);
    if (headerLen > 20 * 1024 || shpsSize < 4 + headerLen)
    {
        free(stream);
        if (error)
            *error = strdup("Invalid header");
        return NULL;
    }

    char *jsonStr = (char *)malloc(headerLen + 1);
    memcpy(jsonStr, shpsData + 4, headerLen);
    jsonStr[headerLen] = '\0';

    char encKeyB64[1024] = {0}, ivB64[128] = {0};
    int compressed = 0;
    char *p = strstr(jsonStr, "\"encryptedKey\":\"");
    if (p)
    {
        p += 16;
        char *end = strchr(p, '\"');
        if (end)
        {
            size_t len = end - p;
            if (len < sizeof(encKeyB64))
            {
                memcpy(encKeyB64, p, len);
                encKeyB64[len] = '\0';
            }
        }
    }
    p = strstr(jsonStr, "\"iv\":\"");
    if (p)
    {
        p += 6;
        char *end = strchr(p, '\"');
        if (end)
        {
            size_t len = end - p;
            if (len < sizeof(ivB64))
            {
                memcpy(ivB64, p, len);
                ivB64[len] = '\0';
            }
        }
    }
    if (strstr(jsonStr, "\"compressed\":\"true\""))
        compressed = 1;
    free(jsonStr);

    stream->compressed = compressed;
    stream->totalEncryptedSize = shpsSize - (4 + headerLen);

    size_t encKey_len = 0;
    unsigned char *encryptedKey = base64_decode(encKeyB64, &encKey_len);
    size_t iv_len = 0;
    unsigned char *iv = base64_decode(ivB64, &iv_len);
    if (!encryptedKey || !iv || iv_len != 12)
    {
        if (encryptedKey)
            free(encryptedKey);
        if (iv)
            free(iv);
        free(stream);
        if (error)
            *error = strdup("Invalid header fields");
        return NULL;
    }

    EVP_PKEY *privKey = load_private_key_from_pem(privateKeyPem);
    if (!privKey)
    {
        free(encryptedKey);
        free(iv);
        free(stream);
        if (error)
            *error = strdup("Failed to load private key");
        return NULL;
    }

    unsigned char *aesKey = NULL;
    size_t aesKey_len = 0;
    int dec_ok = rsa_oaep_decrypt(encryptedKey, encKey_len, privKey, &aesKey, &aesKey_len);
    if (!dec_ok)
    {
        dec_ok = rsa_oaep_decrypt_sha1(encryptedKey, encKey_len, privKey, &aesKey, &aesKey_len);
    }
    EVP_PKEY_free(privKey);
    free(encryptedKey);
    if (!dec_ok || aesKey_len != 32)
    {
        free(iv);
        free(stream);
        if (aesKey)
            free(aesKey);
        if (error)
            *error = strdup("RSA decryption failed");
        return NULL;
    }

    stream->cipherCtx = EVP_CIPHER_CTX_new();
    if (!stream->cipherCtx)
    {
        free(aesKey);
        free(iv);
        free(stream);
        if (error)
            *error = strdup("EVP_CIPHER_CTX_new failed");
        return NULL;
    }
    if (EVP_DecryptInit_ex(stream->cipherCtx, EVP_aes_256_gcm(), NULL,
                           aesKey, iv) != 1)
    {
        free(aesKey);
        free(iv);
        EVP_CIPHER_CTX_free(stream->cipherCtx);
        free(stream);
        if (error)
            *error = strdup("EVP_DecryptInit_ex failed");
        return NULL;
    }
    free(aesKey);
    free(iv);

    stream->inputOffset = 4 + headerLen;
    stream->headerParsed = 1;
    stream->finished = 0;
    stream->zStreamInitialized = 0;

    if (progressCallback)
        progressCallback(10, userData);
    return stream;
}

int shirm_decrypt_stream_process(
    ShirmDecryptStream *stream,
    uint8_t **out_chunk,
    size_t *out_chunk_size,
    char **error)
{

    if (!stream || !out_chunk || !out_chunk_size)
        return -1;
    if (!stream->headerParsed)
    {
        if (error)
            *error = strdup("Stream not initialized");
        return -1;
    }
    if (stream->finished)
        return 0;

    size_t remaining = stream->inputSize - stream->inputOffset;
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
            *out_chunk_size = finalLen;
        }
        else
        {
            *out_chunk = NULL;
            *out_chunk_size = 0;
        }
        if (stream->progressCallback)
            stream->progressCallback(100, stream->userData);
        stream->finished = 1;
        return 1;
    }

    size_t chunkSize = remaining > (1024 * 1024) ? 1024 * 1024 : remaining;
    int isLast = (chunkSize == remaining);
    size_t updateSize = isLast ? (chunkSize - 16) : chunkSize;
    if (updateSize == 0)
    {
        stream->inputOffset += remaining;
        return shirm_decrypt_stream_process(stream, out_chunk, out_chunk_size, error);
    }

    unsigned char *decBuf = (unsigned char *)malloc(updateSize + EVP_MAX_BLOCK_LENGTH);
    if (!decBuf)
    {
        if (error)
            *error = strdup("Decryption buffer allocation failed");
        return -1;
    }
    int decLen = 0;
    if (EVP_DecryptUpdate(stream->cipherCtx, decBuf, &decLen,
                          stream->inputData + stream->inputOffset, (int)updateSize) != 1)
    {
        free(decBuf);
        if (error)
            *error = strdup("EVP_DecryptUpdate failed");
        return -1;
    }
    stream->inputOffset += updateSize;
    stream->totalProcessed += updateSize;

    *out_chunk = decBuf;
    *out_chunk_size = decLen;

    if (stream->progressCallback)
    {
        int percent = (int)(stream->totalProcessed * 100 / stream->totalEncryptedSize);
        if (percent > 100)
            percent = 100;
        stream->progressCallback(percent, stream->userData);
    }
    return 1;
}

void shirm_decrypt_stream_free(ShirmDecryptStream *stream)
{
    if (stream)
    {
        if (stream->cipherCtx)
            EVP_CIPHER_CTX_free(stream->cipherCtx);
        if (stream->zStreamInitialized)
            inflateEnd(&stream->zStream);
        free(stream);
    }
}
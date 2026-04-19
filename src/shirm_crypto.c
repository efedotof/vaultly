#include "shirm_crypto.h"

#include <arpa/inet.h>
#include <openssl/evp.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <openssl/err.h>
#include <zlib.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static void current_iso8601(char *buffer, size_t buffer_size)
{
    time_t t = time(NULL);
    struct tm *tm = gmtime(&t);
    strftime(buffer, buffer_size, "%Y-%m-%dT%H:%M:%SZ", tm);
}

static char *base64_encode(const unsigned char *data, size_t len)
{
    BIO *bio, *b64;
    BUF_MEM *bufferPtr;
    b64 = BIO_new(BIO_f_base64());
    bio = BIO_new(BIO_s_mem());
    bio = BIO_push(b64, bio);
    BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);
    BIO_write(bio, data, (int)len);
    BIO_flush(bio);
    BIO_get_mem_ptr(bio, &bufferPtr);
    char *result = (char *)malloc(bufferPtr->length + 1);
    memcpy(result, bufferPtr->data, bufferPtr->length);
    result[bufferPtr->length] = '\0';
    BIO_free_all(bio);
    return result;
}

static unsigned char *base64_decode(const char *encoded, size_t *out_len)
{
    BIO *bio, *b64;
    size_t len = strlen(encoded);
    unsigned char *buffer = (unsigned char *)malloc(len);
    b64 = BIO_new(BIO_f_base64());
    bio = BIO_new_mem_buf(encoded, (int)len);
    bio = BIO_push(b64, bio);
    BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);
    int decodedLen = BIO_read(bio, buffer, (int)len);
    if (decodedLen < 0)
        decodedLen = 0;
    *out_len = decodedLen;
    BIO_free_all(bio);
    return buffer;
}

static int generate_random_bytes(unsigned char *buf, size_t len)
{
    return RAND_bytes(buf, (int)len) == 1;
}

static EVP_PKEY *load_public_key_from_pem(const char *pem)
{
    BIO *bio = BIO_new_mem_buf(pem, -1);
    if (!bio)
        return NULL;
    EVP_PKEY *key = PEM_read_bio_PUBKEY(bio, NULL, NULL, NULL);
    BIO_free(bio);
    return key;
}

static EVP_PKEY *load_private_key_from_pem(const char *pem)
{
    BIO *bio = BIO_new_mem_buf(pem, -1);
    if (!bio)
        return NULL;
    EVP_PKEY *key = PEM_read_bio_PrivateKey(bio, NULL, NULL, NULL);
    BIO_free(bio);
    return key;
}

static int rsa_oaep_encrypt(const unsigned char *plaintext, size_t plaintext_len,
                            EVP_PKEY *pubkey,
                            unsigned char **out, size_t *out_len)
{
    EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new(pubkey, NULL);
    if (!ctx)
        return 0;
    if (EVP_PKEY_encrypt_init(ctx) <= 0)
    {
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }
    if (EVP_PKEY_CTX_set_rsa_padding(ctx, RSA_PKCS1_OAEP_PADDING) <= 0)
    {
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }
    if (EVP_PKEY_CTX_set_rsa_oaep_md(ctx, EVP_sha256()) <= 0)
    {
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }

    size_t outlen = 0;
    if (EVP_PKEY_encrypt(ctx, NULL, &outlen, plaintext, plaintext_len) <= 0)
    {
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }

    unsigned char *outbuf = (unsigned char *)malloc(outlen);
    if (EVP_PKEY_encrypt(ctx, outbuf, &outlen, plaintext, plaintext_len) <= 0)
    {
        free(outbuf);
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }
    *out = outbuf;
    *out_len = outlen;
    EVP_PKEY_CTX_free(ctx);
    return 1;
}

static int rsa_oaep_decrypt_sha1(const unsigned char *ciphertext, size_t ciphertext_len,
                                 EVP_PKEY *privkey,
                                 unsigned char **out, size_t *out_len)
{
    EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new(privkey, NULL);
    if (!ctx)
        return 0;
    if (EVP_PKEY_decrypt_init(ctx) <= 0)
    {
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }
    if (EVP_PKEY_CTX_set_rsa_padding(ctx, RSA_PKCS1_OAEP_PADDING) <= 0)
    {
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }
    if (EVP_PKEY_CTX_set_rsa_oaep_md(ctx, EVP_sha1()) <= 0)
    {
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }

    size_t outlen = 0;
    if (EVP_PKEY_decrypt(ctx, NULL, &outlen, ciphertext, ciphertext_len) <= 0)
    {
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }

    unsigned char *outbuf = (unsigned char *)malloc(outlen);
    if (EVP_PKEY_decrypt(ctx, outbuf, &outlen, ciphertext, ciphertext_len) <= 0)
    {
        free(outbuf);
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }
    *out = outbuf;
    *out_len = outlen;
    EVP_PKEY_CTX_free(ctx);
    return 1;
}

static int rsa_oaep_decrypt(const unsigned char *ciphertext, size_t ciphertext_len,
                            EVP_PKEY *privkey,
                            unsigned char **out, size_t *out_len)
{
    EVP_PKEY_CTX *ctx = EVP_PKEY_CTX_new(privkey, NULL);
    if (!ctx)
        return 0;
    if (EVP_PKEY_decrypt_init(ctx) <= 0)
    {
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }
    if (EVP_PKEY_CTX_set_rsa_padding(ctx, RSA_PKCS1_OAEP_PADDING) <= 0)
    {
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }
    if (EVP_PKEY_CTX_set_rsa_oaep_md(ctx, EVP_sha256()) <= 0)
    {
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }

    size_t outlen = 0;
    if (EVP_PKEY_decrypt(ctx, NULL, &outlen, ciphertext, ciphertext_len) <= 0)
    {
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }

    unsigned char *outbuf = (unsigned char *)malloc(outlen);
    if (EVP_PKEY_decrypt(ctx, outbuf, &outlen, ciphertext, ciphertext_len) <= 0)
    {
        free(outbuf);
        EVP_PKEY_CTX_free(ctx);
        return 0;
    }
    *out = outbuf;
    *out_len = outlen;
    EVP_PKEY_CTX_free(ctx);
    return 1;
}

static int rsa_sign(const unsigned char *data, size_t data_len,
                    EVP_PKEY *privkey,
                    unsigned char **sig, size_t *sig_len)
{
    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    if (!ctx)
        return 0;
    if (EVP_DigestSignInit(ctx, NULL, EVP_sha256(), NULL, privkey) <= 0)
    {
        EVP_MD_CTX_free(ctx);
        return 0;
    }
    EVP_PKEY_CTX_set_rsa_padding(EVP_MD_CTX_pkey_ctx(ctx), RSA_PKCS1_PSS_PADDING);
    EVP_PKEY_CTX_set_rsa_pss_saltlen(EVP_MD_CTX_pkey_ctx(ctx), RSA_PSS_SALTLEN_DIGEST);
    if (EVP_DigestSignUpdate(ctx, data, data_len) <= 0)
    {
        EVP_MD_CTX_free(ctx);
        return 0;
    }

    size_t req = 0;
    if (EVP_DigestSignFinal(ctx, NULL, &req) <= 0)
    {
        EVP_MD_CTX_free(ctx);
        return 0;
    }
    unsigned char *buf = (unsigned char *)malloc(req);
    if (EVP_DigestSignFinal(ctx, buf, &req) <= 0)
    {
        free(buf);
        EVP_MD_CTX_free(ctx);
        return 0;
    }
    *sig = buf;
    *sig_len = req;
    EVP_MD_CTX_free(ctx);
    return 1;
}

static int gzip_compress(const unsigned char *input, size_t input_len,
                         unsigned char **out, size_t *out_len)
{
    z_stream zs;
    memset(&zs, 0, sizeof(zs));
    if (deflateInit2(&zs, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 16 + MAX_WBITS, 8, Z_DEFAULT_STRATEGY) != Z_OK)
        return 0;

    zs.next_in = (Bytef *)input;
    zs.avail_in = (uInt)input_len;

    size_t total = 0;
    size_t capacity = 1024 * 1024;
    unsigned char *buf = (unsigned char *)malloc(capacity);
    int ret;
    do
    {
        if (total == capacity)
        {
            capacity *= 2;
            buf = (unsigned char *)realloc(buf, capacity);
        }
        zs.next_out = buf + total;
        zs.avail_out = (uInt)(capacity - total);
        ret = deflate(&zs, Z_FINISH);
        total = capacity - zs.avail_out;
    } while (ret == Z_OK);

    deflateEnd(&zs);
    if (ret != Z_STREAM_END)
    {
        free(buf);
        return 0;
    }
    *out = buf;
    *out_len = total;
    return 1;
}

static int gzip_decompress(const unsigned char *input, size_t input_len,
                           unsigned char **out, size_t *out_len)
{
    z_stream zs;
    memset(&zs, 0, sizeof(zs));
    if (inflateInit2(&zs, 16 + MAX_WBITS) != Z_OK)
        return 0;

    zs.next_in = (Bytef *)input;
    zs.avail_in = (uInt)input_len;

    size_t total = 0;
    size_t capacity = 1024 * 1024;
    unsigned char *buf = (unsigned char *)malloc(capacity);
    int ret;
    do
    {
        if (total == capacity)
        {
            capacity *= 2;
            buf = (unsigned char *)realloc(buf, capacity);
        }
        zs.next_out = buf + total;
        zs.avail_out = (uInt)(capacity - total);
        ret = inflate(&zs, Z_NO_FLUSH);
        total = capacity - zs.avail_out;
    } while (ret == Z_OK);

    inflateEnd(&zs);
    if (ret != Z_STREAM_END)
    {
        free(buf);
        return 0;
    }
    *out = buf;
    *out_len = total;
    return 1;
}

static unsigned char *read_file(const char *path, size_t *size)
{
    FILE *file = fopen(path, "rb");
    if (!file)
        return NULL;
    fseek(file, 0, SEEK_END);
    long fsize = ftell(file);
    fseek(file, 0, SEEK_SET);
    unsigned char *buf = (unsigned char *)malloc(fsize);
    fread(buf, 1, fsize, file);
    fclose(file);
    *size = fsize;
    return buf;
}

static int aes_gcm_encrypt(const unsigned char *plaintext, size_t plaintext_len,
                           const unsigned char *key, const unsigned char *iv,
                           unsigned char **out, size_t *out_len)
{
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx)
        return 0;
    if (EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, key, iv) != 1)
    {
        EVP_CIPHER_CTX_free(ctx);
        return 0;
    }

    size_t capacity = plaintext_len + EVP_MAX_BLOCK_LENGTH;
    unsigned char *buf = (unsigned char *)malloc(capacity + 16);
    int len = 0;
    if (EVP_EncryptUpdate(ctx, buf, &len, plaintext, (int)plaintext_len) != 1)
    {
        free(buf);
        EVP_CIPHER_CTX_free(ctx);
        return 0;
    }
    int tmp = 0;
    if (EVP_EncryptFinal_ex(ctx, buf + len, &tmp) != 1)
    {
        free(buf);
        EVP_CIPHER_CTX_free(ctx);
        return 0;
    }
    len += tmp;

    unsigned char tag[16];
    if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, tag) != 1)
    {
        free(buf);
        EVP_CIPHER_CTX_free(ctx);
        return 0;
    }
    memcpy(buf + len, tag, 16);
    *out = buf;
    *out_len = len + 16;
    EVP_CIPHER_CTX_free(ctx);
    return 1;
}

static int aes_gcm_decrypt(const unsigned char *ciphertext, size_t ciphertext_len,
                           const unsigned char *key, const unsigned char *iv,
                           unsigned char **out, size_t *out_len)
{
    if (ciphertext_len < 16)
        return 0;
    size_t tag_offset = ciphertext_len - 16;

    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx)
        return 0;
    if (EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, key, iv) != 1)
    {
        EVP_CIPHER_CTX_free(ctx);
        return 0;
    }

    unsigned char *buf = (unsigned char *)malloc(tag_offset);
    int len = 0;
    if (EVP_DecryptUpdate(ctx, buf, &len, ciphertext, (int)tag_offset) != 1)
    {
        free(buf);
        EVP_CIPHER_CTX_free(ctx);
        return 0;
    }
    if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16, (void *)(ciphertext + tag_offset)) != 1)
    {
        free(buf);
        EVP_CIPHER_CTX_free(ctx);
        return 0;
    }
    int tmp = 0;
    if (EVP_DecryptFinal_ex(ctx, buf + len, &tmp) != 1)
    {
        free(buf);
        EVP_CIPHER_CTX_free(ctx);
        return 0;
    }
    len += tmp;
    *out = buf;
    *out_len = len;
    EVP_CIPHER_CTX_free(ctx);
    return 1;
}

static unsigned char *build_header(const char *originalFileName,
                                   size_t originalFileSize,
                                   const unsigned char *encryptedKey, size_t encryptedKey_len,
                                   const unsigned char *iv,
                                   const char *keyOwner,
                                   const char *userId,
                                   int compressed,
                                   const unsigned char *signature, size_t signature_len,
                                   size_t *header_len)
{
    char time_buf[32];
    current_iso8601(time_buf, sizeof(time_buf));

    char *encKeyB64 = base64_encode(encryptedKey, encryptedKey_len);
    char *ivB64 = base64_encode(iv, 12);

    char *sigB64 = NULL;
    if (signature && signature_len > 0)
    {
        sigB64 = base64_encode(signature, signature_len);
    }

    char *json = malloc(4096);
    int pos = sprintf(json,
                      "{"
                      "\"version\":\"1.0\","
                      "\"algorithm\":\"AES-256-GCM\","
                      "\"keyEncryption\":\"RSA-OAEP\","
                      "\"creationDate\":\"%s\","
                      "\"originalFileName\":\"%s\","
                      "\"originalFileSize\":%zu,"
                      "\"encryptedKey\":\"%s\","
                      "\"iv\":\"%s\","
                      "\"keyOwner\":\"%s\","
                      "\"userId\":\"%s\"",
                      time_buf, originalFileName, originalFileSize, encKeyB64, ivB64, keyOwner, userId);

    if (compressed)
    {
        pos += sprintf(json + pos, ",\"metadata\":{\"compressed\":\"true\"}");
    }
    if (sigB64)
    {
        pos += sprintf(json + pos, ",\"signature\":\"%s\"", sigB64);
    }
    sprintf(json + pos, "}");

    free(encKeyB64);
    free(ivB64);
    if (sigB64)
        free(sigB64);

    size_t json_len = strlen(json);
    uint32_t net_len = htonl((uint32_t)json_len);

    unsigned char *result = (unsigned char *)malloc(4 + json_len);
    memcpy(result, &net_len, 4);
    memcpy(result + 4, json, json_len);
    free(json);

    *header_len = 4 + json_len;
    return result;
}

EncryptResult *shirm_encrypt_file(
    const char *inputPath,
    const char *publicKeyPem,
    const char *privateKeyPem,
    const char *userId,
    const char *keyOwner,
    const char *originalFileName,
    int compress,
    ProgressCallback progressCallback,
    void *userData)
{
    EncryptResult *result = (EncryptResult *)malloc(sizeof(EncryptResult));
    result->data = NULL;
    result->size = 0;
    result->error = NULL;

    size_t file_size = 0;
    unsigned char *fileData = read_file(inputPath, &file_size);
    if (!fileData)
    {
        result->error = strdup("Cannot open file");
        return result;
    }
    size_t originalSize = file_size;
    if (progressCallback)
        progressCallback(5, userData);

    unsigned char *dataToEncrypt = fileData;
    size_t dataToEncrypt_len = file_size;
    unsigned char *compressedData = NULL;
    size_t compressed_len = 0;
    if (compress)
    {
        if (!gzip_compress(fileData, file_size, &compressedData, &compressed_len))
        {
            free(fileData);
            result->error = strdup("Compression failed");
            return result;
        }
        free(fileData);
        dataToEncrypt = compressedData;
        dataToEncrypt_len = compressed_len;
        if (progressCallback)
            progressCallback(10, userData);
    }

    unsigned char aesKey[32], iv[12];
    if (!generate_random_bytes(aesKey, 32) || !generate_random_bytes(iv, 12))
    {
        free(dataToEncrypt);
        result->error = strdup("Failed to generate random bytes");
        return result;
    }

    EVP_PKEY *pubKey = load_public_key_from_pem(publicKeyPem);
    if (!pubKey)
    {
        free(dataToEncrypt);
        result->error = strdup("Failed to load public key");
        return result;
    }
    unsigned char *encryptedKey = NULL;
    size_t encryptedKey_len = 0;
    int enc_ok = rsa_oaep_encrypt(aesKey, 32, pubKey, &encryptedKey, &encryptedKey_len);
    EVP_PKEY_free(pubKey);
    if (!enc_ok)
    {
        free(dataToEncrypt);
        result->error = strdup("RSA encryption failed");
        return result;
    }

    unsigned char *signature = NULL;
    size_t signature_len = 0;
    if (privateKeyPem && *privateKeyPem)
    {
        EVP_PKEY *privKey = load_private_key_from_pem(privateKeyPem);
        if (privKey)
        {
            rsa_sign(dataToEncrypt, dataToEncrypt_len, privKey, &signature, &signature_len);
            EVP_PKEY_free(privKey);
        }
    }
    if (progressCallback)
        progressCallback(20, userData);

    unsigned char *encryptedData = NULL;
    size_t encryptedData_len = 0;
    if (!aes_gcm_encrypt(dataToEncrypt, dataToEncrypt_len, aesKey, iv,
                         &encryptedData, &encryptedData_len))
    {
        free(dataToEncrypt);
        free(encryptedKey);
        if (signature)
            free(signature);
        result->error = strdup("AES encryption failed");
        return result;
    }
    free(dataToEncrypt);
    if (progressCallback)
        progressCallback(80, userData);

    const char *origName = originalFileName ? originalFileName : "";
    size_t header_len = 0;
    unsigned char *header = build_header(origName, originalSize,
                                         encryptedKey, encryptedKey_len,
                                         iv, keyOwner, userId, compress,
                                         signature, signature_len,
                                         &header_len);
    free(encryptedKey);
    if (signature)
        free(signature);

    unsigned char *finalData = (unsigned char *)malloc(header_len + encryptedData_len);
    memcpy(finalData, header, header_len);
    memcpy(finalData + header_len, encryptedData, encryptedData_len);
    free(header);
    free(encryptedData);

    if (progressCallback)
        progressCallback(100, userData);

    result->data = finalData;
    result->size = header_len + encryptedData_len;
    return result;
}

DecryptResult *shirm_decrypt_data(
    const unsigned char *shpsData,
    size_t shpsSize,
    const char *privateKeyPem,
    ProgressCallback progressCallback,
    void *userData)
{
    DecryptResult *result = (DecryptResult *)malloc(sizeof(DecryptResult));
    result->data = NULL;
    result->size = 0;
    result->error = NULL;

    if (shpsSize < 4)
    {
        result->error = strdup("Data too short");
        return result;
    }

    uint32_t headerLen_net;
    memcpy(&headerLen_net, shpsData, 4);
    uint32_t headerLen = ntohl(headerLen_net);
    if (headerLen > 20 * 1024 || shpsSize < 4 + headerLen)
    {
        result->error = strdup("Invalid header");
        return result;
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
    {
        compressed = 1;
    }
    free(jsonStr);

    if (progressCallback)
        progressCallback(10, userData);

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
        result->error = strdup("Invalid header fields");
        return result;
    }

    EVP_PKEY *privKey = load_private_key_from_pem(privateKeyPem);
    if (!privKey)
    {
        free(encryptedKey);
        free(iv);
        result->error = strdup("Failed to load private key");
        return result;
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
        if (aesKey)
            free(aesKey);
        result->error = strdup("RSA decryption failed");
        return result;
    }

    if (progressCallback)
        progressCallback(20, userData);

    const unsigned char *encryptedDataPtr = shpsData + 4 + headerLen;
    size_t encryptedDataLen = shpsSize - (4 + headerLen);

    unsigned char *decrypted = NULL;
    size_t decrypted_len = 0;
    if (!aes_gcm_decrypt(encryptedDataPtr, encryptedDataLen, aesKey, iv,
                         &decrypted, &decrypted_len))
    {
        free(aesKey);
        free(iv);
        result->error = strdup("AES decryption failed");
        return result;
    }
    free(aesKey);
    free(iv);

    if (progressCallback)
        progressCallback(80, userData);

    if (progressCallback)
        progressCallback(100, userData);

    result->data = decrypted;
    result->size = decrypted_len;
    return result;
}

void shirm_free_encrypt_result(EncryptResult *result)
{
    if (result)
    {
        if (result->data)
            free(result->data);
        if (result->error)
            free(result->error);
        free(result);
    }
}

void shirm_free_decrypt_result(DecryptResult *result)
{
    if (result)
    {
        if (result->data)
            free(result->data);
        if (result->error)
            free(result->error);
        free(result);
    }
}

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
    int enc_ok = rsa_oaep_encrypt(stream->aesKey, 32, pubKey, &encryptedKey, &encryptedKey_len);
    EVP_PKEY_free(pubKey);
    if (!enc_ok)
    {
        fclose(stream->inputFile);
        free(stream);
        if (error)
            *error = strdup("RSA encryption failed");
        return NULL;
    }

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
    stream->headerParsed = 0;
    stream->finished = 0;
    stream->zStreamInitialized = 0;

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
    {
        compressed = 1;
    }
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
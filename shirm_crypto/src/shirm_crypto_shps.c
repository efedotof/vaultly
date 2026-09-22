#include "shirm_crypto.h"
#include "internal/shirm_crypto_common.h"
#include <stdio.h>

unsigned char *build_header(const char *originalFileName,
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
    char *sigB64 = (signature && signature_len > 0) ? base64_encode(signature, signature_len) : NULL;
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
        pos += sprintf(json + pos, ",\"metadata\":{\"compressed\":\"true\"}");
    if (sigB64)
        pos += sprintf(json + pos, ",\"signature\":\"%s\"", sigB64);
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

EncryptResult *shirm_encrypt_file(const char *inputPath,
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
    if (!rsa_oaep_encrypt(aesKey, 32, pubKey, &encryptedKey, &encryptedKey_len))
    {
        EVP_PKEY_free(pubKey);
        free(dataToEncrypt);
        result->error = strdup("RSA encryption failed");
        return result;
    }
    EVP_PKEY_free(pubKey);
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

DecryptResult *shirm_decrypt_data(const unsigned char *shpsData,
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
        compressed = 1;
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
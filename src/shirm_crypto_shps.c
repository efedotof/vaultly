#include "shirm_crypto.h"
#include "internal/shirm_crypto_common.h"
#include "internal/shirm_crypto_shps_internal.h"
#include "jsmn/jsmn.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


char *shps_json_escape(const char *s)
{
    if (!s) s = "";
    size_t n = strlen(s);
    size_t cap = n * 6 + 1;
    char *out = (char *)malloc(cap);
    if (!out) return NULL;
    size_t j = 0;
    for (size_t i = 0; i < n; i++) {
        unsigned char c = (unsigned char)s[i];
        switch (c) {
        case '"':  out[j++] = '\\'; out[j++] = '"';  break;
        case '\\': out[j++] = '\\'; out[j++] = '\\'; break;
        case '\n': out[j++] = '\\'; out[j++] = 'n';  break;
        case '\r': out[j++] = '\\'; out[j++] = 'r';  break;
        case '\t': out[j++] = '\\'; out[j++] = 't';  break;
        case '\b': out[j++] = '\\'; out[j++] = 'b';  break;
        case '\f': out[j++] = '\\'; out[j++] = 'f';  break;
        default:
            if (c < 0x20) {
                j += (size_t)sprintf(out + j, "\\u%04x", c);
            } else {
                out[j++] = (char)c;
            }
        }
    }
    out[j] = '\0';
    return out;
}



static char *tok_to_cstr(const char *json, const jsmntok_t *t)
{
    size_t len = (size_t)(t->end - t->start);
    char *s = (char *)malloc(len + 1);
    if (!s) return NULL;
    memcpy(s, json + t->start, len);
    s[len] = '\0';
    return s;
}

static int tok_is_key(const char *json, const jsmntok_t *t, const char *key)
{
    size_t klen = strlen(key);
    return t->type == JSMN_STRING
        && (size_t)(t->end - t->start) == klen
        && memcmp(json + t->start, key, klen) == 0;
}

void shps_free_header(ShpsHeader *h)
{
    if (!h) return;
    free(h->encrypted_key_b64);
    free(h->iv_b64);
    h->encrypted_key_b64 = NULL;
    h->iv_b64 = NULL;
    h->compressed = 0;
}

int shps_parse_header(const char *json, size_t json_len,
                      ShpsHeader *out, char **error)
{
    memset(out, 0, sizeof(*out));

    jsmn_parser p;
    jsmn_init(&p);
    int ntok = jsmn_parse(&p, json, json_len, NULL, 0);
    if (ntok <= 0) {
        if (error) *error = strdup("Invalid JSON header");
        return 0;
    }
    jsmntok_t *toks = (jsmntok_t *)malloc((size_t)ntok * sizeof(jsmntok_t));
    if (!toks) { if (error) *error = strdup("malloc failed"); return 0; }
    jsmn_init(&p);
    int ret = jsmn_parse(&p, json, json_len, toks, (unsigned int)ntok);
    if (ret < 0 || toks[0].type != JSMN_OBJECT) {
        free(toks);
        if (error) *error = strdup("Invalid JSON header");
        return 0;
    }

    int found_key = 0, found_iv = 0;
    for (int i = 0; i < ntok - 1; i++) {
        if (toks[i].type != JSMN_STRING) continue;
        if (tok_is_key(json, &toks[i], "encryptedKey")) {
            if (toks[i + 1].type != JSMN_STRING) {
                if (error) *error = strdup("encryptedKey is not a string");
                goto fail;
            }
            out->encrypted_key_b64 = tok_to_cstr(json, &toks[i + 1]);
            if (!out->encrypted_key_b64) { if (error) *error = strdup("malloc failed"); goto fail; }
            found_key = 1;
        } else if (tok_is_key(json, &toks[i], "iv")) {
            if (toks[i + 1].type != JSMN_STRING) {
                if (error) *error = strdup("iv is not a string");
                goto fail;
            }
            out->iv_b64 = tok_to_cstr(json, &toks[i + 1]);
            if (!out->iv_b64) { if (error) *error = strdup("malloc failed"); goto fail; }
            found_iv = 1;
        } else if (tok_is_key(json, &toks[i], "compressed")) {
            int vlen = toks[i + 1].end - toks[i + 1].start;
            if (vlen == 4 && memcmp(json + toks[i + 1].start, "true", 4) == 0)
                out->compressed = 1;
        }
    }
    free(toks);
    if (!found_key || !found_iv) {
        if (error) *error = strdup("Missing required header fields");
        shps_free_header(out);
        return 0;
    }
    return 1;
fail:
    free(toks);
    shps_free_header(out);
    return 0;
}


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
    char *ivB64     = base64_encode(iv, 12);
    char *sigB64    = (signature && signature_len > 0)
                        ? base64_encode(signature, signature_len) : NULL;

    char *escName  = shps_json_escape(originalFileName ? originalFileName : "");
    char *escOwner = shps_json_escape(keyOwner ? keyOwner : "");
    char *escUser  = shps_json_escape(userId ? userId : "");
    if (!encKeyB64 || !ivB64 || !escName || !escOwner || !escUser) {
        free(encKeyB64); free(ivB64); free(sigB64);
        free(escName); free(escOwner); free(escUser);
        return NULL;
    }

    const char *comp_part = compressed
        ? ",\"metadata\":{\"compressed\":\"true\"}" : "";

    char *sig_block = NULL;
    const char *sig_part = "";
    if (sigB64) {
        size_t sl = strlen(sigB64) + 32;
        sig_block = (char *)malloc(sl);
        if (!sig_block) { free(encKeyB64); free(ivB64); free(sigB64);
                          free(escName); free(escOwner); free(escUser); return NULL; }
        snprintf(sig_block, sl, ",\"signature\":\"%s\"", sigB64);
        sig_part = sig_block;
    }

    int needed = snprintf(NULL, 0,
        "{\"version\":\"1.0\",\"algorithm\":\"AES-256-GCM\","
        "\"keyEncryption\":\"RSA-OAEP\",\"creationDate\":\"%s\","
        "\"originalFileName\":\"%s\",\"originalFileSize\":%zu,"
        "\"encryptedKey\":\"%s\",\"iv\":\"%s\","
        "\"keyOwner\":\"%s\",\"userId\":\"%s\"%s%s}",
        time_buf, escName, originalFileSize, encKeyB64, ivB64,
        escOwner, escUser, comp_part, sig_part);

    free(encKeyB64); free(ivB64); free(sigB64);
    free(escName); free(escOwner); free(escUser); free(sig_block);

    if (needed < 0) return NULL;

    char *json = (char *)malloc((size_t)needed + 1);
    if (!json) return NULL;

    char *encKeyB64b = base64_encode(encryptedKey, encryptedKey_len);
    char *ivB64b     = base64_encode(iv, 12);
    char *sigB64b    = (signature && signature_len > 0)
                        ? base64_encode(signature, signature_len) : NULL;
    char *escNameb   = shps_json_escape(originalFileName ? originalFileName : "");
    char *escOwnerb  = shps_json_escape(keyOwner ? keyOwner : "");
    char *escUserb   = shps_json_escape(userId ? userId : "");
    char *sig_blockb = NULL;
    const char *sig_partb = "";
    if (sigB64b) {
        size_t sl = strlen(sigB64b) + 32;
        sig_blockb = (char *)malloc(sl);
        if (sig_blockb) {
            snprintf(sig_blockb, sl, ",\"signature\":\"%s\"", sigB64b);
            sig_partb = sig_blockb;
        }
    }
    snprintf(json, (size_t)needed + 1,
        "{\"version\":\"1.0\",\"algorithm\":\"AES-256-GCM\","
        "\"keyEncryption\":\"RSA-OAEP\",\"creationDate\":\"%s\","
        "\"originalFileName\":\"%s\",\"originalFileSize\":%zu,"
        "\"encryptedKey\":\"%s\",\"iv\":\"%s\","
        "\"keyOwner\":\"%s\",\"userId\":\"%s\"%s%s}",
        time_buf, escNameb ? escNameb : "", originalFileSize,
        encKeyB64b ? encKeyB64b : "", ivB64b ? ivB64b : "",
        escOwnerb ? escOwnerb : "", escUserb ? escUserb : "",
        comp_part, sig_partb);

    free(encKeyB64b); free(ivB64b); free(sigB64b);
    free(escNameb); free(escOwnerb); free(escUserb); free(sig_blockb);

    size_t json_len = strlen(json);
    uint32_t net_len = htonl((uint32_t)json_len);
    unsigned char *result = (unsigned char *)malloc(4 + json_len);
    if (!result) { free(json); return NULL; }
    memcpy(result, &net_len, 4);
    memcpy(result + 4, json, json_len);
    free(json);
    *header_len = 4 + json_len;
    return result;
}


DecryptResult *shirm_decrypt_data(const unsigned char *shpsData,
                                  size_t shpsSize,
                                  const char *privateKeyPem,
                                  ProgressCallback progressCallback,
                                  void *userData)
{
    DecryptResult *result = (DecryptResult *)malloc(sizeof(DecryptResult));
    result->data = NULL; result->size = 0; result->error = NULL;

    if (shpsSize < 4) { result->error = strdup("Data too short"); return result; }

    uint32_t headerLen_net;
    memcpy(&headerLen_net, shpsData, 4);
    uint32_t headerLen = ntohl(headerLen_net);
    if (headerLen > 20 * 1024 || shpsSize < 4 + headerLen) {
        result->error = strdup("Invalid header");
        return result;
    }

    char *jsonStr = (char *)malloc(headerLen + 1);
    memcpy(jsonStr, shpsData + 4, headerLen);
    jsonStr[headerLen] = '\0';

    ShpsHeader hdr;
    char *parse_err = NULL;
    if (!shps_parse_header(jsonStr, headerLen, &hdr, &parse_err)) {
        free(jsonStr);
        result->error = parse_err ? parse_err : strdup("Bad header");
        return result;
    }
    free(jsonStr);

    if (progressCallback) progressCallback(10, userData);

    size_t encKey_len = 0;
    unsigned char *encryptedKey = base64_decode(hdr.encrypted_key_b64, &encKey_len);
    size_t iv_len = 0;
    unsigned char *iv = base64_decode(hdr.iv_b64, &iv_len);
    if (!encryptedKey || !iv || iv_len != 12) {
        free(encryptedKey); free(iv); shps_free_header(&hdr);
        result->error = strdup("Invalid header fields");
        return result;
    }

    EVP_PKEY *privKey = load_private_key_from_pem(privateKeyPem);
    if (!privKey) {
        free(encryptedKey); free(iv); shps_free_header(&hdr);
        result->error = strdup("Failed to load private key");
        return result;
    }

    unsigned char *aesKey = NULL;
    size_t aesKey_len = 0;
    int dec_ok = rsa_oaep_decrypt(encryptedKey, encKey_len, privKey, &aesKey, &aesKey_len);
    if (!dec_ok)
        dec_ok = rsa_oaep_decrypt_sha1(encryptedKey, encKey_len, privKey, &aesKey, &aesKey_len);
    EVP_PKEY_free(privKey);
    free(encryptedKey);
    if (!dec_ok || aesKey_len != 32) {
        free(iv); shps_free_header(&hdr); free(aesKey);
        result->error = strdup("RSA decryption failed");
        return result;
    }

    if (progressCallback) progressCallback(20, userData);

    const unsigned char *ct = shpsData + 4 + headerLen;
    size_t ctLen = shpsSize - (4 + headerLen);
    unsigned char *decrypted = NULL;
    size_t decrypted_len = 0;
    if (!aes_gcm_decrypt(ct, ctLen, aesKey, iv, &decrypted, &decrypted_len)) {
        free(aesKey); free(iv); shps_free_header(&hdr);
        result->error = strdup("AES decryption failed");
        return result;
    }
    free(aesKey); free(iv);

    if (hdr.compressed) {
        unsigned char *plain = NULL;
        size_t plain_len = 0;
        if (!gzip_decompress(decrypted, decrypted_len, &plain, &plain_len)) {
            free(decrypted); shps_free_header(&hdr);
            result->error = strdup("Decompression failed");
            return result;
        }
        free(decrypted);
        decrypted = plain;
        decrypted_len = plain_len;
    }
    shps_free_header(&hdr);

    if (progressCallback) progressCallback(100, userData);

    result->data = decrypted;
    result->size = decrypted_len;
    return result;
}

void shirm_free_encrypt_result(EncryptResult *result)
{
    if (result) {
        free(result->data); free(result->error); free(result);
    }
}
void shirm_free_decrypt_result(DecryptResult *result)
{
    if (result) {
        free(result->data); free(result->error); free(result);
    }
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
    if (!fileData) {
        result->error = strdup("Cannot open file");
        return result;
    }
    size_t originalSize = file_size;

    if (progressCallback) progressCallback(5, userData);

    unsigned char *dataToEncrypt = fileData;
    size_t dataToEncrypt_len = file_size;
    unsigned char *compressedData = NULL;
    size_t compressed_len = 0;
    if (compress) {
        if (!gzip_compress(fileData, file_size, &compressedData, &compressed_len)) {
            free(fileData);
            result->error = strdup("Compression failed");
            return result;
        }
        free(fileData);
        dataToEncrypt = compressedData;
        dataToEncrypt_len = compressed_len;
        if (progressCallback) progressCallback(10, userData);
    }

    unsigned char aesKey[32], iv[12];
    if (!generate_random_bytes(aesKey, 32) ||
        !generate_random_bytes(iv, 12)) {
        free(dataToEncrypt);
        result->error = strdup("Failed to generate random bytes");
        return result;
    }

    EVP_PKEY *pubKey = load_public_key_from_pem(publicKeyPem);
    if (!pubKey) {
        free(dataToEncrypt);
        result->error = strdup("Failed to load public key");
        return result;
    }

    unsigned char *encryptedKey = NULL;
    size_t encryptedKey_len = 0;
    if (!rsa_oaep_encrypt(aesKey, 32, pubKey, &encryptedKey, &encryptedKey_len)) {
        EVP_PKEY_free(pubKey);
        free(dataToEncrypt);
        result->error = strdup("RSA encryption failed");
        return result;
    }
    EVP_PKEY_free(pubKey);

    unsigned char *signature = NULL;
    size_t signature_len = 0;
    if (privateKeyPem && *privateKeyPem) {
        EVP_PKEY *privKey = load_private_key_from_pem(privateKeyPem);
        if (privKey) {
            rsa_sign(dataToEncrypt, dataToEncrypt_len, privKey,
                     &signature, &signature_len);
            EVP_PKEY_free(privKey);
        }
    }

    if (progressCallback) progressCallback(20, userData);

    unsigned char *encryptedData = NULL;
    size_t encryptedData_len = 0;
    if (!aes_gcm_encrypt(dataToEncrypt, dataToEncrypt_len, aesKey, iv,
                         &encryptedData, &encryptedData_len)) {
        free(dataToEncrypt);
        free(encryptedKey);
        if (signature) free(signature);
        result->error = strdup("AES encryption failed");
        return result;
    }
    free(dataToEncrypt);

    if (progressCallback) progressCallback(80, userData);

    const char *origName = originalFileName ? originalFileName : "";
    size_t header_len = 0;
    unsigned char *header = build_header(
        origName, originalSize,
        encryptedKey, encryptedKey_len,
        iv, keyOwner, userId, compress,
        signature, signature_len,
        &header_len);
    free(encryptedKey);
    if (signature) free(signature);
    if (!header) {
        free(encryptedData);
        result->error = strdup("Failed to build header");
        return result;
    }

    unsigned char *finalData = (unsigned char *)malloc(header_len + encryptedData_len);
    if (!finalData) {
        free(header); free(encryptedData);
        result->error = strdup("malloc failed");
        return result;
    }
    memcpy(finalData, header, header_len);
    memcpy(finalData + header_len, encryptedData, encryptedData_len);
    free(header);
    free(encryptedData);

    if (progressCallback) progressCallback(100, userData);

    result->data = finalData;
    result->size = header_len + encryptedData_len;
    return result;
}
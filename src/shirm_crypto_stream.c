#include "shirm_crypto.h"
#include "internal/shirm_crypto_common.h"
#include "internal/shirm_crypto_shps_internal.h"
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
    int eofReached;
    int zFinishDone;
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
    ShirmEncryptStream *stream =
        (ShirmEncryptStream *)calloc(1, sizeof(ShirmEncryptStream));
    if (!stream) { if (error) *error = strdup("Memory allocation failed"); return NULL; }

    stream->compress = compress;
    stream->progressCallback = progressCallback;
    stream->userData = userData;
    stream->readBufferSize = 1024 * 1024;

    stream->inputFile = fopen(inputPath, "rb");
    if (!stream->inputFile) {
        free(stream);
        if (error) *error = strdup("Cannot open input file");
        return NULL;
    }
    fseek(stream->inputFile, 0, SEEK_END);
    long fsz = ftell(stream->inputFile);
    if (fsz < 0) fsz = 0;
    stream->originalSize = (size_t)fsz;
    fseek(stream->inputFile, 0, SEEK_SET);

    if (!generate_random_bytes(stream->aesKey, 32) ||
        !generate_random_bytes(stream->iv, 12)) {
        fclose(stream->inputFile); free(stream);
        if (error) *error = strdup("Failed to generate random bytes");
        return NULL;
    }

    EVP_PKEY *pubKey = load_public_key_from_pem_cached(publicKeyPem);
    if (!pubKey) {
        fclose(stream->inputFile); free(stream);
        if (error) *error = strdup("Failed to load public key");
        return NULL;
    }

    unsigned char *encKey = NULL;
    size_t encKey_len = 0;
    if (!rsa_oaep_encrypt(stream->aesKey, 32, pubKey, &encKey, &encKey_len)) {
        EVP_PKEY_free(pubKey);
        fclose(stream->inputFile); free(stream);
        if (error) *error = strdup("RSA encryption failed");
        return NULL;
    }
    EVP_PKEY_free(pubKey);

    (void)privateKeyPem;

    const char *origName = originalFileName ? originalFileName : "";
    stream->headerData = build_header(
        origName, stream->originalSize, encKey, encKey_len,
        stream->iv, keyOwner, userId, compress,
        NULL, 0, &stream->headerSize);
    free(encKey);
    if (!stream->headerData) {
        fclose(stream->inputFile); free(stream);
        if (error) *error = strdup("Failed to build header");
        return NULL;
    }

    stream->cipherCtx = EVP_CIPHER_CTX_new();
    if (!stream->cipherCtx ||
        EVP_EncryptInit_ex(stream->cipherCtx, EVP_aes_256_gcm(), NULL,
                           stream->aesKey, stream->iv) != 1) {
        free(stream->headerData);
        if (stream->cipherCtx) EVP_CIPHER_CTX_free(stream->cipherCtx);
        fclose(stream->inputFile); free(stream);
        if (error) *error = strdup("EVP init failed");
        return NULL;
    }

    stream->readBuffer = (unsigned char *)malloc(stream->readBufferSize);
    if (!stream->readBuffer) {
        free(stream->headerData);
        EVP_CIPHER_CTX_free(stream->cipherCtx);
        fclose(stream->inputFile); free(stream);
        if (error) *error = strdup("Read buffer allocation failed");
        return NULL;
    }

    if (compress) {
        stream->compressBufferSize = stream->readBufferSize * 2;
        stream->compressBuffer = (unsigned char *)malloc(stream->compressBufferSize);
        if (!stream->compressBuffer) {
            free(stream->headerData); free(stream->readBuffer);
            EVP_CIPHER_CTX_free(stream->cipherCtx);
            fclose(stream->inputFile); free(stream);
            if (error) *error = strdup("Compress buffer allocation failed");
            return NULL;
        }
        memset(&stream->zStream, 0, sizeof(z_stream));
        if (deflateInit2(&stream->zStream, Z_DEFAULT_COMPRESSION, Z_DEFLATED,
                         16 + MAX_WBITS, 8, Z_DEFAULT_STRATEGY) != Z_OK) {
            free(stream->headerData); free(stream->readBuffer);
            free(stream->compressBuffer);
            EVP_CIPHER_CTX_free(stream->cipherCtx);
            fclose(stream->inputFile); free(stream);
            if (error) *error = strdup("deflateInit2 failed");
            return NULL;
        }
        stream->zStreamInitialized = 1;
    }

    return stream;
}

int shirm_encrypt_stream_process(
    ShirmEncryptStream *stream,
    uint8_t **out_chunk,
    size_t *out_chunk_size,
    char **error)
{
    if (!stream || !out_chunk || !out_chunk_size) return -1;

    while (1) {
        if (!stream->headerWritten) {
            *out_chunk = (uint8_t *)malloc(stream->headerSize);
            if (!*out_chunk) { if (error) *error = strdup("malloc failed"); return -1; }
            memcpy(*out_chunk, stream->headerData, stream->headerSize);
            *out_chunk_size = stream->headerSize;
            stream->headerWritten = 1;
            return 1;
        }

        if (stream->finished) return 0;

        if (stream->eofReached) {
            if (stream->compress && stream->zStreamInitialized && !stream->zFinishDone) {
                stream->zStream.next_out = stream->compressBuffer;
                stream->zStream.avail_out = (uInt)stream->compressBufferSize;
                int zret = deflate(&stream->zStream, Z_FINISH);
                if (zret != Z_STREAM_END) {
                    if (error) *error = strdup("deflate(Z_FINISH) failed");
                    return -1;
                }
                size_t produced =
                    stream->compressBufferSize - stream->zStream.avail_out;
                stream->zFinishDone = 1;

                if (produced > 0) {
                    int outLen = (int)produced + EVP_MAX_BLOCK_LENGTH;
                    unsigned char *encBuf = (unsigned char *)malloc(outLen);
                    if (!encBuf) { if (error) *error = strdup("malloc failed"); return -1; }
                    int encLen = 0;
                    if (EVP_EncryptUpdate(stream->cipherCtx, encBuf, &encLen,
                                          stream->compressBuffer, (int)produced) != 1) {
                        free(encBuf);
                        if (error) *error = strdup("EVP_EncryptUpdate failed");
                        return -1;
                    }
                    *out_chunk = encBuf;
                    *out_chunk_size = (size_t)encLen;
                    return 1;
                }
            }

            unsigned char finalBuf[EVP_MAX_BLOCK_LENGTH];
            int finalLen = 0;
            if (EVP_EncryptFinal_ex(stream->cipherCtx, finalBuf, &finalLen) != 1) {
                if (error) *error = strdup("EVP_EncryptFinal_ex failed");
                return -1;
            }
            unsigned char tag[16];
            if (EVP_CIPHER_CTX_ctrl(stream->cipherCtx, EVP_CTRL_GCM_GET_TAG,
                                    16, tag) != 1) {
                if (error) *error = strdup("Failed to get GCM tag");
                return -1;
            }
            size_t total = (size_t)finalLen + 16;
            *out_chunk = (uint8_t *)malloc(total);
            if (!*out_chunk) { if (error) *error = strdup("malloc failed"); return -1; }
            memcpy(*out_chunk, finalBuf, finalLen);
            memcpy(*out_chunk + finalLen, tag, 16);
            *out_chunk_size = total;
            stream->finished = 1;
            if (stream->progressCallback)
                stream->progressCallback(100, stream->userData);
            return 1;
        }

        size_t bytesRead = fread(stream->readBuffer, 1, stream->readBufferSize,
                                 stream->inputFile);
        if (bytesRead == 0) {
            stream->eofReached = 1;
            continue;
        }

        stream->totalRead += bytesRead;
        unsigned char *toEnc = stream->readBuffer;
        size_t toEnc_len = bytesRead;

        if (stream->compress) {
            stream->zStream.next_in = stream->readBuffer;
            stream->zStream.avail_in = (uInt)bytesRead;
            stream->zStream.next_out = stream->compressBuffer;
            stream->zStream.avail_out = (uInt)stream->compressBufferSize;
            int zret = deflate(&stream->zStream, Z_SYNC_FLUSH);
            if (zret < 0) {
                if (error) *error = strdup("deflate failed");
                return -1;
            }
            toEnc = stream->compressBuffer;
            toEnc_len = stream->compressBufferSize - stream->zStream.avail_out;
        }

        int outLen = (int)toEnc_len + EVP_MAX_BLOCK_LENGTH;
        unsigned char *encBuf = (unsigned char *)malloc(outLen);
        if (!encBuf) { if (error) *error = strdup("malloc failed"); return -1; }
        int encLen = 0;
        if (EVP_EncryptUpdate(stream->cipherCtx, encBuf, &encLen,
                              toEnc, (int)toEnc_len) != 1) {
            free(encBuf);
            if (error) *error = strdup("EVP_EncryptUpdate failed");
            return -1;
        }

        *out_chunk = encBuf;
        *out_chunk_size = (size_t)encLen;

        if (stream->progressCallback && stream->originalSize > 0) {
            int percent = (int)(stream->totalRead * 100 / stream->originalSize);
            if (percent > 100) percent = 100;
            stream->progressCallback(percent, stream->userData);
        }
        return 1;
    }
}

void shirm_encrypt_stream_free(ShirmEncryptStream *stream)
{
    if (!stream) return;
    if (stream->inputFile) fclose(stream->inputFile);
    if (stream->cipherCtx) EVP_CIPHER_CTX_free(stream->cipherCtx);
    free(stream->headerData);
    free(stream->readBuffer);
    free(stream->compressBuffer);
    if (stream->zStreamInitialized) deflateEnd(&stream->zStream);
    free(stream);
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
    int inflateDone;
    const unsigned char *tagPtr;
    int authDone;
    unsigned char *outBuf;
    size_t outBufSize;
    size_t outBufCap;
    ProgressCallback progressCallback;
    void *userData;
    size_t totalProcessed;
    size_t totalEncryptedSize;
};

static int decrypt_inflate_append(ShirmDecryptStream *s,
                                  const unsigned char *in, size_t in_len,
                                  char **error)
{
    while (in_len > 0) {
        if (s->outBufCap - s->outBufSize < 65536) {
            size_t nc = s->outBufCap ? s->outBufCap * 2 : 65536;
            unsigned char *nb = (unsigned char *)realloc(s->outBuf, nc);
            if (!nb) { if (error) *error = strdup("realloc failed"); return 0; }
            s->outBuf = nb; s->outBufCap = nc;
        }
        s->zStream.next_in  = (Bytef *)in;
        s->zStream.avail_in = (uInt)in_len;
        s->zStream.next_out = s->outBuf + s->outBufSize;
        s->zStream.avail_out = (uInt)(s->outBufCap - s->outBufSize);

        int zret = inflate(&s->zStream, Z_NO_FLUSH);
        size_t produced = (s->outBufCap - s->outBufSize) - s->zStream.avail_out;
        size_t consumed = in_len - s->zStream.avail_in;

        s->outBufSize += produced;
        in      += consumed;
        in_len  -= consumed;

        if (zret == Z_STREAM_END) { s->inflateDone = 1; break; }
        if (zret != Z_OK && zret != Z_BUF_ERROR) {
            if (error) *error = strdup("inflate failed");
            return 0;
        }
        if (consumed == 0 && produced == 0) {
            if (error) *error = strdup("inflate stalled");
            return 0;
        }
    }
    return 1;
}

ShirmDecryptStream *shirm_decrypt_stream_init(
    const unsigned char *shpsData,
    size_t shpsSize,
    const char *privateKeyPem,
    ProgressCallback progressCallback,
    void *userData,
    char **error)
{
    if (shpsSize < 4) { if (error) *error = strdup("Data too short"); return NULL; }

    ShirmDecryptStream *s = (ShirmDecryptStream *)calloc(1, sizeof(*s));
    if (!s) { if (error) *error = strdup("Memory allocation failed"); return NULL; }

    s->inputData = shpsData;
    s->inputSize = shpsSize;
    s->progressCallback = progressCallback;
    s->userData = userData;

    uint32_t hlen_net;
    memcpy(&hlen_net, shpsData, 4);
    uint32_t hlen = ntohl(hlen_net);
    if (hlen > 20 * 1024 || shpsSize < 4 + hlen) {
        free(s);
        if (error) *error = strdup("Invalid header");
        return NULL;
    }

    if (shpsSize < (size_t)4 + hlen + 16) {
        free(s);
        if (error) *error = strdup("Data too short (missing GCM tag)");
        return NULL;
    }

    char *jsonStr = (char *)malloc(hlen + 1);
    memcpy(jsonStr, shpsData + 4, hlen);
    jsonStr[hlen] = '\0';

    ShpsHeader hdr;
    char *perr = NULL;
    if (!shps_parse_header(jsonStr, hlen, &hdr, &perr)) {
        free(jsonStr); free(s);
        if (error) *error = perr ? perr : strdup("Bad header");
        return NULL;
    }
    free(jsonStr);
    s->compressed = hdr.compressed;

    size_t encKey_len = 0;
    unsigned char *encKey = base64_decode(hdr.encrypted_key_b64, &encKey_len);
    size_t iv_len = 0;
    unsigned char *iv = base64_decode(hdr.iv_b64, &iv_len);
    if (!encKey || !iv || iv_len != 12) {
        free(encKey); free(iv); shps_free_header(&hdr); free(s);
        if (error) *error = strdup("Invalid header fields");
        return NULL;
    }

    EVP_PKEY *priv = load_private_key_from_pem_cached(privateKeyPem);
    if (!priv) {
        free(encKey); free(iv); shps_free_header(&hdr); free(s);
        if (error) *error = strdup("Failed to load private key");
        return NULL;
    }

    unsigned char *aesKey = NULL;
    size_t aesKey_len = 0;
    int ok = rsa_oaep_decrypt(encKey, encKey_len, priv, &aesKey, &aesKey_len);
    if (!ok) ok = rsa_oaep_decrypt_sha1(encKey, encKey_len, priv, &aesKey, &aesKey_len);
    EVP_PKEY_free(priv);
    free(encKey);
    if (!ok || aesKey_len != 32) {
        free(iv); free(aesKey); shps_free_header(&hdr); free(s);
        if (error) *error = strdup("RSA decryption failed");
        return NULL;
    }

    s->cipherCtx = EVP_CIPHER_CTX_new();
    if (!s->cipherCtx ||
        EVP_DecryptInit_ex(s->cipherCtx, EVP_aes_256_gcm(), NULL,
                           aesKey, iv) != 1) {
        free(aesKey); free(iv); shps_free_header(&hdr);
        if (s->cipherCtx) EVP_CIPHER_CTX_free(s->cipherCtx);
        free(s);
        if (error) *error = strdup("EVP init failed");
        return NULL;
    }
    free(aesKey); free(iv);
    shps_free_header(&hdr);

    if (s->compressed) {
        memset(&s->zStream, 0, sizeof(z_stream));
        if (inflateInit2(&s->zStream, 47) != Z_OK) {
            EVP_CIPHER_CTX_free(s->cipherCtx); free(s);
            if (error) *error = strdup("inflateInit2 failed");
            return NULL;
        }
        s->zStreamInitialized = 1;
    }

    s->inputOffset = 4 + hlen;
    s->headerParsed = 1;
    s->finished = 0;
    s->tagPtr = shpsData + shpsSize - 16; 
    s->totalEncryptedSize = shpsSize - (4 + hlen);

    if (progressCallback) progressCallback(10, userData);
    return s;
}

int shirm_decrypt_stream_process(
    ShirmDecryptStream *s,
    uint8_t **out_chunk,
    size_t *out_chunk_size,
    char **error)
{
    if (!s || !out_chunk || !out_chunk_size) return -1;
    if (!s->headerParsed) {
        if (error) *error = strdup("Stream not initialized");
        return -1;
    }

    if (s->outBufSize > 0) {
        *out_chunk = s->outBuf;
        *out_chunk_size = s->outBufSize;
        s->outBuf = NULL;
        s->outBufSize = 0;
        s->outBufCap = 0;
        return 1;
    }

    if (s->finished) return 0;

    while (1) {
        size_t remaining = s->inputSize - s->inputOffset;
        if (remaining == 0) {
            if (!s->authDone) {
                if (EVP_CIPHER_CTX_ctrl(s->cipherCtx, EVP_CTRL_GCM_SET_TAG,
                                        16, (void *)s->tagPtr) != 1) {
                    if (error) *error = strdup("Failed to set GCM tag");
                    return -1;
                }
                s->authDone = 1;
            }

            unsigned char finalBuf[EVP_MAX_BLOCK_LENGTH];
            int finalLen = 0;
            if (EVP_DecryptFinal_ex(s->cipherCtx, finalBuf, &finalLen) != 1) {
                if (error) *error = strdup("EVP_DecryptFinal_ex failed (authentication failed)");
                return -1;
            }

            if (s->compressed) {
                if (finalLen > 0 && !s->inflateDone) {
                    if (!decrypt_inflate_append(s, finalBuf, (size_t)finalLen, error))
                        return -1;
                }

                while (!s->inflateDone) {
                    if (s->outBufCap - s->outBufSize < 65536) {
                        size_t nc = s->outBufCap ? s->outBufCap * 2 : 65536;
                        unsigned char *nb = (unsigned char *)realloc(s->outBuf, nc);
                        if (!nb) { if (error) *error = strdup("realloc failed"); return -1; }
                        s->outBuf = nb; s->outBufCap = nc;
                    }
                    s->zStream.next_in  = NULL;
                    s->zStream.avail_in = 0;
                    s->zStream.next_out = s->outBuf + s->outBufSize;
                    s->zStream.avail_out = (uInt)(s->outBufCap - s->outBufSize);

                    int zret = inflate(&s->zStream, Z_FINISH);
                    size_t produced = (s->outBufCap - s->outBufSize) - s->zStream.avail_out;
                    s->outBufSize += produced;

                
                    if (zret == Z_STREAM_END) { s->inflateDone = 1; break; }
                    if (zret == Z_BUF_ERROR) {
                        if (produced == 0) {
                            if (error) *error = strdup("inflate finish failed (truncated stream)");
                            return -1;
                        }
                        continue; 
                    }
                    if (zret != Z_OK) {
                        if (error) *error = strdup("inflate finish failed");
                        return -1;
                    }
                    if (produced == 0) {
                        if (error) *error = strdup("inflate finish stalled");
                        return -1;
                    }
                }
            }

            s->finished = 1;
            if (s->progressCallback)
                s->progressCallback(100, s->userData);

            if (s->outBufSize > 0) {
                *out_chunk = s->outBuf;
                *out_chunk_size = s->outBufSize;
                s->outBuf = NULL;
                s->outBufSize = 0;
                s->outBufCap = 0;
                return 1;
            }
            return 0;
        }

        size_t chunkSize = remaining > (1024 * 1024) ? 1024 * 1024 : remaining;
        int isLast = ((size_t)chunkSize == remaining);


        if (isLast && chunkSize < 16) {
            if (error) *error = strdup("Data too short (truncated ciphertext)");
            return -1;
        }

        size_t updateSize = isLast ? (chunkSize - 16) : chunkSize;

        if (updateSize == 0) {
            s->inputOffset += remaining;
            continue;
        }

        unsigned char *decBuf = (unsigned char *)malloc(updateSize + EVP_MAX_BLOCK_LENGTH);
        if (!decBuf) { if (error) *error = strdup("malloc failed"); return -1; }
        int decLen = 0;
        if (EVP_DecryptUpdate(s->cipherCtx, decBuf, &decLen,
                              s->inputData + s->inputOffset, (int)updateSize) != 1) {
            free(decBuf);
            if (error) *error = strdup("EVP_DecryptUpdate failed");
            return -1;
        }
        s->inputOffset   += updateSize;
        s->totalProcessed += updateSize;

        if (s->progressCallback) {
            int percent = (int)(s->totalProcessed * 100 / s->totalEncryptedSize);
            if (percent > 100) percent = 100;
            s->progressCallback(percent, s->userData);
        }

        if (s->compressed) {
            int ok = decrypt_inflate_append(s, decBuf, (size_t)decLen, error);
            free(decBuf);
            if (!ok) return -1;

            if (s->outBufSize > 0) {
                *out_chunk = s->outBuf;
                *out_chunk_size = s->outBufSize;
                s->outBuf = NULL;
                s->outBufSize = 0;
                s->outBufCap = 0;
                return 1;
            }
            continue;
        }

        *out_chunk = decBuf;
        *out_chunk_size = (size_t)decLen;
        return 1;
    }
}

void shirm_decrypt_stream_free(ShirmDecryptStream *s)
{
    if (!s) return;
    if (s->cipherCtx)         EVP_CIPHER_CTX_free(s->cipherCtx);
    if (s->zStreamInitialized) inflateEnd(&s->zStream);
    free(s->outBuf);
    free(s);
}
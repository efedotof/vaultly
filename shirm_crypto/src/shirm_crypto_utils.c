#include "shirm_crypto.h"
#include "internal/shirm_crypto_common.h"
#include <openssl/err.h>
#include <openssl/rand.h>
#include <zlib.h>

void current_iso8601(char *buffer, size_t buffer_size)
{
    time_t t = time(NULL);
    struct tm *tm = gmtime(&t);
    strftime(buffer, buffer_size, "%Y-%m-%dT%H:%M:%SZ", tm);
}

char *base64_encode(const unsigned char *data, size_t len)
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

unsigned char *base64_decode(const char *encoded, size_t *out_len)
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

int generate_random_bytes(unsigned char *buf, size_t len)
{
    return RAND_bytes(buf, (int)len) == 1;
}

EVP_PKEY *load_public_key_from_pem(const char *pem)
{
    BIO *bio = BIO_new_mem_buf(pem, -1);
    if (!bio)
        return NULL;
    EVP_PKEY *key = PEM_read_bio_PUBKEY(bio, NULL, NULL, NULL);
    BIO_free(bio);
    return key;
}

EVP_PKEY *load_private_key_from_pem(const char *pem)
{
    BIO *bio = BIO_new_mem_buf(pem, -1);
    if (!bio)
        return NULL;
    EVP_PKEY *key = PEM_read_bio_PrivateKey(bio, NULL, NULL, NULL);
    BIO_free(bio);
    return key;
}

int rsa_oaep_encrypt(const unsigned char *plaintext, size_t plaintext_len,
                     EVP_PKEY *pubkey, unsigned char **out, size_t *out_len)
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

int rsa_oaep_decrypt_sha1(const unsigned char *ciphertext, size_t ciphertext_len,
                          EVP_PKEY *privkey, unsigned char **out, size_t *out_len)
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

int rsa_oaep_decrypt(const unsigned char *ciphertext, size_t ciphertext_len,
                     EVP_PKEY *privkey, unsigned char **out, size_t *out_len)
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

int rsa_sign(const unsigned char *data, size_t data_len, EVP_PKEY *privkey,
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

int gzip_compress(const unsigned char *input, size_t input_len,
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

int gzip_decompress(const unsigned char *input, size_t input_len,
                    unsigned char **out, size_t *out_len)
{
    z_stream zs;
    memset(&zs, 0, sizeof(zs));
    int ret = inflateInit2(&zs, 47);
    if (ret != Z_OK)
        return 0;
    zs.next_in = (Bytef *)input;
    zs.avail_in = (uInt)input_len;
    size_t capacity = input_len * 2;
    if (capacity < 256 * 1024)
        capacity = 256 * 1024;
    unsigned char *buf = (unsigned char *)malloc(capacity);
    if (!buf)
    {
        inflateEnd(&zs);
        return 0;
    }
    size_t total = 0;
    do
    {
        if (capacity - total < 16 * 1024)
        {
            capacity *= 2;
            unsigned char *new_buf = (unsigned char *)realloc(buf, capacity);
            if (!new_buf)
            {
                free(buf);
                inflateEnd(&zs);
                return 0;
            }
            buf = new_buf;
        }
        zs.next_out = buf + total;
        zs.avail_out = (uInt)(capacity - total);
        ret = inflate(&zs, Z_NO_FLUSH);
        total = capacity - zs.avail_out;
        if (ret == Z_STREAM_END)
            break;
        if (ret == Z_NEED_DICT)
        {
            ret = Z_DATA_ERROR;
            break;
        }
        if (ret == Z_DATA_ERROR || ret == Z_MEM_ERROR)
            break;
        if (ret != Z_OK && ret != Z_BUF_ERROR)
            break;
        if (zs.avail_in == 0 && ret == Z_OK)
        {
            ret = Z_DATA_ERROR;
            break;
        }
    } while (zs.avail_in > 0 || ret == Z_BUF_ERROR);
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

unsigned char *read_file(const char *path, size_t *size)
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

int aes_gcm_encrypt(const unsigned char *plaintext, size_t plaintext_len,
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

int aes_gcm_decrypt(const unsigned char *ciphertext, size_t ciphertext_len,
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

unsigned char *aes_gcm_encrypt_simple(const unsigned char *plain, size_t plain_len,
                                      const unsigned char *key, const unsigned char *nonce,
                                      size_t *out_len)
{
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx)
        return NULL;
    if (EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, key, nonce) != 1)
    {
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }
    EVP_CIPHER_CTX_set_padding(ctx, 0);

    unsigned char *buf = (unsigned char *)malloc(plain_len + 16);
    if (!buf)
    {
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }
    int len = 0;
    if (EVP_EncryptUpdate(ctx, buf, &len, plain, (int)plain_len) != 1)
    {
        free(buf);
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }
    int tmp = 0;
    if (EVP_EncryptFinal_ex(ctx, buf + len, &tmp) != 1)
    {
        free(buf);
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }
    len += tmp;
    unsigned char tag[16];
    if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, tag) != 1)
    {
        free(buf);
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }
    memcpy(buf + len, tag, 16);
    *out_len = len + 16;
    EVP_CIPHER_CTX_free(ctx);
    return buf;
}

unsigned char *aes_gcm_decrypt_simple(const unsigned char *cipher, size_t cipher_len,
                                      const unsigned char *key, const unsigned char *nonce,
                                      size_t *out_len)
{
    if (cipher_len < 16)
        return NULL;
    size_t tag_offset = cipher_len - 16;

    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx)
        return NULL;
    if (EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, key, nonce) != 1)
    {
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }
    EVP_CIPHER_CTX_set_padding(ctx, 0);

    unsigned char *buf = (unsigned char *)malloc(tag_offset);
    if (!buf)
    {
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }
    int len = 0;
    if (EVP_DecryptUpdate(ctx, buf, &len, cipher, (int)tag_offset) != 1)
    {
        free(buf);
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }
    if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16, (void *)(cipher + tag_offset)) != 1)
    {
        free(buf);
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }
    int tmp = 0;
    if (EVP_DecryptFinal_ex(ctx, buf + len, &tmp) != 1)
    {
        free(buf);
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }
    len += tmp;
    *out_len = len;
    EVP_CIPHER_CTX_free(ctx);
    return buf;
}
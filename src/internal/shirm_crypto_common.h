#ifndef SHIRM_CRYPTO_COMMON_H
#define SHIRM_CRYPTO_COMMON_H

#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <openssl/evp.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <openssl/err.h>
#include <zlib.h>
#ifdef _WIN32
  #include <winsock2.h>   
#else
  #include <arpa/inet.h>  /
#endif

void current_iso8601(char *buffer, size_t buffer_size);
char *base64_encode(const unsigned char *data, size_t len);
unsigned char *base64_decode(const char *encoded, size_t *out_len);
int generate_random_bytes(unsigned char *buf, size_t len);

EVP_PKEY *load_public_key_from_pem(const char *pem);
EVP_PKEY *load_private_key_from_pem(const char *pem);
int rsa_oaep_encrypt(const unsigned char *plaintext, size_t plaintext_len,
                     EVP_PKEY *pubkey, unsigned char **out, size_t *out_len);
int rsa_oaep_decrypt_sha1(const unsigned char *ciphertext, size_t ciphertext_len,
                          EVP_PKEY *privkey, unsigned char **out, size_t *out_len);
int rsa_oaep_decrypt(const unsigned char *ciphertext, size_t ciphertext_len,
                     EVP_PKEY *privkey, unsigned char **out, size_t *out_len);
int rsa_sign(const unsigned char *data, size_t data_len, EVP_PKEY *privkey,
             unsigned char **sig, size_t *sig_len);

int gzip_compress(const unsigned char *input, size_t input_len,
                  unsigned char **out, size_t *out_len);
int gzip_decompress(const unsigned char *input, size_t input_len,
                    unsigned char **out, size_t *out_len);

unsigned char *read_file(const char *path, size_t *size);

int aes_gcm_encrypt(const unsigned char *plaintext, size_t plaintext_len,
                    const unsigned char *key, const unsigned char *iv,
                    unsigned char **out, size_t *out_len);
int aes_gcm_decrypt(const unsigned char *ciphertext, size_t ciphertext_len,
                    const unsigned char *key, const unsigned char *iv,
                    unsigned char **out, size_t *out_len);

unsigned char *aes_gcm_encrypt_simple(const unsigned char *plain, size_t plain_len,
                                      const unsigned char *key, const unsigned char *nonce,
                                      size_t *out_len);
unsigned char *aes_gcm_decrypt_simple(const unsigned char *cipher, size_t cipher_len,
                                      const unsigned char *key, const unsigned char *nonce,
                                      size_t *out_len);

unsigned char *build_header(const char *originalFileName,
                            size_t originalFileSize,
                            const unsigned char *encryptedKey, size_t encryptedKey_len,
                            const unsigned char *iv,
                            const char *keyOwner,
                            const char *userId,
                            int compressed,
                            const unsigned char *signature, size_t signature_len,
                            size_t *header_len);

#endif
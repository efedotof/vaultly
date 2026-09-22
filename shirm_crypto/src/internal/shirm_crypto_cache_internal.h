#ifndef SHIRM_CRYPTO_CACHE_INTERNAL_H
#define SHIRM_CRYPTO_CACHE_INTERNAL_H

#include <sqlite3.h>

typedef struct ShirmCache {
    sqlite3 *db;
    char *cache_dir;
} ShirmCache;

void generate_key_nonce(unsigned char *key, unsigned char *nonce);
void create_directory(const char *path);

#endif
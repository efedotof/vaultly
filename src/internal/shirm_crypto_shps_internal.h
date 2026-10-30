#ifndef SHIRM_CRYPTO_SHPS_INTERNAL_H
#define SHIRM_CRYPTO_SHPS_INTERNAL_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct
{
    char *encrypted_key_b64;  
    char *iv_b64;             
    int   compressed;
} ShpsHeader;

int  shps_parse_header(const char *json, size_t json_len,
                       ShpsHeader *out, char **error);
void shps_free_header(ShpsHeader *h);


char *shps_json_escape(const char *s);

#ifdef __cplusplus
}
#endif

#endif
#ifndef JSMN_H
#define JSMN_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    JSMN_UNDEFINED = 0,
    JSMN_OBJECT    = 1 << 0,
    JSMN_ARRAY     = 1 << 1,
    JSMN_STRING    = 1 << 2,
    JSMN_PRIMITIVE = 1 << 3
} jsmntype_t;

enum jsmnerr {
    JSMN_ERROR_NOMEM = -1,
    JSMN_ERROR_INVAL = -2,
    JSMN_ERROR_PART  = -3
};

typedef struct {
    jsmntype_t type;
    int start;
    int end;
    int size;
    int parent;
} jsmntok_t;

typedef struct {
    unsigned int pos;
    unsigned int toknext;
    int toksuper;
} jsmn_parser;

static void jsmn_init(jsmn_parser *parser);
static int  jsmn_parse(jsmn_parser *parser, const char *js, size_t len,
                       jsmntok_t *tokens, unsigned int num_tokens);

#ifdef __cplusplus
}
#endif



static void jsmn_init(jsmn_parser *parser) {
    parser->pos      = 0;
    parser->toknext  = 0;
    parser->toksuper = -1;
}

static jsmntok_t *jsmn_alloc_token(jsmn_parser *p, jsmntok_t *t, size_t n) {
    if (p->toknext >= n) return NULL;
    jsmntok_t *tok = &t[p->toknext++];
    tok->start  = tok->end = -1;
    tok->size   = 0;
    tok->parent = -1;
    return tok;
}

static void jsmn_fill(jsmntok_t *t, jsmntype_t ty, int s, int e) {
    t->type  = ty;
    t->start = s;
    t->end   = e;
    t->size  = 0;
}

static int jsmn_parse_primitive(jsmn_parser *p, const char *js, size_t len,
                                jsmntok_t *t, size_t n) {
    int start = p->pos;
    for (; p->pos < len && js[p->pos] != '\0'; p->pos++) {
        switch (js[p->pos]) {
        case ':': case '\t': case '\r': case '\n':
        case ' ': case ',': case ']': case '}':
            goto found;
        default:
            if ((unsigned char)js[p->pos] < 32) {
                p->pos = start;
                return JSMN_ERROR_INVAL;
            }
        }
    }
found:
    if (!t) { p->pos--; return 0; }
    jsmntok_t *tok = jsmn_alloc_token(p, t, n);
    if (!tok) { p->pos = start; return JSMN_ERROR_NOMEM; }
    jsmn_fill(tok, JSMN_PRIMITIVE, start, p->pos);
    tok->parent = (int)p->toksuper;
    p->pos--;
    return 0;
}

static int jsmn_parse_string(jsmn_parser *p, const char *js, size_t len,
                             jsmntok_t *t, size_t n) {
    int start = p->pos;
    p->pos++;
    for (; p->pos < len && js[p->pos] != '\0'; p->pos++) {
        char c = js[p->pos];
        if (c == '\"') {
            if (!t) return 0;
            jsmntok_t *tok = jsmn_alloc_token(p, t, n);
            if (!tok) { p->pos = start; return JSMN_ERROR_NOMEM; }
            jsmn_fill(tok, JSMN_STRING, start + 1, p->pos);
            tok->parent = (int)p->toksuper;
            return 0;
        }
        if (c == '\\' && p->pos + 1 < len) {
            int i;
            p->pos++;
            switch (js[p->pos]) {
            case '\"': case '/': case '\\': case 'b': case 'f':
            case 'r':  case 'n': case 't':
                break;
            case 'u':
                for (i = 0; i < 4 && p->pos < len && js[p->pos] != '\0'; i++) {
                    p->pos++;
                    if (!((js[p->pos] >= '0' && js[p->pos] <= '9') ||
                          (js[p->pos] >= 'A' && js[p->pos] <= 'F') ||
                          (js[p->pos] >= 'a' && js[p->pos] <= 'f'))) {
                        p->pos = start;
                        return JSMN_ERROR_INVAL;
                    }
                }
                p->pos--;
                break;
            default:
                p->pos = start;
                return JSMN_ERROR_INVAL;
            }
        }
    }
    p->pos = start;
    return JSMN_ERROR_PART;
}

static int jsmn_parse(jsmn_parser *p, const char *js, size_t len,
                      jsmntok_t *t, unsigned int n) {
    int i, r, count = (int)p->toknext;
    jsmntok_t *tok;
    for (; p->pos < len && js[p->pos] != '\0'; p->pos++) {
        char c = js[p->pos];
        switch (c) {
        case '{': case '[': {
            count++;
            if (!t) break;
            tok = jsmn_alloc_token(p, t, n);
            if (!tok) return JSMN_ERROR_NOMEM;
            if (p->toksuper != -1) {
                t[p->toksuper].size++;
                tok->parent = p->toksuper;
            }
            tok->type  = (c == '{' ? JSMN_OBJECT : JSMN_ARRAY);
            tok->start = p->pos;
            p->toksuper = (int)p->toknext - 1;
            break;
        }
        case '}': case ']': {
            if (!t) break;
            jsmntype_t ty = (c == '}' ? JSMN_OBJECT : JSMN_ARRAY);
            if (p->toknext < 1) return JSMN_ERROR_INVAL;
            tok = &t[p->toknext - 1];
            for (;;) {
                if (tok->start != -1 && tok->end == -1) {
                    if (tok->type != ty) return JSMN_ERROR_INVAL;
                    tok->end = p->pos + 1;
                    p->toksuper = tok->parent;
                    break;
                }
                if (tok->parent == -1) {
                    if (tok->type != ty || p->toksuper == -1)
                        return JSMN_ERROR_INVAL;
                    break;
                }
                tok = &t[tok->parent];
            }
            break;
        }
        case '\"':
            r = jsmn_parse_string(p, js, len, t, n);
            if (r < 0) return r;
            count++;
            if (p->toksuper != -1 && t) t[p->toksuper].size++;
            break;
        case '\t': case '\r': case '\n': case ' ':
            break;
        case ':':
            p->toksuper = (int)p->toknext - 1;
            break;
        case ',':
            if (t && p->toksuper != -1 &&
                t[p->toksuper].type != JSMN_ARRAY &&
                t[p->toksuper].type != JSMN_OBJECT) {
                p->toksuper = t[p->toksuper].parent;
            }
            break;
        default:
            r = jsmn_parse_primitive(p, js, len, t, n);
            if (r < 0) return r;
            count++;
            if (p->toksuper != -1 && t) t[p->toksuper].size++;
            break;
        }
    }
    if (t) {
        for (i = (int)p->toknext - 1; i >= 0; i--) {
            if (t[i].start != -1 && t[i].end == -1) return JSMN_ERROR_PART;
        }
    }
    return count;
}

#endif 
package com.efedotov.vaultly.service;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AuthServiceStaticTest {

    @Test
    void normalizePublicKey_null_returnsNull() {
        assertThat(AuthService.normalizePublicKey(null)).isNull();
    }

    @Test
    void normalizePublicKey_stripsPemAndWhitespace() {
        String raw = "-----BEGIN PUBLIC KEY-----\nABC DEF\n-----END PUBLIC KEY-----";
        assertThat(AuthService.normalizePublicKey(raw)).isEqualTo("ABCDEF");
    }
}
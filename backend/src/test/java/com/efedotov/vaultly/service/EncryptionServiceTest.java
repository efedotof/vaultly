package com.efedotov.vaultly.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.security.SecureRandom;
import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class EncryptionServiceTest {

    private EncryptionService service;

    @BeforeEach
    void setUp() {
        byte[] key = new byte[32];
        new SecureRandom().nextBytes(key);
        service = new EncryptionService(Base64.getEncoder().encodeToString(key));
    }

    @Test
    void encryptThenDecrypt_returnsOriginal() {
        String enc = service.encrypt("hello world");
        assertThat(enc).contains(":");
        assertThat(service.decrypt(enc)).isEqualTo("hello world");
    }

    @Test
    void encrypt_differentCiphertextsForSameInput() {
        assertThat(service.encrypt("x")).isNotEqualTo(service.encrypt("x"));
    }

    @Test
    void decrypt_invalidFormat_throws() {
        assertThatThrownBy(() -> service.decrypt("no-colon-here"))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void decrypt_tamperedCiphertext_throws() {
        String enc = service.encrypt("data");
        String[] parts = enc.split(":", 2);
        char[] ct = parts[1].toCharArray();
        ct[0] = ct[0] == 'A' ? 'B' : 'A';
        String tampered = parts[0] + ":" + new String(ct);
        assertThatThrownBy(() -> service.decrypt(tampered))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void constructor_wrongKeySize_throws() {
        String bad = Base64.getEncoder().encodeToString(new byte[16]);
        assertThatThrownBy(() -> new EncryptionService(bad))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
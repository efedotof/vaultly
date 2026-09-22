package com.efedotov.vaultly.shirmps;

import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class ShirmpsHeaderTest {

    @Test
    void jsonRoundtrip() throws Exception {
        ShirmpsHeader header = new ShirmpsHeader();
        header.setKeyOwner("server");
        header.setUserId(UUID.randomUUID().toString());
        header.setOriginalFileSize(1024L);
        header.setEncryptedKey("AAAA");
        header.setIv("BBBB");
        header.setMetadata(Map.of("compressed", "false"));

        byte[] json = header.toJsonBytes();
        ShirmpsHeader parsed = ShirmpsHeader.fromJsonBytes(json);

        assertThat(parsed.getVersion()).isEqualTo("1.0");
        assertThat(parsed.getAlgorithm()).isEqualTo("AES-256-GCM");
        assertThat(parsed.getKeyEncryption()).isEqualTo("RSA-OAEP");
        assertThat(parsed.getKeyOwner()).isEqualTo("server");
        assertThat(parsed.getUserId()).isEqualTo(header.getUserId());
        assertThat(parsed.getOriginalFileSize()).isEqualTo(1024L);
        assertThat(parsed.getMetadata()).containsEntry("compressed", "false");
    }

    @Test
    void unknownPropertiesAreIgnored() throws Exception {
        String json = "{\"version\":\"1.0\",\"unknown\":\"whatever\"}";
        ShirmpsHeader parsed = ShirmpsHeader.fromJsonBytes(json.getBytes());
        assertThat(parsed.getVersion()).isEqualTo("1.0");
    }
}
package com.efedotov.vaultly.service;

import com.efedotov.vaultly.shirmps.ShirmpsHeader;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.ByteArrayInputStream;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.SecureRandom;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.lenient;

@ExtendWith(MockitoExtension.class)
class ShpsEncryptionServiceTest {

    @Mock
    ServerKeyService serverKeyService;
    @InjectMocks
    ShpsEncryptionService service;

    private KeyPair keyPair;

    @BeforeEach
    void setUp() throws Exception {
        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(2048);
        keyPair = kpg.generateKeyPair();
        lenient().when(serverKeyService.getPublicKey()).thenReturn(keyPair.getPublic());
    }

    @Test
    void encrypt_producesValidShpsContainer() throws Exception {
        byte[] payload = "Hello, SHPS!".getBytes(StandardCharsets.UTF_8);
        UUID userId = UUID.randomUUID();

        File result = service.encryptForServerToTempFile(
                new ByteArrayInputStream(payload), payload.length, "test.txt", userId);

        try {
            assertThat(result).exists();
            assertThat(result.length()).isGreaterThan(0);

            ShirmpsHeader header = readHeader(result);

            assertThat(header.getVersion()).isEqualTo("1.0");
            assertThat(header.getAlgorithm()).isEqualTo("AES-256-GCM");
            assertThat(header.getKeyEncryption()).isEqualTo("RSA-OAEP");
            assertThat(header.getKeyOwner()).isEqualTo("server");
            assertThat(header.getUserId()).isEqualTo(userId.toString());
            assertThat(header.getOriginalFileName()).isEqualTo("test.txt");
            assertThat(header.getOriginalFileSize()).isEqualTo((long) payload.length);
            assertThat(header.getEncryptedKey()).isNotBlank();
            assertThat(header.getIv()).isNotBlank();
            assertThat(header.getSignature()).isNull();
            assertThat(header.getCreationDate()).isNotNull();
            assertThat(header.getMetadata()).isNotNull().isEmpty();
        } finally {
            result.delete();
        }
    }

    @Test
    void encrypt_emptyPayload_createsValidFile() throws Exception {
        File result = service.encryptForServerToTempFile(
                new ByteArrayInputStream(new byte[0]), 0L, "empty.txt", UUID.randomUUID());

        try {
            assertThat(result).exists();

            assertThat(result.length()).isGreaterThan(0);
        } finally {
            result.delete();
        }
    }

    @Test
    void encrypt_largePayload_streamedInChunks() throws Exception {
        byte[] payload = new byte[1024 * 1024];
        new SecureRandom().nextBytes(payload);

        File result = service.encryptForServerToTempFile(
                new ByteArrayInputStream(payload), payload.length, "big.bin", UUID.randomUUID());

        try {
            assertThat(result).exists();

            assertThat(result.length()).isGreaterThanOrEqualTo(payload.length);
        } finally {
            result.delete();
        }
    }

    @Test
    void encrypt_usesUniqueIvPerCall() throws Exception {
        byte[] payload = "same input".getBytes(StandardCharsets.UTF_8);

        File f1 = service.encryptForServerToTempFile(
                new ByteArrayInputStream(payload), payload.length, "a.txt", UUID.randomUUID());
        File f2 = service.encryptForServerToTempFile(
                new ByteArrayInputStream(payload), payload.length, "a.txt", UUID.randomUUID());

        try {
            String iv1 = readHeader(f1).getIv();
            String iv2 = readHeader(f2).getIv();
            assertThat(iv1).isNotEqualTo(iv2);
        } finally {
            f1.delete();
            f2.delete();
        }
    }

    @Test
    void encrypt_usesUniqueAesKeyPerCall() throws Exception {
        byte[] payload = "same".getBytes(StandardCharsets.UTF_8);

        File f1 = service.encryptForServerToTempFile(
                new ByteArrayInputStream(payload), payload.length, "a.txt", UUID.randomUUID());
        File f2 = service.encryptForServerToTempFile(
                new ByteArrayInputStream(payload), payload.length, "a.txt", UUID.randomUUID());

        try {
            assertThat(readHeader(f1).getEncryptedKey())
                    .isNotEqualTo(readHeader(f2).getEncryptedKey());
        } finally {
            f1.delete();
            f2.delete();
        }
    }

    private ShirmpsHeader readHeader(File file) throws Exception {
        try (DataInputStream dis = new DataInputStream(new FileInputStream(file))) {
            int len = dis.readInt();
            byte[] hb = new byte[len];
            dis.readFully(hb);
            return ShirmpsHeader.fromJsonBytes(hb);
        }
    }
}
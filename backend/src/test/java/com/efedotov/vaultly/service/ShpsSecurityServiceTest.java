package com.efedotov.vaultly.service;

import com.efedotov.vaultly.shirmps.ShirmpsHeader;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@ExtendWith(MockitoExtension.class)
class ShpsSecurityServiceTest {

    @Mock
    ServerKeyService serverKeyService;
    @InjectMocks
    ShpsSecurityService service;

    private ShirmpsHeader validHeader;

    @BeforeEach
    void setUp() {
        validHeader = new ShirmpsHeader();
        validHeader.setVersion("1.0");
        validHeader.setAlgorithm("AES-256-GCM");
        validHeader.setKeyEncryption("RSA-OAEP");
        validHeader.setKeyOwner("server");
        validHeader.setUserId(UUID.randomUUID().toString());
        validHeader.setOriginalFileSize(100L);
        validHeader.setEncryptedKey("AAAA");
        validHeader.setIv("BBBB");
    }

    private byte[] packWithLength(ShirmpsHeader header) throws Exception {
        byte[] headerBytes = header.toJsonBytes();
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (DataOutputStream dos = new DataOutputStream(baos)) {
            dos.writeInt(headerBytes.length);
            dos.write(headerBytes);
        }
        return baos.toByteArray();
    }

    @Test
    void validateStructure_validHeader_returnsTrue() throws Exception {
        byte[] packed = packWithLength(validHeader);
        assertThat(service.validateStructure(packed)).isTrue();
    }

    @Test
    void validateStructure_validHeaderWithName_returnsTrue() throws Exception {
        byte[] packed = packWithLength(validHeader);
        assertThat(service.validateStructure(packed, "test.shps")).isTrue();
    }

    @Test
    void validateStructure_invalidVersion_returnsFalse() throws Exception {
        validHeader.setVersion("2.0");
        byte[] packed = packWithLength(validHeader);
        assertThat(service.validateStructure(packed)).isFalse();
    }

    @Test
    void validateStructure_invalidAlgorithm_returnsFalse() throws Exception {
        validHeader.setAlgorithm("AES-128");
        byte[] packed = packWithLength(validHeader);
        assertThat(service.validateStructure(packed)).isFalse();
    }

    @Test
    void validateStructure_zeroFileSize_returnsFalse() throws Exception {
        validHeader.setOriginalFileSize(0L);
        byte[] packed = packWithLength(validHeader);
        assertThat(service.validateStructure(packed)).isFalse();
    }

    @Test
    void validateStructure_nullFileSize_returnsFalse() throws Exception {
        validHeader.setOriginalFileSize(null);
        byte[] packed = packWithLength(validHeader);
        assertThat(service.validateStructure(packed)).isFalse();
    }

    @Test
    void validateStructure_badHeaderLength_returnsFalse() throws Exception {

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (DataOutputStream dos = new DataOutputStream(baos)) {
            dos.writeInt(0);
        }
        assertThat(service.validateStructure(baos.toByteArray())).isFalse();
    }

    @Test
    void validateStructure_hugeHeaderLength_returnsFalse() throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (DataOutputStream dos = new DataOutputStream(baos)) {
            dos.writeInt(100_000);
        }
        assertThat(service.validateStructure(baos.toByteArray())).isFalse();
    }

    @Test
    void validateStructure_truncatedHeader_throws() throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (DataOutputStream dos = new DataOutputStream(baos)) {
            dos.writeInt(200);
            dos.write(new byte[] { 1, 2, 3 });
        }
        assertThatThrownBy(() -> service.validateStructure(baos.toByteArray()))
                .isInstanceOf(Exception.class);
    }

    @Test
    void validateHeaderOnly_validHeader_returnsHeader() throws Exception {
        byte[] packed = packWithLength(validHeader);
        ShirmpsHeader result = service.validateHeaderOnly(packed);
        assertThat(result.getVersion()).isEqualTo("1.0");
        assertThat(result.getUserId()).isEqualTo(validHeader.getUserId());
    }

    @Test
    void validateHeaderOnly_withFileName_works() throws Exception {
        byte[] packed = packWithLength(validHeader);
        ShirmpsHeader result = service.validateHeaderOnly(packed, "file.shps");
        assertThat(result.getAlgorithm()).isEqualTo("AES-256-GCM");
    }

    @Test
    void validateHeaderOnly_path_works() throws Exception {
        byte[] packed = packWithLength(validHeader);
        Path tmp = Files.createTempFile("shps-test", ".shps");
        Files.write(tmp, packed);
        try {
            ShirmpsHeader result = service.validateHeaderOnly(tmp, "f.shps");
            assertThat(result.getVersion()).isEqualTo("1.0");
        } finally {
            Files.deleteIfExists(tmp);
        }
    }

    @Test
    void validateHeaderOnly_invalidVersion_throws() throws Exception {
        validHeader.setVersion("0.9");
        byte[] packed = packWithLength(validHeader);
        assertThatThrownBy(() -> service.validateHeaderOnly(packed))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("version");
    }

    @Test
    void validateHeaderOnly_invalidAlgorithm_throws() throws Exception {
        validHeader.setAlgorithm("Blowfish");
        byte[] packed = packWithLength(validHeader);
        assertThatThrownBy(() -> service.validateHeaderOnly(packed))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("algorithm");
    }

    @Test
    void validateHeaderOnly_invalidKeyEncryption_throws() throws Exception {
        validHeader.setKeyEncryption("plain");
        byte[] packed = packWithLength(validHeader);
        assertThatThrownBy(() -> service.validateHeaderOnly(packed))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("key encryption");
    }

    @Test
    void validateHeaderOnly_missingUserId_throws() throws Exception {
        validHeader.setUserId("");
        byte[] packed = packWithLength(validHeader);
        assertThatThrownBy(() -> service.validateHeaderOnly(packed))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("User ID");
    }

    @Test
    void validateHeaderOnly_nullUserId_throws() throws Exception {
        validHeader.setUserId(null);
        byte[] packed = packWithLength(validHeader);
        assertThatThrownBy(() -> service.validateHeaderOnly(packed))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("User ID");
    }

    @Test
    void validateHeaderOnly_zeroSize_throws() throws Exception {
        validHeader.setOriginalFileSize(0L);
        byte[] packed = packWithLength(validHeader);
        assertThatThrownBy(() -> service.validateHeaderOnly(packed))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("file size");
    }

    @Test
    void extractHeader_returnsHeader() throws Exception {
        byte[] packed = packWithLength(validHeader);
        ShirmpsHeader result = service.extractHeader(new ByteArrayInputStream(packed));
        assertThat(result.getVersion()).isEqualTo("1.0");
    }

    @Test
    void extractHeader_badLength_throws() throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (DataOutputStream dos = new DataOutputStream(baos)) {
            dos.writeInt(-1);
        }
        assertThatThrownBy(() -> service.extractHeader(new ByteArrayInputStream(baos.toByteArray())))
                .isInstanceOf(SecurityException.class);
    }
}
package com.efedotov.vaultly.service;

import com.efedotov.vaultly.shirmps.ShirmpsHeader;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.OAEPParameterSpec;
import javax.crypto.spec.PSource;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.SecureRandom;
import java.security.spec.MGF1ParameterSpec;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.function.Consumer;
import java.util.zip.GZIPOutputStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.lenient;

@ExtendWith(MockitoExtension.class)
class ShpsSecurityServiceCryptoTest {

    @Mock
    ServerKeyService serverKeyService;
    @InjectMocks
    ShpsSecurityService service;

    private KeyPair keyPair;

    @BeforeEach
    void setUp() throws Exception {
        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(2048);
        keyPair = kpg.generateKeyPair();
        lenient().when(serverKeyService.getPublicKey()).thenReturn(keyPair.getPublic());
        lenient().when(serverKeyService.getPrivateKey()).thenReturn(keyPair.getPrivate());
    }

    @Test
    void validateAndVerifyStreaming_byteArray_noSignature_returnsTrue() throws Exception {
        byte[] payload = "Hello, world".getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, false, false);

        assertThat(service.validateAndVerifyStreaming(container, UUID.randomUUID(), "f"))
                .isTrue();
    }

    @Test
    void validateAndVerifyStreaming_byteArray_withSignature_returnsTrue() throws Exception {
        byte[] payload = "Signed payload".getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, false, true);

        assertThat(service.validateAndVerifyStreaming(container, UUID.randomUUID(), "f"))
                .isTrue();
    }

    @Test
    void validateAndVerifyStreaming_byteArray_compressed_returnsTrue() throws Exception {
        byte[] payload = "A".repeat(2000).getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, true, false);

        assertThat(service.validateAndVerifyStreaming(container, UUID.randomUUID(), "f"))
                .isTrue();
    }

    @Test
    void validateAndVerifyStreaming_byteArray_tamperedSignature_throws() throws Exception {
        byte[] payload = "Signed payload".getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, false, true);
        byte[] tampered = modifyHeader(container,
                h -> h.setSignature(Base64.getEncoder().encodeToString(new byte[256])));

        assertThatThrownBy(() -> service.validateAndVerifyStreaming(tampered, UUID.randomUUID(), "f"))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("signature");
    }

    @Test
    void validateAndVerifyStreaming_byteArray_userKeyOwner_throws() throws Exception {
        byte[] payload = "x".getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, false, false);
        byte[] userOwned = modifyHeader(container, h -> h.setKeyOwner("user"));

        assertThatThrownBy(() -> service.validateAndVerifyStreaming(userOwned, UUID.randomUUID(), "f"))
                .isInstanceOf(SecurityException.class);
    }

    @Test
    void validateAndVerifyStreaming_byteArray_sizeMismatch_throws() throws Exception {
        byte[] payload = "x".getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, false, true);
        byte[] wrong = modifyHeader(container, h -> h.setOriginalFileSize(9999L));

        assertThatThrownBy(() -> service.validateAndVerifyStreaming(wrong, UUID.randomUUID(), "f"))
                .isInstanceOf(SecurityException.class);
    }

    @Test
    void validateAndVerifyStreaming_path_noSignature_returnsTrue() throws Exception {
        byte[] payload = "Hello path".getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, false, false);
        Path tmp = Files.createTempFile("shps-crypto", ".shps");
        Files.write(tmp, container);
        try {
            assertThat(service.validateAndVerifyStreaming(tmp, UUID.randomUUID(), "f"))
                    .isTrue();
        } finally {
            Files.deleteIfExists(tmp);
        }
    }

    @Test
    void validateAndVerifyStreaming_path_compressed_returnsTrue() throws Exception {
        byte[] payload = "B".repeat(500).getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, true, false);
        Path tmp = Files.createTempFile("shps-crypto", ".shps");
        Files.write(tmp, container);
        try {
            assertThat(service.validateAndVerifyStreaming(tmp, UUID.randomUUID(), "f"))
                    .isTrue();
        } finally {
            Files.deleteIfExists(tmp);
        }
    }

    @Test
    void decryptServerEncrypted_returnsOriginalPayload() throws Exception {
        byte[] payload = "Decrypted content!".getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, false, false);

        byte[] result = service.decryptServerEncrypted(container, "f");

        assertThat(result).isEqualTo(payload);
    }

    @Test
    void decryptServerEncrypted_compressed_returnsOriginal() throws Exception {
        byte[] payload = "C".repeat(2000).getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, true, false);

        byte[] result = service.decryptServerEncrypted(container, "f");

        assertThat(result).isEqualTo(payload);
    }

    @Test
    void decryptServerEncrypted_userKeyOwner_throws() throws Exception {
        byte[] payload = "x".getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, false, false);
        byte[] userOwned = modifyHeader(container, h -> h.setKeyOwner("user"));

        assertThatThrownBy(() -> service.decryptServerEncrypted(userOwned, "f"))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("not encrypted for server");
    }

    @Test
    void decryptServerEncrypted_sizeMismatch_throws() throws Exception {
        byte[] payload = "x".getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, false, false);
        byte[] wrongSize = modifyHeader(container, h -> h.setOriginalFileSize(9999L));

        assertThatThrownBy(() -> service.decryptServerEncrypted(wrongSize, "f"))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("size mismatch");
    }

    @Test
    void decryptServerEncrypted_emptyPayload_isRejected() throws Exception {
        byte[] container = buildShpsDefault(new byte[0], false, false);

        assertThatThrownBy(() -> service.decryptServerEncrypted(container, "f"))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("file size");
    }

    @Test
    void decryptServerEncryptedToStream_writesPayload() throws Exception {
        byte[] payload = "Streamed!".getBytes(StandardCharsets.UTF_8);

        byte[] container = buildShpsExplicit256(payload, false);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        service.decryptServerEncryptedToStream(new ByteArrayInputStream(container), out);

        assertThat(out.toByteArray()).isEqualTo(payload);
    }

    @Test
    void decryptServerEncryptedToStream_compressed_writesOriginal() throws Exception {
        byte[] payload = "D".repeat(1000).getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsExplicit256(payload, true);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        service.decryptServerEncryptedToStream(new ByteArrayInputStream(container), out);

        assertThat(out.toByteArray()).isEqualTo(payload);
    }

    @Test
    void decryptServerEncryptedToStream_userKeyOwner_throws() throws Exception {
        byte[] payload = "x".getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsExplicit256(payload, false);
        byte[] userOwned = modifyHeader(container, h -> h.setKeyOwner("user"));

        assertThatThrownBy(() -> service.decryptServerEncryptedToStream(
                new ByteArrayInputStream(userOwned), new ByteArrayOutputStream()))
                .isInstanceOf(SecurityException.class);
    }

    @Test
    void decryptServerEncryptedToStream_badHeaderLength_throws() throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (DataOutputStream dos = new DataOutputStream(baos)) {
            dos.writeInt(-5);
        }
        assertThatThrownBy(() -> service.decryptServerEncryptedToStream(
                new ByteArrayInputStream(baos.toByteArray()), new ByteArrayOutputStream()))
                .isInstanceOf(SecurityException.class);
    }

    @Test
    void decryptServerEncryptedToStream_emptyPayload_isRejected() throws Exception {
        byte[] container = buildShpsExplicit256(new byte[0], false);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        assertThatThrownBy(() -> service.decryptServerEncryptedToStream(
                new ByteArrayInputStream(container), out))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("file size");
    }

    private byte[] buildShpsDefault(byte[] plaintext, boolean compressed, boolean signed) throws Exception {
        return buildShps(plaintext, compressed, signed, false);
    }

    private byte[] buildShpsExplicit256(byte[] plaintext, boolean compressed) throws Exception {
        return buildShps(plaintext, compressed, false, true);
    }

    private byte[] buildShps(byte[] plaintext, boolean compressed, boolean signed, boolean explicitMgf1)
            throws Exception {

        KeyGenerator keyGen = KeyGenerator.getInstance("AES");
        keyGen.init(256);
        SecretKey aesKey = keyGen.generateKey();
        byte[] iv = new byte[12];
        new SecureRandom().nextBytes(iv);

        byte[] toEncrypt = plaintext;
        if (compressed) {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            try (GZIPOutputStream gz = new GZIPOutputStream(baos)) {
                gz.write(plaintext);
            }
            toEncrypt = baos.toByteArray();
        }

        Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
        aesCipher.init(Cipher.ENCRYPT_MODE, aesKey, new GCMParameterSpec(128, iv));
        byte[] cipherText = aesCipher.doFinal(toEncrypt);

        Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        if (explicitMgf1) {
            OAEPParameterSpec oaepParams = new OAEPParameterSpec(
                    "SHA-256", "MGF1", MGF1ParameterSpec.SHA256, PSource.PSpecified.DEFAULT);
            rsaCipher.init(Cipher.ENCRYPT_MODE, keyPair.getPublic(), oaepParams);
        } else {
            rsaCipher.init(Cipher.ENCRYPT_MODE, keyPair.getPublic());
        }
        byte[] encryptedAesKey = rsaCipher.doFinal(aesKey.getEncoded());

        String signature = null;
        if (signed) {
            java.security.Signature sig = java.security.Signature.getInstance("SHA256withRSA");
            sig.initSign(keyPair.getPrivate());
            sig.update(plaintext);
            signature = Base64.getEncoder().encodeToString(sig.sign());
        }

        ShirmpsHeader header = new ShirmpsHeader();
        header.setVersion("1.0");
        header.setAlgorithm("AES-256-GCM");
        header.setKeyEncryption("RSA-OAEP");
        header.setKeyOwner("server");
        header.setUserId(UUID.randomUUID().toString());
        header.setOriginalFileSize((long) plaintext.length);
        header.setOriginalFileName("test.bin");
        header.setEncryptedKey(Base64.getEncoder().encodeToString(encryptedAesKey));
        header.setIv(Base64.getEncoder().encodeToString(iv));
        header.setSignature(signature);
        header.setMetadata(new HashMap<>(Map.of("compressed", String.valueOf(compressed))));

        byte[] headerBytes = header.toJsonBytes();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try (DataOutputStream dos = new DataOutputStream(out)) {
            dos.writeInt(headerBytes.length);
            dos.write(headerBytes);
            dos.write(cipherText);
        }
        return out.toByteArray();
    }

    private byte[] modifyHeader(byte[] container, Consumer<ShirmpsHeader> modifier) throws Exception {
        try (DataInputStream dis = new DataInputStream(new ByteArrayInputStream(container))) {
            int len = dis.readInt();
            byte[] headerBytes = new byte[len];
            dis.readFully(headerBytes);
            byte[] rest = dis.readAllBytes();

            ShirmpsHeader header = ShirmpsHeader.fromJsonBytes(headerBytes);
            modifier.accept(header);

            byte[] newHeader = header.toJsonBytes();
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            try (DataOutputStream dos = new DataOutputStream(out)) {
                dos.writeInt(newHeader.length);
                dos.write(newHeader);
                dos.write(rest);
            }
            return out.toByteArray();
        }
    }

    @Test
    void validateAndVerifyStreaming_nullMetadata_treatsAsUncompressed() throws Exception {
        byte[] payload = "test".getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, false, false);

        byte[] noMeta = modifyHeader(container, h -> h.setMetadata(null));

        assertThat(service.validateAndVerifyStreaming(noMeta, UUID.randomUUID(), "f")).isTrue();
    }

    @Test
    void validateHeaderOnly_path_badJson_throws() throws Exception {
        byte[] headerBytes = "{not-json".getBytes(StandardCharsets.UTF_8);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try (DataOutputStream dos = new DataOutputStream(out)) {
            dos.writeInt(headerBytes.length);
            dos.write(headerBytes);
        }
        Path tmp = Files.createTempFile("shps-bad", ".shps");
        Files.write(tmp, out.toByteArray());
        try {
            assertThatThrownBy(() -> service.validateHeaderOnly(tmp, "f"))
                    .isInstanceOf(Exception.class);
        } finally {
            Files.deleteIfExists(tmp);
        }
    }

    @Test
    void validateAndVerifyStreaming_path_signed_returnsTrue() throws Exception {
        byte[] payload = "signed".getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, false, true);
        Path tmp = Files.createTempFile("shps-signed", ".shps");
        Files.write(tmp, container);
        try {
            assertThat(service.validateAndVerifyStreaming(tmp, UUID.randomUUID(), "f")).isTrue();
        } finally {
            Files.deleteIfExists(tmp);
        }
    }

    @Test
    void validateAndVerifyStreaming_byteArray_badSignatureBase64_throws() throws Exception {
        byte[] payload = "x".getBytes(StandardCharsets.UTF_8);
        byte[] container = buildShpsDefault(payload, false, true);
        byte[] badSig = modifyHeader(container, h -> h.setSignature("!!!not-base64!!!"));

        assertThatThrownBy(() -> service.validateAndVerifyStreaming(badSig, UUID.randomUUID(), "f"))
                .isInstanceOf(Exception.class);
    }
}
package com.efedotov.vaultly.service;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import javax.crypto.Cipher;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ServerKeyServiceTest {

    private ServerKeyService service;
    private KeyPair keyPair;
    private Path privateKeyFile;
    private Path publicKeyFile;

    @BeforeEach
    void setUp() throws Exception {
        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(2048);
        keyPair = kpg.generateKeyPair();

        privateKeyFile = Files.createTempFile("server-priv", ".pem");
        publicKeyFile = Files.createTempFile("server-pub", ".pem");

        Files.writeString(privateKeyFile, toPem("PRIVATE KEY", keyPair.getPrivate().getEncoded()));
        Files.writeString(publicKeyFile, toPem("PUBLIC KEY", keyPair.getPublic().getEncoded()));

        service = new ServerKeyService();
        ReflectionTestUtils.setField(service, "privateKeyPath", privateKeyFile.toString());
        ReflectionTestUtils.setField(service, "publicKeyPath", publicKeyFile.toString());
    }

    @AfterEach
    void tearDown() throws Exception {
        Files.deleteIfExists(privateKeyFile);
        Files.deleteIfExists(publicKeyFile);
    }

    @Test
    void init_loadsKeysSuccessfully() {
        service.init();

        assertThat(service.getPrivateKey()).isNotNull();
        assertThat(service.getPublicKey()).isNotNull();
        assertThat(service.getPrivateKey().getAlgorithm()).isEqualTo("RSA");
        assertThat(service.getPublicKey().getAlgorithm()).isEqualTo("RSA");
    }

    @Test
    void getPublicKeyPem_returnsValidPem() {
        service.init();

        String pem = service.getPublicKeyPem();

        assertThat(pem).startsWith("-----BEGIN PUBLIC KEY-----");
        assertThat(pem).endsWith("-----END PUBLIC KEY-----");
        assertThat(pem).contains("\n");
    }

    @Test
    void init_thenEncryptDecrypt_roundTrip() throws Exception {
        service.init();

        Cipher enc = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        enc.init(Cipher.ENCRYPT_MODE, service.getPublicKey());
        byte[] data = "hello crypto".getBytes(StandardCharsets.UTF_8);
        byte[] encrypted = enc.doFinal(data);

        Cipher dec = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        dec.init(Cipher.DECRYPT_MODE, service.getPrivateKey());
        byte[] decrypted = dec.doFinal(encrypted);

        assertThat(decrypted).isEqualTo(data);
    }

    @Test
    void getPrivateKey_beforeInit_throws() {
        ServerKeyService fresh = new ServerKeyService();
        assertThatThrownBy(fresh::getPrivateKey)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("not loaded");
    }

    @Test
    void getPublicKey_beforeInit_throws() {
        ServerKeyService fresh = new ServerKeyService();
        assertThatThrownBy(fresh::getPublicKey)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("not loaded");
    }

    @Test
    void init_missingPrivateKeyFile_throws() {
        ReflectionTestUtils.setField(service, "privateKeyPath", "/nonexistent/path.pem");

        assertThatThrownBy(() -> service.init())
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("private key not found");
    }

    @Test
    void init_missingPublicKeyFile_throws() throws Exception {
        ReflectionTestUtils.setField(service, "publicKeyPath", "/nonexistent/path.pem");

        assertThatThrownBy(() -> service.init())
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("public key not found");
    }

    @Test
    void init_garbagePrivateKey_throws() throws Exception {
        Files.writeString(privateKeyFile, "not a pem");
        assertThatThrownBy(() -> service.init())
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    void init_mismatchedKeyPair_logsError_doesNotThrow() throws Exception {

        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(2048);
        KeyPair other = kpg.generateKeyPair();
        Files.writeString(publicKeyFile, toPem("PUBLIC KEY", other.getPublic().getEncoded()));

        service.init();

        assertThat(service.getPublicKey()).isNotNull();
    }

    private static String toPem(String label, byte[] der) {
        return "-----BEGIN " + label + "-----\n"
                + Base64.getMimeEncoder().encodeToString(der)
                + "\n-----END " + label + "-----";
    }
}
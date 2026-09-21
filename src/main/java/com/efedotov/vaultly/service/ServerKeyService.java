package com.efedotov.vaultly.service;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.InvalidKeyException;
import java.security.KeyFactory;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Arrays;
import java.util.Base64;
import java.util.HexFormat;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;

import org.springframework.stereotype.Service;

import io.github.cdimascio.dotenv.Dotenv;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class ServerKeyService {

    private final Dotenv dotenv;

    private PrivateKey serverPrivateKey;
    private PublicKey serverPublicKey;

    @PostConstruct
    public void init() throws Exception {
        loadKeys();
        byte[] pubEncoded = serverPublicKey.getEncoded();
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] fingerprint = md.digest(pubEncoded);
        log.info("Server public key fingerprint (SHA-256): {}", HexFormat.of().formatHex(fingerprint));
        try {
            Cipher cipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
            cipher.init(Cipher.ENCRYPT_MODE, serverPublicKey);
            byte[] testData = "test".getBytes(StandardCharsets.UTF_8);
            byte[] encrypted = cipher.doFinal(testData);
            cipher.init(Cipher.DECRYPT_MODE, serverPrivateKey);
            byte[] decrypted = cipher.doFinal(encrypted);
            if (!Arrays.equals(testData, decrypted)) {
                log.error("CRITICAL: Server public and private keys do not match!");
            } else {
                log.info("Server keys successfully verified as a matching pair.");
            }
        } catch (BadPaddingException e) {
            log.error(
                    "CRITICAL: Server private key cannot decrypt data encrypted with its own public key! Keys are not a pair.");
        } catch (InvalidKeyException | NoSuchAlgorithmException | IllegalBlockSizeException
                | NoSuchPaddingException e) {
            log.error("Failed to verify server key pair: {}", e.getMessage());
        }
    }

    private void loadKeys() throws Exception {
        try {
            String privateKeyPath = dotenv.get("SERVER_PRIVATE_KEY_PATH");
            String publicKeyPath = dotenv.get("SERVER_PUBLIC_KEY_PATH");

            File privateKeyFile = new File(privateKeyPath);
            if (!privateKeyFile.exists()) {
                log.warn("Server private key not found at: {}", privateKeyPath);
                return;
            }
            String privateKeyPem = new String(Files.readAllBytes(privateKeyFile.toPath()));
            byte[] privateKeyDer = decodePem(privateKeyPem);
            PKCS8EncodedKeySpec privateKeySpec = new PKCS8EncodedKeySpec(privateKeyDer);
            KeyFactory keyFactory = KeyFactory.getInstance("RSA");
            serverPrivateKey = keyFactory.generatePrivate(privateKeySpec);
            log.info("Server private key loaded successfully");

            File publicKeyFile = new File(publicKeyPath);
            if (publicKeyFile.exists()) {
                String publicKeyPem = new String(Files.readAllBytes(publicKeyFile.toPath()));
                byte[] publicKeyDer = decodePem(publicKeyPem);
                X509EncodedKeySpec publicKeySpec = new X509EncodedKeySpec(publicKeyDer);
                serverPublicKey = keyFactory.generatePublic(publicKeySpec);
                log.info("Server public key loaded successfully");
            } else {
                log.warn("Server public key not found at: {}", publicKeyPath);
            }

        } catch (IOException | NoSuchAlgorithmException | InvalidKeySpecException e) {
            log.error("Failed to load server keys", e);
            throw e;
        }
    }

    /**
     * Преобразует PEM‑строку в DER‑массив байтов.
     */
    private byte[] decodePem(String pem) {
        String base64 = pem
                .replaceAll("-----BEGIN [^-]+-----", "")
                .replaceAll("-----END [^-]+-----", "")
                .replaceAll("\\s", "");
        return Base64.getDecoder().decode(base64);
    }

    public PrivateKey getPrivateKey() {
        if (serverPrivateKey == null) {
            throw new IllegalStateException("Server private key not loaded");
        }
        return serverPrivateKey;
    }

    public PublicKey getPublicKey() {
        if (serverPublicKey == null) {
            throw new IllegalStateException("Server public key not loaded");
        }
        return serverPublicKey;
    }

    public String getPublicKeyPem() {
        PublicKey publicKey = getPublicKey();
        byte[] encoded = publicKey.getEncoded();
        String base64Key = Base64.getMimeEncoder().encodeToString(encoded);
        return "-----BEGIN PUBLIC KEY-----\n" + base64Key + "\n-----END PUBLIC KEY-----";
    }
}
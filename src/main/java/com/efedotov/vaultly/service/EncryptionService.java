package com.efedotov.vaultly.service;

import java.io.UnsupportedEncodingException;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class EncryptionService {

    private static final String AES_GCM_NO_PADDING = "AES/GCM/NoPadding";
    private static final int GCM_IV_LENGTH = 12;
    private static final int GCM_TAG_LENGTH = 128;

    private final SecretKey masterKey;
    private final SecureRandom secureRandom = new SecureRandom();

    public EncryptionService(@Value("${app.encryption.master-key}") String base64Key) {
        byte[] keyBytes = Base64.getDecoder().decode(base64Key);
        if (keyBytes.length != 32) {
            throw new IllegalArgumentException("Master key must be 32 bytes for AES-256");
        }
        this.masterKey = new SecretKeySpec(keyBytes, "AES");
    }

    public String encrypt(String plainText) {
        try {
            byte[] iv = new byte[GCM_IV_LENGTH];
            secureRandom.nextBytes(iv);

            Cipher cipher = Cipher.getInstance(AES_GCM_NO_PADDING);
            GCMParameterSpec spec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
            cipher.init(Cipher.ENCRYPT_MODE, masterKey, spec);
            byte[] cipherText = cipher.doFinal(plainText.getBytes("UTF-8"));

            String ivB64 = Base64.getEncoder().encodeToString(iv);
            String ctB64 = Base64.getEncoder().encodeToString(cipherText);
            return ivB64 + ":" + ctB64;
        } catch (UnsupportedEncodingException | InvalidAlgorithmParameterException | InvalidKeyException
                | NoSuchAlgorithmException | BadPaddingException | IllegalBlockSizeException
                | NoSuchPaddingException e) {
            throw new RuntimeException("Encryption failed", e);
        }
    }

    public String decrypt(String encryptedText) {
        try {
            String[] parts = encryptedText.split(":", 2);
            if (parts.length != 2) {
                throw new IllegalArgumentException("Invalid encrypted format");
            }
            byte[] iv = Base64.getDecoder().decode(parts[0]);
            byte[] cipherText = Base64.getDecoder().decode(parts[1]);

            Cipher cipher = Cipher.getInstance(AES_GCM_NO_PADDING);
            GCMParameterSpec spec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
            cipher.init(Cipher.DECRYPT_MODE, masterKey, spec);
            byte[] plainText = cipher.doFinal(cipherText);
            return new String(plainText, "UTF-8");
        } catch (UnsupportedEncodingException | IllegalArgumentException | InvalidAlgorithmParameterException
                | InvalidKeyException | NoSuchAlgorithmException | BadPaddingException | IllegalBlockSizeException
                | NoSuchPaddingException e) {
            throw new RuntimeException("Decryption failed", e);
        }
    }
}
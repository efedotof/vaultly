package com.efedotov.vaultly.service;

import com.efedotov.vaultly.dto.file.ShpsEncryptedStream;
import com.efedotov.vaultly.shirmps.ShirmpsHeader;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.CipherInputStream;
import javax.crypto.CipherOutputStream;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.OAEPParameterSpec;
import javax.crypto.spec.PSource;

import java.io.*;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.security.MessageDigest;
import java.security.PublicKey;
import java.security.SecureRandom;
import java.security.spec.MGF1ParameterSpec;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ShpsEncryptionService {

    private static final int AES_KEY_SIZE = 256;
    private static final int GCM_IV_LENGTH = 12;
    private static final int GCM_TAG_LENGTH = 128;

    private final ServerKeyService serverKeyService;
    private final ObjectMapper objectMapper = ShirmpsHeader.createObjectMapper();

    /**
     * Шифрует открытый файл в формат SHPS для публичного доступа (keyOwner =
     * server).
     */
    public byte[] encryptForServer(byte[] plainData, String originalFileName, UUID userId) throws Exception {
        log.info("Encrypting public file for server: {}, size: {} bytes", originalFileName, plainData.length);

        KeyGenerator keyGen = KeyGenerator.getInstance("AES");
        keyGen.init(AES_KEY_SIZE);
        SecretKey aesKey = keyGen.generateKey();

        byte[] iv = new byte[GCM_IV_LENGTH];
        new SecureRandom().nextBytes(iv);

        Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
        GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
        aesCipher.init(Cipher.ENCRYPT_MODE, aesKey, gcmSpec);
        byte[] encryptedData = aesCipher.doFinal(plainData);

        PublicKey serverPublicKey = serverKeyService.getPublicKey();
        Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        rsaCipher.init(Cipher.ENCRYPT_MODE, serverPublicKey);
        byte[] encryptedKey = rsaCipher.doFinal(aesKey.getEncoded());

        ShirmpsHeader header = new ShirmpsHeader();
        header.setVersion("1.0");
        header.setAlgorithm("AES-256-GCM");
        header.setKeyEncryption("RSA-OAEP");
        header.setKeyOwner("server");
        header.setUserId(userId.toString());
        header.setOriginalFileName(originalFileName);
        header.setOriginalFileSize((long) plainData.length);
        header.setEncryptedKey(Base64.getEncoder().encodeToString(encryptedKey));
        header.setIv(Base64.getEncoder().encodeToString(iv));
        header.setSignature(null);
        header.setCreationDate(LocalDateTime.now());
        header.setMetadata(new HashMap<>());

        byte[] headerBytes = objectMapper.writeValueAsBytes(header);

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        DataOutputStream dos = new DataOutputStream(baos);
        dos.writeInt(headerBytes.length);
        dos.write(headerBytes);
        dos.write(encryptedData);

        log.info("SHPS file generated for public upload, total size: {} bytes", baos.size());
        return baos.toByteArray();
    }

    /**
     * Потоковое шифрование в SHPS с возвратом составного InputStream.
     */
    @SuppressWarnings("resource")
    public ShpsEncryptedStream encryptForServerStreaming(InputStream plainInputStream,
            long plainSize,
            String originalFileName,
            UUID userId) throws Exception {
        log.info("Streaming encryption for public file: {}, size: {} bytes", originalFileName, plainSize);

        KeyGenerator keyGen = KeyGenerator.getInstance("AES");
        keyGen.init(AES_KEY_SIZE);
        SecretKey aesKey = keyGen.generateKey();

        byte[] iv = new byte[GCM_IV_LENGTH];
        new SecureRandom().nextBytes(iv);

        PublicKey serverPublicKey = serverKeyService.getPublicKey();
        Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        rsaCipher.init(Cipher.ENCRYPT_MODE, serverPublicKey);
        byte[] encryptedKey = rsaCipher.doFinal(aesKey.getEncoded());

        ShirmpsHeader header = new ShirmpsHeader();
        header.setVersion("1.0");
        header.setAlgorithm("AES-256-GCM");
        header.setKeyEncryption("RSA-OAEP");
        header.setKeyOwner("server");
        header.setUserId(userId.toString());
        header.setOriginalFileName(originalFileName);
        header.setOriginalFileSize(plainSize);
        header.setEncryptedKey(Base64.getEncoder().encodeToString(encryptedKey));
        header.setIv(Base64.getEncoder().encodeToString(iv));
        header.setSignature(null);
        header.setCreationDate(LocalDateTime.now());
        header.setMetadata(new HashMap<>());

        byte[] headerBytes = objectMapper.writeValueAsBytes(header);
        int headerLength = headerBytes.length;

        ByteArrayInputStream lengthStream = new ByteArrayInputStream(
                ByteBuffer.allocate(4).putInt(headerLength).array());
        ByteArrayInputStream headerStream = new ByteArrayInputStream(headerBytes);

        Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
        GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
        aesCipher.init(Cipher.ENCRYPT_MODE, aesKey, gcmSpec);
        CipherInputStream encryptedDataStream = new CipherInputStream(plainInputStream, aesCipher);

        InputStream combinedStream = new SequenceInputStream(
                new SequenceInputStream(lengthStream, headerStream),
                encryptedDataStream);

        long totalSize = 4L + headerLength + plainSize + (GCM_TAG_LENGTH / 8);

        return new ShpsEncryptedStream(combinedStream, totalSize);
    }

    /**
     * Шифрует данные из InputStream во временный файл на диске.
     */
    public java.io.File encryptForServerToTempFile(InputStream plainInputStream,
            long plainSize,
            String originalFileName,
            UUID userId) throws Exception {
        log.info("Encrypting to temp file: {}, size: {} bytes", originalFileName, plainSize);

        KeyGenerator keyGen = KeyGenerator.getInstance("AES");
        keyGen.init(AES_KEY_SIZE);
        SecretKey aesKey = keyGen.generateKey();

        byte[] iv = new byte[GCM_IV_LENGTH];
        new SecureRandom().nextBytes(iv);

        PublicKey serverPublicKey = serverKeyService.getPublicKey();

        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] pubEncoded = serverPublicKey.getEncoded();
        byte[] fingerprint = md.digest(pubEncoded);
        log.info("Encrypting with server public key fingerprint (SHA-256): {}", HexFormat.of().formatHex(fingerprint));

        Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        OAEPParameterSpec oaepParams = new OAEPParameterSpec(
                "SHA-256", "MGF1", MGF1ParameterSpec.SHA256, PSource.PSpecified.DEFAULT);
        rsaCipher.init(Cipher.ENCRYPT_MODE, serverPublicKey, oaepParams);
        byte[] encryptedKey = rsaCipher.doFinal(aesKey.getEncoded());

        ShirmpsHeader header = new ShirmpsHeader();
        header.setVersion("1.0");
        header.setAlgorithm("AES-256-GCM");
        header.setKeyEncryption("RSA-OAEP");
        header.setKeyOwner("server");
        header.setUserId(userId.toString());
        header.setOriginalFileName(originalFileName);
        header.setOriginalFileSize(plainSize);
        header.setEncryptedKey(Base64.getEncoder().encodeToString(encryptedKey));
        header.setIv(Base64.getEncoder().encodeToString(iv));
        header.setSignature(null);
        header.setCreationDate(LocalDateTime.now());
        header.setMetadata(new HashMap<>());

        byte[] headerBytes = objectMapper.writeValueAsBytes(header);
        int headerLength = headerBytes.length;

        Path tempFile = Files.createTempFile("shps-", ".tmp");
        try (OutputStream fos = Files.newOutputStream(tempFile);
                DataOutputStream dos = new DataOutputStream(fos)) {

            dos.writeInt(headerLength);
            dos.write(headerBytes);

            Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
            GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
            aesCipher.init(Cipher.ENCRYPT_MODE, aesKey, gcmSpec);

            try (CipherOutputStream cos = new CipherOutputStream(fos, aesCipher)) {
                byte[] buffer = new byte[8192];
                int read;
                while ((read = plainInputStream.read(buffer)) != -1) {
                    cos.write(buffer, 0, read);
                }
            }
        }

        Path finalTempFile = Files.createTempFile("shps-final-", ".shps");
        Files.copy(tempFile, finalTempFile, StandardCopyOption.REPLACE_EXISTING);
        Files.delete(tempFile);

        try (FileChannel fc = FileChannel.open(finalTempFile, StandardOpenOption.WRITE)) {
            fc.force(true);
        }

        log.info("SHPS data written to final temp file: {}, size: {} bytes", finalTempFile, Files.size(finalTempFile));
        return finalTempFile.toFile();
    }

}
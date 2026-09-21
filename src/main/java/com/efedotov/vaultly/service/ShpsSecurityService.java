package com.efedotov.vaultly.service;

import com.efedotov.vaultly.VaultlyApplication;
import com.efedotov.vaultly.shirmps.ShirmpsHeader;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.CipherInputStream;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.OAEPParameterSpec;
import javax.crypto.spec.PSource;
import javax.crypto.spec.SecretKeySpec;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.spec.MGF1ParameterSpec;
import java.util.Base64;
import java.util.UUID;
import java.util.zip.GZIPInputStream;

@Service
@RequiredArgsConstructor
@Slf4j
public class ShpsSecurityService {

    private static final int GCM_TAG_LENGTH = 128;
    private static final int BUFFER_SIZE = 8192;

    private final ServerKeyService serverKeyService;
    private final UserKeyService userKeyService;

    public boolean validateStructure(byte[] shpsBytes) throws Exception {
        return validateStructure(shpsBytes, null);
    }

    public boolean validateStructure(byte[] shpsBytes, String fileName) throws Exception {
        String fileInfo = (fileName != null) ? fileName : "unknown";
        log.info("Validating SHPS structure for file: {}", fileInfo);
        try (DataInputStream dis = new DataInputStream(new ByteArrayInputStream(shpsBytes))) {
            int headerLength = dis.readInt();
            if (headerLength <= 0 || headerLength > 20_000) {
                log.warn("Invalid header length ({}) for file: {}", headerLength, fileInfo);
                return false;
            }

            byte[] headerBytes = new byte[headerLength];
            dis.readFully(headerBytes);
            ShirmpsHeader header = ShirmpsHeader.fromJsonBytes(headerBytes);

            boolean isValid = "1.0".equals(header.getVersion()) &&
                    "AES-256-GCM".equals(header.getAlgorithm()) &&
                    header.getOriginalFileSize() != null &&
                    header.getOriginalFileSize() > 0;

            if (isValid) {
                log.info("Structure valid for file: {} (version={}, algorithm={}, originalSize={})",
                        fileInfo, header.getVersion(), header.getAlgorithm(), header.getOriginalFileSize());
            } else {
                log.warn("Structure invalid for file: {} (version={}, algorithm={}, originalSize={})",
                        fileInfo, header.getVersion(), header.getAlgorithm(), header.getOriginalFileSize());
            }
            return isValid;
        } catch (Exception e) {
            log.error("Error validating structure for file: {}", fileInfo, e);
            throw e;
        }
    }

    public boolean validateAndVerifyStreaming(byte[] shpsBytes, UUID userId) throws Exception {
        return validateAndVerifyStreaming(shpsBytes, userId, null);
    }

    public boolean validateAndVerifyStreaming(byte[] shpsBytes, UUID userId, String fileName) throws Exception {
        String fileInfo = (fileName != null) ? fileName : "unknown";
        log.info("Starting full SHPS validation for file: {}, user: {}", fileInfo, userId);
        try (ByteArrayInputStream bais = new ByteArrayInputStream(shpsBytes);
                DataInputStream dis = new DataInputStream(bais)) {

            int headerLength = dis.readInt();
            if (headerLength <= 0 || headerLength > 20_000) {
                throw new SecurityException("Invalid header length");
            }

            byte[] headerBytes = new byte[headerLength];
            dis.readFully(headerBytes);
            ShirmpsHeader header = ShirmpsHeader.fromJsonBytes(headerBytes);

            log.info(
                    "SHPS header for file {}: version={}, algorithm={}, keyEncryption={}, keyOwner={}, userId={}, originalSize={}",
                    fileInfo, header.getVersion(), header.getAlgorithm(), header.getKeyEncryption(),
                    header.getKeyOwner(), header.getUserId(), header.getOriginalFileSize());

            validateHeader(header, fileInfo);

            if (header.getSignature() == null) {
                throw new SecurityException("SHPS file must contain signature");
            }

            PublicKey userPublicKey = userKeyService.getPublicKey(userId);
            PrivateKey serverPrivateKey = serverKeyService.getPrivateKey();

            PrivateKey decryptionKey;
            if ("server".equals(header.getKeyOwner())) {
                decryptionKey = serverPrivateKey;
                log.info("File {} is encrypted for server, using server private key for decryption", fileInfo);
            } else {
                PrivateKey userPrivateKey = userKeyService.getPrivateKey(userId);
                if (userPrivateKey == null) {
                    throw new SecurityException("Cannot decrypt private file: user private key not available");
                }
                decryptionKey = userPrivateKey;
                log.info("File {} is encrypted for user, using user private key for decryption", fileInfo);
            }

            byte[] encryptedAesKey = Base64.getDecoder().decode(header.getEncryptedKey());
            Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
            rsaCipher.init(Cipher.DECRYPT_MODE, decryptionKey);
            byte[] aesKeyBytes = rsaCipher.doFinal(encryptedAesKey);
            SecretKey aesKey = new SecretKeySpec(aesKeyBytes, "AES");

            byte[] iv = Base64.getDecoder().decode(header.getIv());
            Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
            aesCipher.init(Cipher.DECRYPT_MODE, aesKey, new GCMParameterSpec(GCM_TAG_LENGTH, iv));

            boolean compressed = false;
            if (header.getMetadata() != null) {
                compressed = Boolean.parseBoolean(
                        header.getMetadata().getOrDefault("compressed", "false"));
            }
            log.info("File {} compressed: {}", fileInfo, compressed);

            try (CipherInputStream cis = new CipherInputStream(dis, aesCipher);
                    InputStream dataStream = compressed ? new GZIPInputStream(cis) : cis) {
                return verifySignatureInternal(dataStream, header, userPublicKey, userId, fileInfo);
            }
        }
    }

    public boolean validateAndVerify(byte[] shpsBytes, UUID userId) throws Exception {
        return validateAndVerify(shpsBytes, userId, null);
    }

    public boolean validateAndVerify(byte[] shpsBytes, UUID userId, String fileName) throws Exception {
        String fileInfo = (fileName != null) ? fileName : "unknown";
        log.info("Starting full SHPS validation (non-streaming) for file: {}, user: {}", fileInfo, userId);
        ShirmpsHeader header;

        try (DataInputStream dis = new DataInputStream(new ByteArrayInputStream(shpsBytes))) {
            int headerLength = dis.readInt();
            if (headerLength <= 0 || headerLength > 20_000) {
                throw new SecurityException("Invalid header length");
            }

            byte[] headerBytes = new byte[headerLength];
            dis.readFully(headerBytes);
            header = ShirmpsHeader.fromJsonBytes(headerBytes);
        }

        validateHeader(header, fileInfo);

        if (header.getSignature() == null) {
            throw new SecurityException("SHPS file must contain signature");
        }

        PublicKey userPublicKey = userKeyService.getPublicKey(userId);
        PrivateKey serverPrivateKey = serverKeyService.getPrivateKey();

        PrivateKey decryptionKey;
        if ("server".equals(header.getKeyOwner())) {
            decryptionKey = serverPrivateKey;
            log.info("File {} is encrypted for server", fileInfo);
        } else {
            PrivateKey userPrivateKey = userKeyService.getPrivateKey(userId);
            if (userPrivateKey == null) {
                throw new SecurityException("Cannot decrypt private file: user private key not available");
            }
            decryptionKey = userPrivateKey;
            log.info("File {} is encrypted for user", fileInfo);
        }

        byte[] encryptedAesKey = Base64.getDecoder().decode(header.getEncryptedKey());
        Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        rsaCipher.init(Cipher.DECRYPT_MODE, decryptionKey);
        byte[] aesKeyBytes = rsaCipher.doFinal(encryptedAesKey);
        SecretKey aesKey = new SecretKeySpec(aesKeyBytes, "AES");

        byte[] iv = Base64.getDecoder().decode(header.getIv());
        Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
        aesCipher.init(Cipher.DECRYPT_MODE, aesKey, new GCMParameterSpec(GCM_TAG_LENGTH, iv));

        try (DataInputStream dataDis = new DataInputStream(new ByteArrayInputStream(shpsBytes))) {
            int headerLength = dataDis.readInt();
            dataDis.skipBytes(headerLength);

            boolean compressed = false;
            if (header.getMetadata() != null) {
                compressed = Boolean.parseBoolean(
                        header.getMetadata().getOrDefault("compressed", "false"));
            }

            if (compressed) {
                try (CipherInputStream cis = new CipherInputStream(dataDis, aesCipher);
                        GZIPInputStream gzip = new GZIPInputStream(cis)) {
                    return verifySignature(gzip, header, userPublicKey, userId, fileInfo);
                }
            } else {
                try (CipherInputStream cis = new CipherInputStream(dataDis, aesCipher)) {
                    return verifySignature(cis, header, userPublicKey, userId, fileInfo);
                }
            }
        }
    }

    public ShirmpsHeader validateHeaderOnly(byte[] shpsBytes) throws Exception {
        return validateHeaderOnly(shpsBytes, null);
    }

    public ShirmpsHeader validateHeaderOnly(byte[] shpsBytes, String fileName) throws Exception {
        String fileInfo = (fileName != null) ? fileName : "unknown";
        log.info("Validating header only for file: {}", fileInfo);
        try (DataInputStream dis = new DataInputStream(new ByteArrayInputStream(shpsBytes))) {
            int headerLength = dis.readInt();
            if (headerLength <= 0 || headerLength > 20_000) {
                throw new SecurityException("Invalid header length");
            }

            byte[] headerBytes = new byte[headerLength];
            dis.readFully(headerBytes);
            ShirmpsHeader header = ShirmpsHeader.fromJsonBytes(headerBytes);

            validateHeader(header, fileInfo);
            return header;
        }
    }

    public ShirmpsHeader validateHeaderOnly(Path shpsFilePath, String fileName) throws Exception {
        String fileInfo = (fileName != null) ? fileName : shpsFilePath.getFileName().toString();
        log.info("Validating header only for file: {}", fileInfo);

        try (InputStream fis = Files.newInputStream(shpsFilePath);
                DataInputStream dis = new DataInputStream(fis)) {

            int headerLength = dis.readInt();
            if (headerLength <= 0 || headerLength > 20_000) {
                throw new SecurityException("Invalid header length: " + headerLength);
            }

            byte[] headerBytes = new byte[headerLength];
            dis.readFully(headerBytes);
            ShirmpsHeader header = ShirmpsHeader.fromJsonBytes(headerBytes);

            validateHeader(header, fileInfo);
            return header;
        }
    }

    public boolean validateAndVerifyStreaming(Path shpsFilePath, UUID userId, String fileName) throws Exception {
        String fileInfo = (fileName != null) ? fileName : shpsFilePath.getFileName().toString();
        log.info("Starting full SHPS validation for file: {}, user: {}", fileInfo, userId);

        try (InputStream fis = Files.newInputStream(shpsFilePath);
                DataInputStream dis = new DataInputStream(fis)) {

            int headerLength = dis.readInt();
            if (headerLength <= 0 || headerLength > 20_000) {
                throw new SecurityException("Invalid header length: " + headerLength);
            }

            byte[] headerBytes = new byte[headerLength];
            dis.readFully(headerBytes);
            ShirmpsHeader header = ShirmpsHeader.fromJsonBytes(headerBytes);

            log.info(
                    "SHPS header for file {}: version={}, algorithm={}, keyEncryption={}, keyOwner={}, userId={}, originalSize={}",
                    fileInfo, header.getVersion(), header.getAlgorithm(), header.getKeyEncryption(),
                    header.getKeyOwner(), header.getUserId(), header.getOriginalFileSize());

            validateHeader(header, fileInfo);

            if (header.getSignature() == null) {
                throw new SecurityException("SHPS file must contain signature");
            }

            PublicKey userPublicKey = userKeyService.getPublicKey(userId);
            PrivateKey serverPrivateKey = serverKeyService.getPrivateKey();

            PrivateKey decryptionKey;
            if ("server".equals(header.getKeyOwner())) {
                decryptionKey = serverPrivateKey;
                log.info("File {} is encrypted for server, using server private key for decryption", fileInfo);
            } else {
                PrivateKey userPrivateKey = userKeyService.getPrivateKey(userId);
                if (userPrivateKey == null) {
                    throw new SecurityException("Cannot decrypt private file: user private key not available");
                }
                decryptionKey = userPrivateKey;
                log.info("File {} is encrypted for user, using user private key for decryption", fileInfo);
            }

            byte[] encryptedAesKey = Base64.getDecoder().decode(header.getEncryptedKey());
            Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
            rsaCipher.init(Cipher.DECRYPT_MODE, decryptionKey);
            byte[] aesKeyBytes = rsaCipher.doFinal(encryptedAesKey);
            SecretKey aesKey = new SecretKeySpec(aesKeyBytes, "AES");

            byte[] iv = Base64.getDecoder().decode(header.getIv());
            Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
            aesCipher.init(Cipher.DECRYPT_MODE, aesKey, new GCMParameterSpec(GCM_TAG_LENGTH, iv));

            boolean compressed = false;
            if (header.getMetadata() != null) {
                compressed = Boolean.parseBoolean(
                        header.getMetadata().getOrDefault("compressed", "false"));
            }
            log.info("File {} compressed: {}", fileInfo, compressed);

            try (CipherInputStream cis = new CipherInputStream(dis, aesCipher);
                    InputStream dataStream = compressed ? new GZIPInputStream(cis) : cis) {
                return verifySignatureInternal(dataStream, header, userPublicKey, userId, fileInfo);
            }
        }
    }

    /**
     * Расшифровывает SHPS-файл, зашифрованный сервером для публичного доступа.
     */
    public byte[] decryptServerEncrypted(byte[] shpsBytes, String fileName) throws Exception {
        String fileInfo = (fileName != null) ? fileName : "unknown";
        log.info("Decrypting server-encrypted public file: {}", fileInfo);

        try (ByteArrayInputStream bais = new ByteArrayInputStream(shpsBytes);
                DataInputStream dis = new DataInputStream(bais)) {

            int headerLength = dis.readInt();
            if (headerLength <= 0 || headerLength > 20_000) {
                throw new SecurityException("Invalid header length: " + headerLength);
            }

            byte[] headerBytes = new byte[headerLength];
            dis.readFully(headerBytes);
            ShirmpsHeader header = ShirmpsHeader.fromJsonBytes(headerBytes);

            validateHeader(header, fileInfo);

            if (!"server".equals(header.getKeyOwner())) {
                throw new SecurityException("File is not encrypted for server (keyOwner=" + header.getKeyOwner() + ")");
            }

            PrivateKey serverPrivateKey = serverKeyService.getPrivateKey();
            byte[] encryptedAesKey = Base64.getDecoder().decode(header.getEncryptedKey());
            Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
            rsaCipher.init(Cipher.DECRYPT_MODE, serverPrivateKey);
            byte[] aesKeyBytes = rsaCipher.doFinal(encryptedAesKey);
            SecretKey aesKey = new SecretKeySpec(aesKeyBytes, "AES");

            byte[] iv = Base64.getDecoder().decode(header.getIv());
            Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
            aesCipher.init(Cipher.DECRYPT_MODE, aesKey, new GCMParameterSpec(GCM_TAG_LENGTH, iv));

            boolean compressed = false;
            if (header.getMetadata() != null) {
                compressed = Boolean.parseBoolean(header.getMetadata().getOrDefault("compressed", "false"));
            }

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            try (CipherInputStream cis = new CipherInputStream(dis, aesCipher);
                    InputStream is = compressed ? new GZIPInputStream(cis) : cis) {
                byte[] buffer = new byte[BUFFER_SIZE];
                int read;
                long total = 0;
                while ((read = is.read(buffer)) != -1) {
                    baos.write(buffer, 0, read);
                    total += read;
                }

                if (total != header.getOriginalFileSize()) {
                    throw new SecurityException("File size mismatch after decryption. Expected: " +
                            header.getOriginalFileSize() + ", got: " + total);
                }
            }

            log.info("Public file decrypted successfully: {}, size: {} bytes", fileInfo, baos.size());
            return baos.toByteArray();
        }
    }

    private boolean verifySignature(InputStream dataStream, ShirmpsHeader header,
            PublicKey userPublicKey, UUID userId, String fileName) throws Exception {
        String fileInfo = (fileName != null) ? fileName : "unknown";
        java.security.Signature signature = java.security.Signature.getInstance("SHA256withRSA");
        signature.initVerify(userPublicKey);

        byte[] buffer = new byte[BUFFER_SIZE];
        int read;
        long total = 0;

        while ((read = dataStream.read(buffer)) != -1) {
            signature.update(buffer, 0, read);
            total += read;
        }

        if (total != header.getOriginalFileSize()) {
            throw new SecurityException("File size mismatch after decryption. Expected: " +
                    header.getOriginalFileSize() + ", got: " + total);
        }

        byte[] sigBytes = Base64.getDecoder().decode(header.getSignature());
        boolean signatureValid = signature.verify(sigBytes);

        if (!signatureValid) {
            throw new SecurityException("Digital signature verification failed");
        }

        log.info("SHPS file validated and verified for user {} (file: {})", userId, fileInfo);
        return true;
    }

    private boolean verifySignatureInternal(InputStream dataStream, ShirmpsHeader header,
            PublicKey userPublicKey, UUID userId, String fileName) throws Exception {
        return verifySignature(dataStream, header, userPublicKey, userId, fileName);
    }

    private void validateHeader(ShirmpsHeader header, String fileName) throws SecurityException {
        String fileInfo = (fileName != null) ? fileName : "unknown";
        if (!"1.0".equals(header.getVersion())) {
            throw new SecurityException("Unsupported SHPS version: " + header.getVersion());
        }
        if (!"AES-256-GCM".equals(header.getAlgorithm())) {
            throw new SecurityException("Invalid encryption algorithm: " + header.getAlgorithm());
        }
        if (!"RSA-OAEP".equals(header.getKeyEncryption())) {
            throw new SecurityException("Invalid key encryption algorithm: " + header.getKeyEncryption());
        }
        if (header.getOriginalFileSize() == null || header.getOriginalFileSize() <= 0) {
            throw new SecurityException("Invalid original file size: " + header.getOriginalFileSize());
        }
        if (header.getUserId() == null || header.getUserId().isBlank()) {
            throw new SecurityException("User ID missing in SHPS header");
        }
        log.info("Header validation passed for file {}: userId={}, originalSize={}",
                fileInfo, header.getUserId(), header.getOriginalFileSize());
    }

    public void decryptServerEncryptedToOutputStream(InputStream shpsInputStream, OutputStream outputStream,
            String fileName) throws Exception {

        Path tempShps = Files.createTempFile("shps-", ".tmp");
        Files.copy(shpsInputStream, tempShps, StandardCopyOption.REPLACE_EXISTING);

        Path tempDecrypted = Files.createTempFile("decrypted-", ".tmp");
        try {

            String privateKeyPath = System.getProperty("SERVER_PRIVATE_KEY_PATH");
            if (privateKeyPath == null) {
                throw new IllegalStateException("SERVER_PRIVATE_KEY_PATH not set in environment");
            }

            String jarPath = VaultlyApplication.class
                    .getProtectionDomain()
                    .getCodeSource()
                    .getLocation()
                    .toURI()
                    .getPath();

            ProcessBuilder pb = new ProcessBuilder(
                    "java", "-Xmx256m", "-cp", jarPath,
                    "com.efedotov.vaultly.DecryptUtil",
                    tempShps.toString(), tempDecrypted.toString(), privateKeyPath);
            pb.redirectErrorStream(true);
            Process p = pb.start();
            int exitCode = p.waitFor();
            if (exitCode != 0) {
                String error = new String(p.getInputStream().readAllBytes());
                throw new RuntimeException("Decryption failed: " + error);
            }

            Files.copy(tempDecrypted, outputStream);
        } finally {
            Files.deleteIfExists(tempShps);
            Files.deleteIfExists(tempDecrypted);
        }
    }

    public ShirmpsHeader extractHeader(InputStream shpsInputStream) throws Exception {
        DataInputStream dis = new DataInputStream(shpsInputStream);
        int headerLength = dis.readInt();
        if (headerLength <= 0 || headerLength > 20_000) {
            throw new SecurityException("Invalid header length");
        }
        byte[] headerBytes = new byte[headerLength];
        dis.readFully(headerBytes);
        return ShirmpsHeader.fromJsonBytes(headerBytes);
    }

    public void decryptServerEncryptedToStream(InputStream shpsInputStream, OutputStream outputStream)
            throws Exception {
        DataInputStream dis = new DataInputStream(shpsInputStream);

        int headerLength = dis.readInt();
        if (headerLength <= 0 || headerLength > 20_000) {
            throw new SecurityException("Invalid header length: " + headerLength);
        }

        byte[] headerBytes = new byte[headerLength];
        dis.readFully(headerBytes);
        ShirmpsHeader header = ShirmpsHeader.fromJsonBytes(headerBytes);

        validateHeader(header, "stream");

        if (!"server".equals(header.getKeyOwner())) {
            throw new SecurityException("File is not encrypted for server");
        }

        PrivateKey serverPrivateKey = serverKeyService.getPrivateKey();
        byte[] encryptedAesKey = Base64.getDecoder().decode(header.getEncryptedKey());
        Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");

        OAEPParameterSpec oaepParams = new OAEPParameterSpec(
                "SHA-256", "MGF1", MGF1ParameterSpec.SHA256, PSource.PSpecified.DEFAULT);
        rsaCipher.init(Cipher.DECRYPT_MODE, serverPrivateKey, oaepParams);

        byte[] aesKeyBytes = rsaCipher.doFinal(encryptedAesKey);
        SecretKey aesKey = new SecretKeySpec(aesKeyBytes, "AES");

        byte[] iv = Base64.getDecoder().decode(header.getIv());
        Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
        aesCipher.init(Cipher.DECRYPT_MODE, aesKey, new GCMParameterSpec(GCM_TAG_LENGTH, iv));

        boolean compressed = false;
        if (header.getMetadata() != null) {
            compressed = Boolean.parseBoolean(header.getMetadata().getOrDefault("compressed", "false"));
        }

        try (CipherInputStream cis = new CipherInputStream(dis, aesCipher);
                InputStream finalStream = compressed ? new GZIPInputStream(cis) : cis) {

            byte[] buffer = new byte[8192];
            int read;
            while ((read = finalStream.read(buffer)) != -1) {
                outputStream.write(buffer, 0, read);
            }
        }
    }
}
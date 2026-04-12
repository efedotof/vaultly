package com.efedotov.vaultly.controller;

import com.efedotov.vaultly.dto.file.DecryptionMetadata;
import com.efedotov.vaultly.dto.file.FileDto;
import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.*;
import com.efedotov.vaultly.shirmps.ShirmpsHeader;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import javax.crypto.spec.OAEPParameterSpec;
import javax.crypto.spec.PSource;
import java.security.MessageDigest;
import java.util.HexFormat;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.spec.MGF1ParameterSpec;
import java.time.Duration;
import java.util.Base64;
import java.util.UUID;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;

@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
@Slf4j
public class FileRestController {

    private final S3Service s3Service;
    private final ShpsSecurityService shpsSecurityService;
    private final FileService fileService;
    private final FolderService folderService;
    private final ShpsEncryptionService shpsEncryptionService;
    private final ServerKeyService serverKeyService;
    private final UserKeyService userKeyService;

    @PostMapping("/upload/shps")
    public FileDto uploadShps(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "folderId", required = false) UUID folderId,
            @RequestParam("isPublic") boolean isPublic,
            @AuthenticationPrincipal CustomUserDetails user) throws Exception {

        UUID userId = user.getUserId();
        String originalFilename = file.getOriginalFilename();
        long fileSize = file.getSize();

        log.info("REST upload SHPS file: {}, size: {} bytes, isPublic: {}, user: {}",
                originalFilename, fileSize, isPublic, userId);

        Path tempFile = Files.createTempFile("shps-upload-", ".shps");
        try (InputStream inputStream = file.getInputStream()) {
            Files.copy(inputStream, tempFile, java.nio.file.StandardCopyOption.REPLACE_EXISTING);

            ShirmpsHeader header;
            try {
                header = shpsSecurityService.validateHeaderOnly(tempFile, originalFilename);
                log.info("Structure validation passed for file: {}", originalFilename);
            } catch (Exception e) {
                log.error("SHPS structure validation failed for file: {}", originalFilename, e);
                throw new RuntimeException("SHPS structure validation failed: " + e.getMessage(), e);
            }

            if (isPublic) {
                if (!"server".equals(header.getKeyOwner())) {
                    throw new SecurityException("Public file must be encrypted for server (keyOwner=server)");
                }
                try {
                    shpsSecurityService.validateAndVerifyStreaming(tempFile, userId, originalFilename);
                    log.info("Full validation and signature verification passed for file: {}", originalFilename);
                } catch (Exception e) {
                    log.error("SHPS validation failed for file: {}", originalFilename, e);
                    throw new RuntimeException("SHPS validation failed: " + e.getMessage(), e);
                }
            } else {
                if (!"user".equals(header.getKeyOwner())) {
                    throw new SecurityException("Private file must be encrypted for user (keyOwner=user)");
                }
                if (!userId.toString().equals(header.getUserId())) {
                    throw new SecurityException("Private file belongs to a different user");
                }
                log.info("Private file structure validated, skipping decryption");
            }

            String shpsFileName = originalFilename.endsWith(".shps") ? originalFilename : originalFilename + ".shps";
            String url = s3Service.uploadFileWithMultipart(tempFile, shpsFileName, "application/x-shirmps");
            String s3Key = s3Service.getObjectKeyFromUrl(url);

            File createdFile = fileService.createFile(
                    originalFilename,
                    originalFilename,
                    s3Key,
                    url,
                    Files.size(tempFile),
                    "application/x-shirmps",
                    userId,
                    true,
                    isPublic);

            if (folderId != null) {
                createdFile = folderService.addFileToFolder(createdFile.getId(), folderId, userId);
            }

            log.info("SHPS file uploaded successfully: {} (name: {}, public: {})",
                    createdFile.getId(), originalFilename, isPublic);

            return mapToDto(createdFile);
        } finally {
            Files.deleteIfExists(tempFile);
        }
    }

    @PostMapping("/upload/public")
    public FileDto uploadPublicFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "folderId", required = false) UUID folderId,
            @AuthenticationPrincipal CustomUserDetails user) throws Exception {

        UUID userId = user.getUserId();
        String originalFilename = file.getOriginalFilename();
        long fileSize = file.getSize();

        log.info("REST upload public file: {}, size: {} bytes", originalFilename, fileSize);

        java.io.File tempShpsFile = null;
        try (InputStream plainStream = file.getInputStream()) {
            tempShpsFile = shpsEncryptionService.encryptForServerToTempFile(
                    plainStream, fileSize, originalFilename, userId);

            String shpsFileName = originalFilename + ".shps";
            String url = s3Service.uploadFileWithMultipart(tempShpsFile.toPath(), shpsFileName,
                    "application/x-shirmps");
            String s3Key = s3Service.getObjectKeyFromUrl(url);

            File createdFile = fileService.createFile(
                    originalFilename, originalFilename, s3Key, url,
                    tempShpsFile.length(), "application/x-shirmps",
                    userId, true, true);

            if (folderId != null) {
                createdFile = folderService.addFileToFolder(createdFile.getId(), folderId, userId);
            }

            log.info("Public file encrypted and uploaded: {}", createdFile.getId());
            return mapToDto(createdFile);
        } finally {
            if (tempShpsFile != null && tempShpsFile.exists()) {
                tempShpsFile.delete();
            }
        }
    }

    @GetMapping
    public ResponseEntity<Page<FileDto>> getAllFiles(
            @AuthenticationPrincipal CustomUserDetails user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        UUID userId = user.getUserId();
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());

        Page<File> filesPage = fileService.getAllFilesForUser(userId, pageable);
        Page<FileDto> dtoPage = filesPage.map(this::mapToDto);

        return ResponseEntity.ok(dtoPage);
    }

    @GetMapping("/recent")
    public ResponseEntity<Page<FileDto>> getRecentFiles(
            @AuthenticationPrincipal CustomUserDetails user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        UUID userId = user.getUserId();
        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());

        Page<File> filesPage = fileService.getLatestFilesForUser(userId, pageable);
        Page<FileDto> dtoPage = filesPage.map(this::mapToDto);

        return ResponseEntity.ok(dtoPage);
    }

    @GetMapping("/{fileId}/download")
    public ResponseEntity<Void> downloadFile(
            @PathVariable UUID fileId,
            @AuthenticationPrincipal CustomUserDetails user) {

        UUID userId = user.getUserId();
        File file = fileService.getFileById(fileId, userId);

        log.info("Generating presigned URL for file: {} (name: {}) for user: {}",
                fileId, file.getOriginalName(), userId);

        Duration duration = Duration.ofSeconds(30);
        String presignedUrl = s3Service.generatePresignedUrl(file.getS3Key(), duration);

        return ResponseEntity.status(HttpStatus.SEE_OTHER)
                .header(HttpHeaders.LOCATION, presignedUrl)
                .build();
    }

    @GetMapping("/{fileId}/content")
    public ResponseEntity<DecryptionMetadata> getDecryptionMetadata(
            @PathVariable UUID fileId,
            @AuthenticationPrincipal CustomUserDetails user) throws Exception {

        UUID userId = user.getUserId();
        File file = fileService.getFileById(fileId, userId);
        if (!file.getIsPublic()) {
            throw new SecurityException("Only public files supported");
        }

        ShirmpsHeader header;
        try (InputStream s3Stream = s3Service.getObjectStream(file.getS3Key())) {
            header = shpsSecurityService.extractHeader(s3Stream);
        }

        log.info(
                "SHPS header extracted: version={}, algorithm={}, keyEncryption={}, keyOwner={}, userId={}, originalSize={}",
                header.getVersion(), header.getAlgorithm(), header.getKeyEncryption(),
                header.getKeyOwner(), header.getUserId(), header.getOriginalFileSize());

        String encryptedKeyBase64 = header.getEncryptedKey();
        log.info("Encrypted AES key (Base64): length={}, first 20 chars: {}",
                encryptedKeyBase64 != null ? encryptedKeyBase64.length() : 0,
                encryptedKeyBase64 != null && encryptedKeyBase64.length() > 20
                        ? encryptedKeyBase64.substring(0, 20)
                        : encryptedKeyBase64);

        if (encryptedKeyBase64 == null || encryptedKeyBase64.isBlank()) {
            throw new SecurityException("Encrypted AES key is missing in SHPS header");
        }

        PrivateKey serverPrivateKey = serverKeyService.getPrivateKey();
        PublicKey serverPublicKey = serverKeyService.getPublicKey();

        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] pubEncoded = serverPublicKey.getEncoded();
        byte[] fingerprint = md.digest(pubEncoded);
        log.info("Decrypting with server public key fingerprint (SHA-256): {}", HexFormat.of().formatHex(fingerprint));

        byte[] encryptedAesKey = Base64.getDecoder().decode(encryptedKeyBase64);
        log.info("Encrypted AES key (decoded): length={} bytes (expected 256 for RSA-2048 OAEP)",
                encryptedAesKey.length);

        Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        OAEPParameterSpec oaepParams = new OAEPParameterSpec(
                "SHA-256", "MGF1", MGF1ParameterSpec.SHA256, PSource.PSpecified.DEFAULT);
        rsaCipher.init(Cipher.DECRYPT_MODE, serverPrivateKey, oaepParams);

        byte[] aesKeyBytes;
        try {
            aesKeyBytes = rsaCipher.doFinal(encryptedAesKey);
            log.info("AES key successfully decrypted, length: {} bytes", aesKeyBytes.length);
        } catch (BadPaddingException e) {
            log.error(
                    "BadPaddingException during AES key decryption. Possible cause: key encrypted for different public key, corrupted header, or wrong keyOwner.");
            throw e;
        }

        PublicKey userPublicKey = userKeyService.getPublicKey(userId);
        md = MessageDigest.getInstance("SHA-256");
        pubEncoded = userPublicKey.getEncoded();
        fingerprint = md.digest(pubEncoded);
        log.info("User public key fingerprint: {}", HexFormat.of().formatHex(fingerprint));
        log.info("User public key algorithm: {}, format: {}", userPublicKey.getAlgorithm(), userPublicKey.getFormat());

        rsaCipher.init(Cipher.ENCRYPT_MODE, userPublicKey, oaepParams);
        byte[] reEncryptedKey = rsaCipher.doFinal(aesKeyBytes);
        log.info("Re-encrypted AES key length: {} bytes", reEncryptedKey.length);

        Duration duration = Duration.ofMinutes(10);
        String presignedUrl = s3Service.generatePresignedUrl(file.getS3Key(), duration);

        DecryptionMetadata metadata = new DecryptionMetadata();
        metadata.setPresignedUrl(presignedUrl);
        metadata.setEncryptedKey(Base64.getEncoder().encodeToString(reEncryptedKey));
        metadata.setIv(header.getIv());
        metadata.setOriginalSize(header.getOriginalFileSize());
        metadata.setMimeType(file.getMimeType());
        metadata.setFileName(file.getOriginalName());

        return ResponseEntity.ok(metadata);
    }

    @DeleteMapping("/{fileId}")
    public ResponseEntity<Void> deleteFile(
            @PathVariable UUID fileId,
            @AuthenticationPrincipal CustomUserDetails user) {

        UUID userId = user.getUserId();
        log.info("REST delete file: {} requested by user: {}", fileId, userId);

        fileService.deleteFile(fileId, userId);
        return ResponseEntity.noContent().build();
    }

    private FileDto mapToDto(File file) {
        FileDto dto = new FileDto();
        dto.setId(file.getId());
        dto.setName(file.getName());
        dto.setOriginalName(file.getOriginalName());
        dto.setSize(file.getSize());
        dto.setMimeType(file.getMimeType());
        dto.setS3Url(file.getS3Url());
        dto.setIsEncrypted(file.getIsEncrypted());
        dto.setIsPublic(file.getIsPublic());
        dto.setCreatedAt(file.getCreatedAt());

        if (file.getFolder() != null) {
            dto.setFolderId(file.getFolder().getId());
            dto.setFolderName(file.getFolder().getName());
        } else {
            dto.setFolderId(null);
            dto.setFolderName(null);
        }

        return dto;
    }
}
package com.efedotov.vaultly.controller;

import java.io.InputStream;
import java.security.MessageDigest;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.spec.MGF1ParameterSpec;
import java.time.Duration;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Map;
import java.util.UUID;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.spec.OAEPParameterSpec;
import javax.crypto.spec.PSource;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.efedotov.vaultly.dto.file.CheckDuplicateRequest;
import com.efedotov.vaultly.dto.file.DecryptionMetadata;
import com.efedotov.vaultly.dto.file.FileDto;
import com.efedotov.vaultly.dto.file.LinkFileRequest;
import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.FileService;
import com.efedotov.vaultly.service.S3Service;
import com.efedotov.vaultly.service.ServerKeyService;
import com.efedotov.vaultly.service.ShpsSecurityService;
import com.efedotov.vaultly.service.UserKeyService;
import com.efedotov.vaultly.shirmps.ShirmpsHeader;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
@Slf4j
public class FileRestController {

    private final S3Service s3Service;
    private final ShpsSecurityService shpsSecurityService;
    private final FileService fileService;
    private final ServerKeyService serverKeyService;
    private final UserKeyService userKeyService;

    @PostMapping("/upload/shps")
    public FileDto uploadShps(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "folderId", required = false) UUID folderId,
            @RequestParam("isPublic") boolean isPublic,
            @RequestParam(value = "contentHash", required = false) String contentHash,
            @AuthenticationPrincipal CustomUserDetails user) throws Exception {

        UUID userId = user.getUserId();
        return fileService.uploadShpsFile(file, folderId, isPublic, contentHash, userId);
    }

    @PostMapping("/upload/public")
    public FileDto uploadPublicFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "folderId", required = false) UUID folderId,
            @RequestParam(value = "contentHash", required = false) String contentHash,
            @AuthenticationPrincipal CustomUserDetails user) throws Exception {

        UUID userId = user.getUserId();
        return fileService.uploadPublicFile(file, folderId, contentHash, userId);
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
    public ResponseEntity<Map<String, String>> downloadFile(
            @PathVariable UUID fileId,
            @AuthenticationPrincipal CustomUserDetails user) {

        UUID userId = user.getUserId();
        File file = fileService.getFileById(fileId, userId);

        log.info("Generating presigned URL for file: {} (name: {}) for user: {}",
                fileId, file.getOriginalName(), userId);

        Duration duration = Duration.ofSeconds(30);
        String s3Key = file.getFileContent() != null ? file.getFileContent().getS3Key() : null;
        if (s3Key == null) {
            throw new IllegalStateException("File has no associated content");
        }
        String presignedUrl = s3Service.generatePresignedUrl(s3Key, duration);

        return ResponseEntity.ok(Map.of("url", presignedUrl));
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

        String s3Key = file.getFileContent() != null ? file.getFileContent().getS3Key() : null;
        if (s3Key == null) {
            throw new IllegalStateException("File has no associated content");
        }

        ShirmpsHeader header;
        try (InputStream s3Stream = s3Service.getObjectStream(s3Key)) {
            header = shpsSecurityService.extractHeader(s3Stream);
        }

        log.info(
                "SHPS header extracted: version={}, algorithm={}, keyEncryption={}, keyOwner={}, userId={}, originalSize={}",
                header.getVersion(), header.getAlgorithm(), header.getKeyEncryption(),
                header.getKeyOwner(), header.getUserId(), header.getOriginalFileSize());

        String encryptedKeyBase64 = header.getEncryptedKey();
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

        Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        OAEPParameterSpec oaepParams = new OAEPParameterSpec(
                "SHA-256", "MGF1", MGF1ParameterSpec.SHA256, PSource.PSpecified.DEFAULT);
        rsaCipher.init(Cipher.DECRYPT_MODE, serverPrivateKey, oaepParams);

        byte[] aesKeyBytes;
        try {
            aesKeyBytes = rsaCipher.doFinal(encryptedAesKey);
        } catch (BadPaddingException e) {
            log.error("BadPaddingException during AES key decryption.");
            throw e;
        }

        PublicKey userPublicKey = userKeyService.getPublicKey(userId);
        rsaCipher.init(Cipher.ENCRYPT_MODE, userPublicKey, oaepParams);
        byte[] reEncryptedKey = rsaCipher.doFinal(aesKeyBytes);

        Duration duration = Duration.ofMinutes(10);
        String presignedUrl = s3Service.generatePresignedUrl(s3Key, duration);

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

    @GetMapping("/notes")
    public ResponseEntity<Page<FileDto>> getNotes(
            @AuthenticationPrincipal CustomUserDetails user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        UUID userId = user.getUserId();
        Page<File> notesPage = fileService.getUsersNodes(userId, page, size);
        Page<FileDto> dtoPage = notesPage.map(this::mapToDto);
        return ResponseEntity.ok(dtoPage);
    }

    @PostMapping("/notes")
    public FileDto createNote(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "folderId", required = false) UUID folderId,
            @AuthenticationPrincipal CustomUserDetails user) throws Exception {

        UUID userId = user.getUserId();
        File note = fileService.createNote(file, folderId, userId);
        return mapToDto(note);
    }

    @PutMapping("/notes/{noteId}/content")
    public FileDto updateNoteContent(
            @PathVariable UUID noteId,
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal CustomUserDetails user) throws Exception {

        UUID userId = user.getUserId();
        File updatedNote = fileService.updateNoteContent(noteId, file, userId);
        return mapToDto(updatedNote);
    }

    @PostMapping("/check-duplicate")
    public ResponseEntity<Map<String, Object>> checkDuplicate(
            @RequestBody CheckDuplicateRequest request,
            @AuthenticationPrincipal CustomUserDetails user) {

        UUID existingFileContentId = fileService.findExistingFileContentId(
                request.getHash(), request.getIsPublic());
        if (existingFileContentId != null) {
            return ResponseEntity.ok(Map.of(
                    "exists", true,
                    "fileContentId", existingFileContentId.toString()));
        } else {
            return ResponseEntity.ok(Map.of("exists", false));
        }
    }

    @PostMapping("/link")
    public FileDto linkExistingFile(
            @RequestBody LinkFileRequest request,
            @AuthenticationPrincipal CustomUserDetails user) {

        UUID userId = user.getUserId();
        File file = fileService.linkExistingFile(
                userId,
                request.getFileContentId(),
                request.getFileName(),
                request.getFolderId(),
                request.getIsPublic());
        return mapToDto(file);
    }

    private FileDto mapToDto(File file) {
        FileDto dto = new FileDto();
        dto.setId(file.getId());
        dto.setName(file.getName());
        dto.setOriginalName(file.getOriginalName());
        dto.setSize(file.getSize());
        dto.setMimeType(file.getMimeType());
        if (file.getFileContent() != null) {
            dto.setS3Url(file.getFileContent().getS3Url());
        }
        dto.setIsEncrypted(file.getIsEncrypted());
        dto.setIsPublic(file.getIsPublic());
        dto.setIsNote(file.getIsNote());
        dto.setCreatedAt(file.getCreatedAt());
        dto.setUpdatedAt(file.getUpdatedAt());

        if (file.getFolder() != null) {
            dto.setFolderId(file.getFolder().getId());
            dto.setFolderName(file.getFolder().getName());
        }

        return dto;
    }
}
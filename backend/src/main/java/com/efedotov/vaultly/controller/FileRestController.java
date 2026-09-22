package com.efedotov.vaultly.controller;

import java.time.Duration;
import java.util.Map;
import java.util.UUID;

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
import com.efedotov.vaultly.exception.BadRequestException;
import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.FileService;
import com.efedotov.vaultly.service.S3Service;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
@Slf4j
public class FileRestController {

    private static final int MAX_PAGE_SIZE = 100;

    private final S3Service s3Service;
    private final FileService fileService;

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

        validatePageParams(page, size);
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

        validatePageParams(page, size);
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
            @AuthenticationPrincipal CustomUserDetails user) {

        UUID userId = user.getUserId();
        DecryptionMetadata metadata = fileService.getDecryptionMetadataForUser(fileId, userId);
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

        validatePageParams(page, size);
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

        boolean exists = fileService.existsFileContentForUser(
                request.getHash(), request.getIsPublic(), user.getUserId());
        return ResponseEntity.ok(Map.of("exists", exists));
    }

    @PostMapping("/link")
    public FileDto linkExistingFile(
            @Valid @RequestBody LinkFileRequest request,
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

    private void validatePageParams(int page, int size) {
        if (page < 0 || size < 1 || size > MAX_PAGE_SIZE) {
            throw new BadRequestException(
                    "Invalid pagination: page >= 0, 1 <= size <= " + MAX_PAGE_SIZE);
        }
    }

    private FileDto mapToDto(File file) {
        FileDto dto = new FileDto();
        dto.setId(file.getId());
        dto.setName(file.getName());
        dto.setOriginalName(file.getOriginalName());
        dto.setSize(file.getSize());
        dto.setMimeType(file.getMimeType());
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
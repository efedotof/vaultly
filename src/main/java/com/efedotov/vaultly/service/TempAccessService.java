package com.efedotov.vaultly.service;

import java.io.InputStream;
import java.io.OutputStream;
import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Propagation;
import com.efedotov.vaultly.dto.tempaccess.CreateTempLinkRequest;
import com.efedotov.vaultly.dto.tempaccess.TempLinkInfo;
import com.efedotov.vaultly.dto.tempaccess.TempLinkResponse;
import com.efedotov.vaultly.exception.BadRequestException;
import com.efedotov.vaultly.exception.ForbiddenException;
import com.efedotov.vaultly.exception.NotFoundException;
import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.model.FileContent;
import com.efedotov.vaultly.model.TempFileAccess;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.FileContentRepository;
import com.efedotov.vaultly.repository.FileRepository;
import com.efedotov.vaultly.repository.TempFileAccessRepository;
import com.efedotov.vaultly.repository.UserRepository;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.shirmps.ShirmpsHeader;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class TempAccessService {

    private final TempFileAccessRepository tempFileAccessRepository;
    private final FileRepository fileRepository;
    private final FileContentRepository fileContentRepository;
    private final S3Service s3Service;
    private final UserRepository userRepository;
    private final ShpsSecurityService shpsSecurityService;
    private final PasswordEncoder passwordEncoder;
    private final LoginAttemptService loginAttemptService;

    @Value("${app.base-url}")
    private String baseUrl;

    @PostConstruct
    public void validateBaseUrl() {
        if (baseUrl == null || baseUrl.isBlank()) {
            throw new IllegalStateException("APP_BASE_URL is not set");
        }
        if (baseUrl.startsWith("http://localhost") || baseUrl.startsWith("http://127.0.0.1")) {
            log.warn("APP_BASE_URL points to localhost ({}). " +
                    "Temp links will be unusable from other machines.", baseUrl);
        }
    }

    private User getCurrentUser() {
        CustomUserDetails userDetails = (CustomUserDetails) SecurityContextHolder.getContext()
                .getAuthentication().getPrincipal();
        UUID userId = userDetails.getUserId();

        return userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("User not found with id: " + userId));
    }

    @Transactional
    public TempLinkResponse createTempLink(CreateTempLinkRequest request) {
        User currentUser = getCurrentUser();

        File file = fileRepository.findById(request.getFileId())
                .orElseThrow(() -> new NotFoundException("File not found"));

        if (!file.getUser().getId().equals(currentUser.getId())) {
            throw new ForbiddenException("You can only create temp links for your own files");
        }
        if (!Boolean.TRUE.equals(file.getIsPublic())) {
            throw new BadRequestException("File is not public. Only public files can have temp links.");
        }
        if (Boolean.TRUE.equals(file.getIsDeleted())) {
            throw new BadRequestException("File is deleted");
        }
        if (request.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new BadRequestException("Expiration time must be in the future");
        }

        String token = UUID.randomUUID().toString();

        String passwordHash = null;
        if (request.getPassword() != null && !request.getPassword().isEmpty()) {
            passwordHash = passwordEncoder.encode(request.getPassword());
        }

        TempFileAccess tempAccess = TempFileAccess.builder()
                .token(token)
                .file(file)
                .createdBy(currentUser)
                .expiresAt(request.getExpiresAt())
                .maxDownloads(request.getMaxDownloads())
                .passwordHash(passwordHash)
                .downloadsCount(0)
                .isActive(true)
                .build();

        tempFileAccessRepository.save(tempAccess);

        String accessUrl = baseUrl + "/tempacces/version132/temp-access/" + token;

        TempLinkResponse response = new TempLinkResponse();
        response.setToken(token);
        response.setAccessUrl(accessUrl);
        response.setExpiresAt(tempAccess.getExpiresAt());
        response.setMaxDownloads(tempAccess.getMaxDownloads());
        response.setDownloadsCount(tempAccess.getDownloadsCount());
        return response;
    }

    @Transactional
    public void setFilePublic(UUID fileId, Boolean isPublic) {
        User currentUser = getCurrentUser();
        File file = fileRepository.findById(fileId)
                .orElseThrow(() -> new NotFoundException("File not found"));

        if (!file.getUser().getId().equals(currentUser.getId())) {
            throw new ForbiddenException("You can only change publicity of your own files");
        }

        FileContent content = file.getFileContent();
        if (content == null) {
            throw new BadRequestException("File has no associated content");
        }

        if (Boolean.TRUE.equals(isPublic)) {
            try (InputStream s3Stream = s3Service.getObjectStream(content.getS3Key())) {
                ShirmpsHeader header = shpsSecurityService.extractHeader(s3Stream);
                if (!"server".equals(header.getKeyOwner())) {
                    throw new BadRequestException(
                            "Cannot make user-encrypted file public. Re-upload via /upload/public.");
                }
            } catch (BadRequestException e) {
                throw e;
            } catch (Exception e) {
                throw new RuntimeException("Failed to check file encryption mode", e);
            }
        }

        if (!Objects.equals(content.getIsPublic(), isPublic)) {
            long activeLinks = fileRepository.countActiveLinksByFileContent(content);
            if (activeLinks > 1) {
                throw new BadRequestException(
                        "Cannot change publicity: content is shared with other files");
            }
            content.setIsPublic(isPublic);
            fileContentRepository.save(content);
        }

        file.setIsPublic(isPublic);
        fileRepository.save(file);
    }

    public TempLinkInfo getTempLinkInfo(String token) {
        TempFileAccess tempAccess = tempFileAccessRepository.findByToken(token)
                .orElseThrow(() -> new NotFoundException("Temp link not found or expired"));

        if (!tempAccess.getIsActive() || tempAccess.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new BadRequestException("Temp link is invalid or expired");
        }

        File file = tempAccess.getFile();
        return TempLinkInfo.builder()
                .fileName(file.getOriginalName())
                .expiresAt(tempAccess.getExpiresAt())
                .mimeType(file.getMimeType())
                .hasPassword(tempAccess.getPasswordHash() != null && !tempAccess.getPasswordHash().isEmpty())
                .build();
    }

    public TempFileAccess validateTempLink(String token, String password) {
        LocalDateTime now = LocalDateTime.now();

        TempFileAccess tempAccess = tempFileAccessRepository.findByToken(token)
                .orElseThrow(() -> new NotFoundException("Temp link not found"));

        if (!tempAccess.getIsActive()) {
            throw new BadRequestException("Temp link is inactive");
        }
        if (tempAccess.getExpiresAt().isBefore(now)) {
            throw new BadRequestException("Temp link has expired");
        }
        if (tempAccess.getMaxDownloads() != null
                && tempAccess.getDownloadsCount() >= tempAccess.getMaxDownloads()) {
            throw new BadRequestException("Max downloads limit reached");
        }

        String storedHash = tempAccess.getPasswordHash();
        if (storedHash != null && !storedHash.isEmpty()) {
            String attemptKey = "temp-link:" + token;
            if (loginAttemptService.isFolderPasswordBlocked(attemptKey)) {
                throw new SecurityException("Too many password attempts");
            }
            if (password == null || !passwordEncoder.matches(password, storedHash)) {
                loginAttemptService.folderPasswordFailed(attemptKey);
                throw new BadRequestException("Invalid password");
            }
            loginAttemptService.folderPasswordSucceeded(attemptKey);
        }

        File file = tempAccess.getFile();
        if (!Boolean.TRUE.equals(file.getIsPublic())) {
            throw new BadRequestException("File is not public");
        }
        if (Boolean.TRUE.equals(file.getIsDeleted())) {
            throw new BadRequestException("File is deleted");
        }

        return tempAccess;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public boolean reserveDownloadSlot(String token) {
        int updated = tempFileAccessRepository.incrementDownloadsAndCheck(
                token, LocalDateTime.now());
        if (updated > 0) {
            tempFileAccessRepository.findByToken(token).ifPresent(ta -> {
                if (ta.getMaxDownloads() != null
                        && ta.getDownloadsCount() >= ta.getMaxDownloads()) {
                    ta.setIsActive(false);
                    tempFileAccessRepository.save(ta);
                }
            });
        }
        return updated > 0;
    }

    public void streamDecryptedFile(String token, String password, OutputStream outputStream) throws Exception {
        TempFileAccess tempAccess = validateTempLink(token, password);

        if (!reserveDownloadSlot(token)) {
            throw new BadRequestException("Max downloads limit reached");
        }

        File file = tempAccess.getFile();
        try (InputStream shpsStream = s3Service.getObjectStream(file.getFileContent().getS3Key())) {
            shpsSecurityService.decryptServerEncryptedToStream(shpsStream, outputStream);
        }
    }

    @Transactional
    public void incrementDownloadCount(String token) {
        if (!reserveDownloadSlot(token)) {
            throw new BadRequestException("Max downloads limit reached");
        }
    }
}
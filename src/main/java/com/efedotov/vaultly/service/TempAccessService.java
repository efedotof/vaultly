package com.efedotov.vaultly.service;

import java.io.InputStream;
import java.io.OutputStream;
import java.time.LocalDateTime;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.efedotov.vaultly.dto.tempaccess.CreateTempLinkRequest;
import com.efedotov.vaultly.dto.tempaccess.TempFileDownloadResponse;
import com.efedotov.vaultly.dto.tempaccess.TempLinkInfo;
import com.efedotov.vaultly.dto.tempaccess.TempLinkResponse;
import com.efedotov.vaultly.exception.BadRequestException;
import com.efedotov.vaultly.exception.ForbiddenException;
import com.efedotov.vaultly.exception.NotFoundException;
import com.efedotov.vaultly.exception.ResourceNotFoundException;
import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.model.TempFileAccess;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.FileRepository;
import com.efedotov.vaultly.repository.TempFileAccessRepository;
import com.efedotov.vaultly.repository.UserRepository;
import com.efedotov.vaultly.security.CustomUserDetails;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class TempAccessService {

    private final TempFileAccessRepository tempFileAccessRepository;
    private final FileRepository fileRepository;
    private final S3Service s3Service;
    private final UserRepository userRepository;
    private final ShpsSecurityService shpsSecurityService;

    @Value("${app.base-url}")
    private String baseUrl;

    private User getCurrentUser() {
        CustomUserDetails userDetails = (CustomUserDetails) SecurityContextHolder.getContext()
                .getAuthentication().getPrincipal();
        UUID userId = userDetails.getUserId();

        return userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));
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

        TempFileAccess tempAccess = TempFileAccess.builder()
                .token(token)
                .file(file)
                .createdBy(currentUser)
                .expiresAt(request.getExpiresAt())
                .maxDownloads(request.getMaxDownloads())
                .password(request.getPassword())
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

        file.setIsPublic(isPublic);
        fileRepository.save(file);
    }

    @Transactional
    public TempFileDownloadResponse getFileByTempLink(String token, String password) {
        LocalDateTime now = LocalDateTime.now();

        int updated = tempFileAccessRepository.incrementDownloadsAndCheck(token, now);
        if (updated == 0) {
            TempFileAccess tempAccess = tempFileAccessRepository.findByToken(token).orElse(null);
            if (tempAccess == null) {
                throw new NotFoundException("Temp link not found");
            }
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
            if (tempAccess.getPassword() != null && !tempAccess.getPassword().isEmpty()) {
                if (password == null || !password.equals(tempAccess.getPassword())) {
                    throw new BadRequestException("Invalid password");
                }
            }
            throw new BadRequestException("Temp link is not valid");
        }

        TempFileAccess tempAccess = tempFileAccessRepository.findByToken(token).orElseThrow();
        File file = tempAccess.getFile();

        if (!Boolean.TRUE.equals(file.getIsPublic())) {
            throw new BadRequestException("File is not public");
        }
        if (Boolean.TRUE.equals(file.getIsDeleted())) {
            throw new BadRequestException("File is deleted");
        }
        if (tempAccess.getMaxDownloads() != null && tempAccess.getDownloadsCount() >= tempAccess.getMaxDownloads()) {
            tempAccess.setIsActive(false);
            tempFileAccessRepository.save(tempAccess);
        }

        byte[] shpsBytes = s3Service.downloadFile(file.getS3Key());

        byte[] decryptedData;
        try {
            decryptedData = shpsSecurityService.decryptServerEncrypted(shpsBytes, file.getOriginalName());
            log.info("Public file decrypted successfully for temp link: {}", file.getOriginalName());
        } catch (Exception e) {
            log.error("Failed to decrypt public file {} for temp link", file.getId(), e);
            throw new RuntimeException("Failed to decrypt file", e);
        }

        return new TempFileDownloadResponse(decryptedData, file.getOriginalName(), file.getMimeType());
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
                .hasPassword(tempAccess.getPassword() != null && !tempAccess.getPassword().isEmpty())
                .build();
    }

    /**
     * Проверяет валидность временной ссылки и пароля.
     */
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
        if (tempAccess.getPassword() != null && !tempAccess.getPassword().isEmpty()) {
            if (password == null || !password.equals(tempAccess.getPassword())) {
                throw new BadRequestException("Invalid password");
            }
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

    /**
     * Потоковая расшифровка и отдача файла.
     */
    @Transactional
    public void streamDecryptedFile(String token, String password, OutputStream outputStream) throws Exception {
        TempFileAccess tempAccess = validateTempLink(token, password);
        File file = tempAccess.getFile();

        try (InputStream shpsStream = s3Service.getObjectStream(file.getS3Key())) {
            shpsSecurityService.decryptServerEncryptedToStream(shpsStream, outputStream);
        }

        tempAccess.setDownloadsCount(tempAccess.getDownloadsCount() + 1);
        if (tempAccess.getMaxDownloads() != null && tempAccess.getDownloadsCount() >= tempAccess.getMaxDownloads()) {
            tempAccess.setIsActive(false);
        }
        tempFileAccessRepository.save(tempAccess);
    }

    @Transactional
    public void incrementDownloadCount(String token) {
        TempFileAccess tempAccess = tempFileAccessRepository.findByToken(token)
                .orElseThrow(() -> new NotFoundException("Temp link not found"));
        tempAccess.setDownloadsCount(tempAccess.getDownloadsCount() + 1);
        if (tempAccess.getMaxDownloads() != null && tempAccess.getDownloadsCount() >= tempAccess.getMaxDownloads()) {
            tempAccess.setIsActive(false);
        }
        tempFileAccessRepository.save(tempAccess);
    }

}
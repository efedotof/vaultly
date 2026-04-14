package com.efedotov.vaultly.service;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.spec.MGF1ParameterSpec;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.UUID;

import javax.crypto.Cipher;
import javax.crypto.spec.OAEPParameterSpec;
import javax.crypto.spec.PSource;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.efedotov.vaultly.dto.file.DecryptionMetadata;
import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.model.Folder;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.FileRepository;
import com.efedotov.vaultly.repository.FolderRepository;
import com.efedotov.vaultly.repository.UserRepository;
import com.efedotov.vaultly.shirmps.ShirmpsHeader;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class FileService {

    private final FileRepository fileRepository;
    private final UserRepository userRepository;
    private final FolderRepository folderRepository;
    private final S3Service s3Service;
    private final ShpsSecurityService shpsSecurityService;
    private final ServerKeyService serverKeyService;
    private final UserKeyService userKeyService;
    private final FolderService folderService;

    @Transactional
    public File createFile(String name, String originalName, String s3Key,
            String s3Url, Long size, String mimeType,
            UUID userId, Boolean isEncrypted, Boolean isPublic) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));

        File file = File.builder()
                .name(name)
                .originalName(originalName)
                .s3Key(s3Key)
                .s3Url(s3Url)
                .size(size)
                .mimeType(mimeType)
                .user(user)
                .isEncrypted(isEncrypted)
                .isPublic(isPublic)
                .build();

        return fileRepository.save(file);
    }

    @Transactional
    public void deleteFile(UUID fileId, UUID userId) {
        File file = fileRepository.findById(fileId)
                .orElseThrow(() -> new IllegalArgumentException("Файл не найден"));

        if (!file.getUser().getId().equals(userId)) {
            throw new SecurityException("У вас нет прав на удаление этого файла");
        }

        try {
            s3Service.deleteFile(file.getS3Url());
            log.info("Файл удалён из S3: {}", file.getS3Key());
        } catch (Exception e) {
            log.error("Ошибка при удалении файла из S3: {}", file.getS3Key(), e);
            throw new RuntimeException("Не удалось удалить файл из хранилища", e);
        }

        file.setIsDeleted(true);
        file.setDeletedAt(LocalDateTime.now());
        fileRepository.save(file);

        log.info("Файл помечен как удалённый: {}", fileId);
    }

    @Transactional
    public File updateFileFolder(UUID fileId, UUID folderId, UUID userId) {
        File file = fileRepository.findById(fileId)
                .orElseThrow(() -> new IllegalArgumentException("Файл не найден"));

        if (!file.getUser().getId().equals(userId)) {
            throw new SecurityException("У вас нет прав на изменение этого файла");
        }

        Folder folder = null;
        if (folderId != null) {
            folder = folderRepository.findById(folderId)
                    .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));

            if (!folder.getUser().getId().equals(userId)) {
                throw new SecurityException("Папка принадлежит другому пользователю");
            }
        }

        file.setFolder(folder);
        return fileRepository.save(file);
    }

    @Transactional(readOnly = true)
    public File getFileById(UUID fileId, UUID userId) {
        return fileRepository.findByIdAndUserId(fileId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Файл не найден или доступ запрещен"));
    }

    @Transactional(readOnly = true)
    public Page<File> getAllFilesForUser(UUID userId, Pageable pageable) {
        return fileRepository.findByUserIdAndIsDeletedFalse(userId, pageable);
    }

    @Transactional(readOnly = true)
    public Page<File> getLatestFilesForUser(UUID userId, Pageable pageable) {
        return fileRepository.findLatestByUserId(userId, pageable);
    }

    public DecryptionMetadata getDecryptionMetadataForUser(UUID fileId, UUID userId) {
        File file = getFileById(fileId, userId);

        if (file.getIsPublic()) {
            return createMetadataForPublicFile(file, userId);
        } else {
            return createMetadataForPrivateFile(file, userId);
        }
    }

    private DecryptionMetadata createMetadataForPublicFile(File file, UUID userId) {
        try (InputStream s3Stream = s3Service.getObjectStream(file.getS3Key())) {

            ShirmpsHeader header = shpsSecurityService.extractHeader(s3Stream);

            PrivateKey serverPrivateKey = serverKeyService.getPrivateKey();
            byte[] encryptedAesKey = Base64.getDecoder().decode(header.getEncryptedKey());

            Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
            OAEPParameterSpec oaepParams = new OAEPParameterSpec(
                    "SHA-256", "MGF1", MGF1ParameterSpec.SHA256, PSource.PSpecified.DEFAULT);
            rsaCipher.init(Cipher.DECRYPT_MODE, serverPrivateKey, oaepParams);
            byte[] aesKeyBytes = rsaCipher.doFinal(encryptedAesKey);

            PublicKey userPublicKey = userKeyService.getPublicKey(userId);

            rsaCipher.init(Cipher.ENCRYPT_MODE, userPublicKey, oaepParams);
            byte[] reEncryptedKey = rsaCipher.doFinal(aesKeyBytes);

            Duration duration = Duration.ofMinutes(10);
            String presignedUrl = s3Service.generatePresignedUrl(file.getS3Key(), duration);

            DecryptionMetadata metadata = new DecryptionMetadata();
            metadata.setPresignedUrl(presignedUrl);
            metadata.setEncryptedKey(Base64.getEncoder().encodeToString(reEncryptedKey));
            metadata.setIv(header.getIv());
            metadata.setOriginalSize(header.getOriginalFileSize());
            metadata.setMimeType(file.getMimeType());
            metadata.setFileName(file.getOriginalName());

            return metadata;
        } catch (Exception e) {
            log.error("Failed to create decryption metadata for public file {}", file.getId(), e);
            throw new RuntimeException("Failed to prepare file for decryption", e);
        }
    }

    private DecryptionMetadata createMetadataForPrivateFile(File file, UUID userId) {
        try (InputStream s3Stream = s3Service.getObjectStream(file.getS3Key())) {

            ShirmpsHeader header = shpsSecurityService.extractHeader(s3Stream);

            if (!"user".equals(header.getKeyOwner()) || !userId.toString().equals(header.getUserId())) {
                throw new SecurityException("Private file does not belong to the current user");
            }

            Duration duration = Duration.ofMinutes(10);
            String presignedUrl = s3Service.generatePresignedUrl(file.getS3Key(), duration);

            DecryptionMetadata metadata = new DecryptionMetadata();
            metadata.setPresignedUrl(presignedUrl);
            metadata.setEncryptedKey(header.getEncryptedKey());
            metadata.setIv(header.getIv());
            metadata.setOriginalSize(header.getOriginalFileSize());
            metadata.setMimeType(file.getMimeType());
            metadata.setFileName(file.getOriginalName());

            return metadata;
        } catch (Exception e) {
            log.error("Failed to create decryption metadata for private file {}", file.getId(), e);
            throw new RuntimeException("Failed to prepare file for decryption", e);
        }
    }

    public DecryptionMetadata getDecryptionMetadataForTempAccess(UUID fileId, UUID userId) {
        File file = fileRepository.findById(fileId)
                .orElseThrow(() -> new IllegalArgumentException("Файл не найден"));
        return createMetadataForPublicFile(file, userId);
    }

    @Transactional
    public File createNote(MultipartFile shpsFile, UUID folderId, UUID userId) throws Exception {
        String originalFilename = shpsFile.getOriginalFilename();
        long fileSize = shpsFile.getSize();

        log.info("Creating note: {}, size: {} bytes, user: {}", originalFilename, fileSize, userId);

        Path tempFile = Files.createTempFile("note-upload-", ".shps");
        try (InputStream inputStream = shpsFile.getInputStream()) {
            Files.copy(inputStream, tempFile, StandardCopyOption.REPLACE_EXISTING);

            ShirmpsHeader header = shpsSecurityService.validateHeaderOnly(tempFile, originalFilename);
            if (!"user".equals(header.getKeyOwner())) {
                throw new SecurityException("Note must be encrypted for user (keyOwner=user)");
            }
            if (!userId.toString().equals(header.getUserId())) {
                throw new SecurityException("Note belongs to a different user");
            }

            String url = s3Service.uploadFileWithMultipart(tempFile, originalFilename, "application/x-shirmps");
            String s3Key = s3Service.getObjectKeyFromUrl(url);

            File note = createFile(
                    originalFilename.replace(".shps", ""),
                    originalFilename,
                    s3Key,
                    url,
                    Files.size(tempFile),
                    "text/markdown",
                    userId,
                    true,
                    false);
            note.setIsNote(true);
            note = fileRepository.save(note);

            if (folderId != null) {
                note = folderService.addFileToFolder(note.getId(), folderId, userId);
            }

            log.info("Note created: {}", note.getId());
            return note;
        } finally {
            Files.deleteIfExists(tempFile);
        }
    }

    @Transactional
    public File updateNoteContent(UUID fileId, MultipartFile updatedShpsFile, UUID userId) throws Exception {
        File existingNote = fileRepository.findByIdAndUserId(fileId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Заметка не найдена или доступ запрещен"));

        if (!existingNote.getIsNote()) {
            throw new IllegalArgumentException("Файл не является заметкой");
        }

        String originalFilename = updatedShpsFile.getOriginalFilename();
        log.info("Updating note content: {} (id: {})", originalFilename, fileId);

        Path tempFile = Files.createTempFile("note-update-", ".shps");
        try (InputStream inputStream = updatedShpsFile.getInputStream()) {
            Files.copy(inputStream, tempFile, StandardCopyOption.REPLACE_EXISTING);

            ShirmpsHeader header = shpsSecurityService.validateHeaderOnly(tempFile, originalFilename);
            if (!"user".equals(header.getKeyOwner())) {
                throw new SecurityException("Note must be encrypted for user (keyOwner=user)");
            }
            if (!userId.toString().equals(header.getUserId())) {
                throw new SecurityException("Note belongs to a different user");
            }

            String s3Key = existingNote.getS3Key();
            s3Service.uploadFileWithMultipart(tempFile, s3Key, originalFilename, "application/x-shirmps");
            existingNote.setSize(Files.size(tempFile));
            existingNote.setOriginalName(originalFilename);
            File savedNote = fileRepository.save(existingNote);

            log.info("Note content updated: {}", savedNote.getId());
            return savedNote;
        } finally {
            Files.deleteIfExists(tempFile);
        }
    }

    public Page<File> getUsersNodes(UUID userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("updatedAt").descending());

        Page<File> notesPage = fileRepository.findNotesByUserId(userId, pageable);
        return notesPage;
    }

}
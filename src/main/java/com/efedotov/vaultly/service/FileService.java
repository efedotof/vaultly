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
import java.util.Optional;
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
import com.efedotov.vaultly.dto.file.FileDto;
import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.model.FileContent;
import com.efedotov.vaultly.model.Folder;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.FileContentRepository;
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
    private final FileContentRepository fileContentRepository;
    private final ShpsEncryptionService shpsEncryptionService;

    @Transactional
    public FileDto uploadShpsFile(MultipartFile file, UUID folderId, boolean isPublic,
            String contentHash, UUID userId) throws Exception {
        String originalFilename = file.getOriginalFilename();

        if (contentHash != null && !contentHash.isBlank()) {
            Optional<FileContent> existing = fileContentRepository
                    .findByHashAndIsPublic(contentHash, isPublic);
            if (existing.isPresent()) {
                File createdFile = createFileLink(userId, existing.get(), originalFilename, folderId);
                return mapToDto(createdFile);
            }
        }

        Path tempFile = Files.createTempFile("shps-upload-", ".shps");
        try (InputStream inputStream = file.getInputStream()) {
            Files.copy(inputStream, tempFile, StandardCopyOption.REPLACE_EXISTING);

            ShirmpsHeader header = shpsSecurityService.validateHeaderOnly(tempFile, originalFilename);
            if (isPublic) {
                if (!"server".equals(header.getKeyOwner())) {
                    throw new SecurityException("Public file must be encrypted for server (keyOwner=server)");
                }
                shpsSecurityService.validateAndVerifyStreaming(tempFile, userId, originalFilename);
            } else {
                if (!"user".equals(header.getKeyOwner())) {
                    throw new SecurityException("Private file must be encrypted for user (keyOwner=user)");
                }
                if (!userId.toString().equals(header.getUserId())) {
                    throw new SecurityException("Private file belongs to a different user");
                }
            }

            String shpsFileName = originalFilename.endsWith(".shps") ? originalFilename : originalFilename + ".shps";
        
            String s3Key = s3Service.uploadFileWithMultipart(tempFile, shpsFileName, "application/x-shirmps");
            long actualSize = Files.size(tempFile);
            
   
            String publicUrl = s3Service.getPublicUrl(s3Key);

            FileContent content = FileContent.builder()
                    .hash(contentHash)
                    .s3Key(s3Key)
                    .s3Url(publicUrl)  
                    .size(actualSize)
                    .mimeType("application/x-shirmps")
                    .isPublic(isPublic)
                    .build();
            content = fileContentRepository.save(content);

            File createdFile = createFileLink(userId, content, originalFilename, folderId);
            log.info("SHPS file uploaded: {} (hash: {})", createdFile.getId(), contentHash);
            return mapToDto(createdFile);
        } finally {
            Files.deleteIfExists(tempFile);
        }
    }

    @Transactional
    public FileDto uploadPublicFile(MultipartFile file, UUID folderId, String contentHash, UUID userId)
            throws Exception {
        String originalFilename = file.getOriginalFilename();
        long fileSize = file.getSize();

        if (contentHash != null && !contentHash.isBlank()) {
            Optional<FileContent> existing = fileContentRepository
                    .findByHashAndIsPublic(contentHash, true);
            if (existing.isPresent()) {
                File createdFile = createFileLink(userId, existing.get(), originalFilename, folderId);
                return mapToDto(createdFile);
            }
        }

        java.io.File tempShpsFile = null;
        try (InputStream plainStream = file.getInputStream()) {
            tempShpsFile = shpsEncryptionService.encryptForServerToTempFile(
                    plainStream, fileSize, originalFilename, userId);

            String shpsFileName = originalFilename + ".shps";
  
            String s3Key = s3Service.uploadFileWithMultipart(tempShpsFile.toPath(), shpsFileName,
                    "application/x-shirmps");
            long actualSize = tempShpsFile.length();
            
            String publicUrl = s3Service.getPublicUrl(s3Key);

            FileContent content = FileContent.builder()
                    .hash(contentHash)
                    .s3Key(s3Key)
                    .s3Url(publicUrl)
                    .size(actualSize)
                    .mimeType("application/x-shirmps")
                    .isPublic(true)
                    .build();
            content = fileContentRepository.save(content);

            File createdFile = createFileLink(userId, content, originalFilename, folderId);
            log.info("Public file encrypted and uploaded: {}", createdFile.getId());
            return mapToDto(createdFile);
        } finally {
            if (tempShpsFile != null && tempShpsFile.exists()) {
                tempShpsFile.delete();
            }
        }
    }

    @Transactional
    public File createFileLink(UUID userId, FileContent content, String fileName, UUID folderId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        File file = File.builder()
                .name(fileName)
                .originalName(fileName)
                .fileContent(content)
                .user(user)
                .size(content.getSize())
                .mimeType(content.getMimeType())
                .isEncrypted(true)
                .isPublic(content.getIsPublic())
                .isNote(false)
                .build();

        if (folderId != null) {
            Folder folder = folderRepository.findById(folderId)
                    .orElseThrow(() -> new IllegalArgumentException("Folder not found"));
            file.setFolder(folder);
        }

        return fileRepository.save(file);
    }

    @Transactional(readOnly = true)
    public UUID findExistingFileContentId(String hash, Boolean isPublic) {
        return fileContentRepository.findByHashAndIsPublic(hash, isPublic)
                .map(FileContent::getId)
                .orElse(null);
    }

    @Transactional
    public File linkExistingFile(UUID userId, UUID fileContentId, String fileName,
            UUID folderId, Boolean isPublic) {
        FileContent content = fileContentRepository.findById(fileContentId)
                .orElseThrow(() -> new IllegalArgumentException("File content not found"));

        if (!content.getIsPublic().equals(isPublic)) {
            throw new SecurityException("Cannot link public content as private or vice versa");
        }

        return createFileLink(userId, content, fileName, folderId);
    }

    @Transactional
    public File createFileWithContent(String name, String originalName, String s3Key, String s3Url,
            Long size, String mimeType, UUID userId,
            Boolean isEncrypted, Boolean isPublic, String contentHash) {

        FileContent content = FileContent.builder()
                .hash(contentHash)
                .s3Key(s3Key)
                .s3Url(s3Url)
                .size(size)
                .mimeType(mimeType)
                .isPublic(isPublic)
                .build();
        content = fileContentRepository.save(content);

        return createFileLink(userId, content, name, null);
    }

    @Transactional
    public void deleteFile(UUID fileId, UUID userId) {
        File file = fileRepository.findByIdAndUserId(fileId, userId)
                .orElseThrow(() -> new IllegalArgumentException("File not found"));

        FileContent content = file.getFileContent();

        file.setIsDeleted(true);
        file.setDeletedAt(LocalDateTime.now());
        fileRepository.save(file);

        if (content != null) {
            long activeLinks = fileRepository.countActiveLinksByFileContent(content);
            if (activeLinks == 0) {
                try {
                    s3Service.deleteFile(content.getS3Url());
                    log.info("Deleted S3 object: {}", content.getS3Key());
                } catch (Exception e) {
                    log.error("Failed to delete S3 object: {}", content.getS3Key(), e);
                }
            } else {
                log.debug("FileContent {} still has {} active links, keeping S3 object and metadata",
                        content.getId(), activeLinks);
            }
        }

        User user = file.getUser();
        long newStorageUsed = user.getStorageUsed() - file.getSize();
        if (newStorageUsed < 0)
            newStorageUsed = 0L;
        user.setStorageUsed(newStorageUsed);
        userRepository.save(user);
    }

    @Transactional
    public File updateFileFolder(UUID fileId, UUID folderId, UUID userId) {
        File file = fileRepository.findById(fileId)
                .orElseThrow(() -> new IllegalArgumentException("File not found"));
        if (!file.getUser().getId().equals(userId)) {
            throw new SecurityException("Access denied");
        }
        Folder folder = null;
        if (folderId != null) {
            folder = folderRepository.findById(folderId)
                    .orElseThrow(() -> new IllegalArgumentException("Folder not found"));
            if (!folder.getUser().getId().equals(userId)) {
                throw new SecurityException("Folder belongs to another user");
            }
        }
        file.setFolder(folder);
        return fileRepository.save(file);
    }

    @Transactional(readOnly = true)
    public File getFileById(UUID fileId, UUID userId) {
        return fileRepository.findByIdAndUserId(fileId, userId)
                .orElseThrow(() -> new IllegalArgumentException("File not found or access denied"));
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
        String s3Key = file.getFileContent().getS3Key();
        try (InputStream s3Stream = s3Service.getObjectStream(s3Key)) {
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
            String presignedUrl = s3Service.generatePresignedUrl(s3Key, duration);

            DecryptionMetadata metadata = new DecryptionMetadata();
            metadata.setPresignedUrl(presignedUrl);
            metadata.setEncryptedKey(Base64.getEncoder().encodeToString(reEncryptedKey));
            metadata.setIv(header.getIv());
            metadata.setOriginalSize(header.getOriginalFileSize());
            metadata.setMimeType(file.getMimeType());
            metadata.setFileName(file.getOriginalName());
            return metadata;
        } catch (Exception e) {
            throw new RuntimeException("Failed to prepare file for decryption", e);
        }
    }

    private DecryptionMetadata createMetadataForPrivateFile(File file, UUID userId) {
        String s3Key = file.getFileContent().getS3Key();
        try (InputStream s3Stream = s3Service.getObjectStream(s3Key)) {
            ShirmpsHeader header = shpsSecurityService.extractHeader(s3Stream);
            if (!"user".equals(header.getKeyOwner()) || !userId.toString().equals(header.getUserId())) {
                throw new SecurityException("Private file does not belong to the current user");
            }
            Duration duration = Duration.ofMinutes(10);
            String presignedUrl = s3Service.generatePresignedUrl(s3Key, duration);

            DecryptionMetadata metadata = new DecryptionMetadata();
            metadata.setPresignedUrl(presignedUrl);
            metadata.setEncryptedKey(header.getEncryptedKey());
            metadata.setIv(header.getIv());
            metadata.setOriginalSize(header.getOriginalFileSize());
            metadata.setMimeType(file.getMimeType());
            metadata.setFileName(file.getOriginalName());
            return metadata;
        } catch (Exception e) {
            throw new RuntimeException("Failed to prepare file for decryption", e);
        }
    }

    public DecryptionMetadata getDecryptionMetadataForTempAccess(UUID fileId, UUID userId) {
        File file = fileRepository.findById(fileId)
                .orElseThrow(() -> new IllegalArgumentException("File not found"));
        return createMetadataForPublicFile(file, userId);
    }

    @Transactional
    public File createNote(MultipartFile shpsFile, UUID folderId, UUID userId) throws Exception {
        String originalFilename = shpsFile.getOriginalFilename();
        Path tempFile = Files.createTempFile("note-upload-", ".shps");
        try (InputStream inputStream = shpsFile.getInputStream()) {
            Files.copy(inputStream, tempFile, StandardCopyOption.REPLACE_EXISTING);
            ShirmpsHeader header = shpsSecurityService.validateHeaderOnly(tempFile, originalFilename);
            if (!"user".equals(header.getKeyOwner()) || !userId.toString().equals(header.getUserId())) {
                throw new SecurityException("Invalid note owner");
            }
        
            String s3Key = s3Service.uploadFileWithMultipart(tempFile, originalFilename, "application/x-shirmps");
            long size = Files.size(tempFile);
            String publicUrl = s3Service.getPublicUrl(s3Key);

            FileContent content = FileContent.builder()
                    .hash(null)
                    .s3Key(s3Key)
                    .s3Url(publicUrl)
                    .size(size)
                    .mimeType("text/markdown")
                    .isPublic(false)
                    .build();
            content = fileContentRepository.save(content);

            File note = createFileLink(userId, content, originalFilename.replace(".shps", ""), folderId);
            note.setIsNote(true);
            note = fileRepository.save(note);
            if (folderId != null) {
                note = folderService.addFileToFolder(note.getId(), folderId, userId);
            }
            return note;
        } finally {
            Files.deleteIfExists(tempFile);
        }
    }

    @Transactional
    public File updateNoteContent(UUID fileId, MultipartFile updatedShpsFile, UUID userId) throws Exception {
        File existingNote = fileRepository.findByIdAndUserId(fileId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Note not found"));
        if (!existingNote.getIsNote()) {
            throw new IllegalArgumentException("Not a note");
        }
        String originalFilename = updatedShpsFile.getOriginalFilename();
        Path tempFile = Files.createTempFile("note-update-", ".shps");
        try (InputStream inputStream = updatedShpsFile.getInputStream()) {
            Files.copy(inputStream, tempFile, StandardCopyOption.REPLACE_EXISTING);
            ShirmpsHeader header = shpsSecurityService.validateHeaderOnly(tempFile, originalFilename);
            if (!"user".equals(header.getKeyOwner()) || !userId.toString().equals(header.getUserId())) {
                throw new SecurityException("Invalid note owner");
            }
            String s3Key = existingNote.getFileContent().getS3Key();
            s3Service.uploadFileWithMultipart(tempFile, s3Key, originalFilename, "application/x-shirmps");
            existingNote.setSize(Files.size(tempFile));
            existingNote.setOriginalName(originalFilename);

            String publicUrl = s3Service.getPublicUrl(s3Key);
            existingNote.getFileContent().setS3Url(publicUrl);
            fileContentRepository.save(existingNote.getFileContent());
            return fileRepository.save(existingNote);
        } finally {
            Files.deleteIfExists(tempFile);
        }
    }

    public Page<File> getUsersNodes(UUID userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("updatedAt").descending());
        return fileRepository.findNotesByUserId(userId, pageable);
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

        if (file.getFileContent() != null) {
            String s3Key = file.getFileContent().getS3Key();
            if (s3Key != null) {
                dto.setS3Url(s3Service.getPublicUrl(s3Key));
            }
        }

        return dto;
    }


}
package com.efedotov.vaultly.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.efedotov.vaultly.dto.folder.FolderCreateDto;
import com.efedotov.vaultly.dto.folder.FolderMoveDto;
import com.efedotov.vaultly.dto.folder.FolderShareDto;
import com.efedotov.vaultly.dto.folder.FolderUpdateDto;
import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.model.Folder;
import com.efedotov.vaultly.model.FolderAccess;
import com.efedotov.vaultly.model.FolderPassword;
import com.efedotov.vaultly.model.FolderType;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.FileRepository;
import com.efedotov.vaultly.repository.FolderAccessRepository;
import com.efedotov.vaultly.repository.FolderPasswordRepository;
import com.efedotov.vaultly.repository.FolderRepository;
import com.efedotov.vaultly.repository.UserRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class FolderService {

    private final FolderRepository folderRepository;
    private final FileRepository fileRepository;
    private final FolderAccessRepository folderAccessRepository;
    private final FolderPasswordRepository folderPasswordRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final S3Service s3Service;

    public Folder getFolderById(UUID folderId) {
        return folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));
    }

    @Transactional
    public Folder createFolder(FolderCreateDto request, UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));

        Folder parentFolder = null;
        if (request.getParentFolderId() != null) {
            parentFolder = folderRepository.findById(request.getParentFolderId())
                    .orElseThrow(() -> new IllegalArgumentException("Родительская папка не найдена"));
            checkFolderAccess(parentFolder, userId, FolderAccess.AccessLevel.WRITE);
        }

        if (folderRepository.existsByUserAndNameAndParentFolder(user, request.getName(), parentFolder)) {
            throw new IllegalArgumentException("Папка с таким именем уже существует");
        }

        Folder folder = Folder.builder()
                .name(request.getName())
                .user(user)
                .parentFolder(parentFolder)
                .type(FolderType.CUSTOM)
                .isHidden(request.getIsHidden())
                .build();

        folder = folderRepository.save(folder);
        createOwnerAccess(folder, userId);

        if (request.getIsHidden() && request.getHiddenFolderKey() != null) {
            setHiddenFolderKey(folder, request.getHiddenFolderKey());
        }
        if (request.getPassword() != null) {
            setFolderPassword(folder, request.getPassword());
        }

        log.info("Папка создана: {} для пользователя {}", folder.getName(), userId);
        return folder;
    }

    @Transactional
    public void deleteFolder(UUID folderId, UUID userId) {
        Folder folder = folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));
        checkFolderAccess(folder, userId, FolderAccess.AccessLevel.ADMIN);

        deleteFolderRecursive(folder, userId);
        folderAccessRepository.deleteByFolder(folder);
        folderPasswordRepository.deleteByFolder(folder);
        folderRepository.delete(folder);
        log.info("Папка удалена: {}", folderId);
    }

    private void deleteFolderRecursive(Folder folder, UUID userId) {
        List<File> files = fileRepository.findByFolderId(folder.getId());
        for (File file : files) {
            try {
                s3Service.deleteFile(file.getS3Url());
                fileRepository.delete(file);
            } catch (Exception e) {
                log.error("Ошибка при удалении файла {} из S3: {}", file.getId(), e.getMessage());
            }
        }

        List<Folder> subfolders = folderRepository.findByParentFolder(folder);
        for (Folder subfolder : subfolders) {
            deleteFolderRecursive(subfolder, userId);
            folderRepository.delete(subfolder);
        }
    }

    @Transactional
    public Folder renameFolder(UUID folderId, FolderUpdateDto request, UUID userId) {
        Folder folder = folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));
        checkFolderAccess(folder, userId, FolderAccess.AccessLevel.WRITE);

        User folderOwner = userRepository.findById(folder.getUser().getId())
                .orElseThrow(() -> new IllegalArgumentException("Владелец папки не найден"));

        if (folderRepository.existsByUserAndNameAndParentFolder(folderOwner, request.getName(),
                folder.getParentFolder())) {
            throw new IllegalArgumentException("Папка с таким именем уже существует");
        }

        folder.setName(request.getName());

        return folderRepository.save(folder);
    }

    @Transactional
    public File addFileToFolder(UUID fileId, UUID folderId, UUID userId) {
        File file = fileRepository.findById(fileId)
                .orElseThrow(() -> new IllegalArgumentException("Файл не найден"));

        Folder folder = null;
        if (folderId != null) {
            folder = folderRepository.findById(folderId)
                    .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));
            checkFolderAccess(folder, userId, FolderAccess.AccessLevel.WRITE);
        }

        file.setFolder(folder);
        return fileRepository.save(file);
    }

    @Transactional
    public List<File> moveFiles(FolderMoveDto request, UUID userId) {
        List<File> movedFiles = new ArrayList<>();

        Folder targetFolder = null;
        if (request.getTargetFolderId() != null) {
            targetFolder = folderRepository.findById(request.getTargetFolderId())
                    .orElseThrow(() -> new IllegalArgumentException("Целевая папка не найдена"));
            checkFolderAccess(targetFolder, userId, FolderAccess.AccessLevel.WRITE);
        }

        for (UUID fileId : request.getFileIds()) {
            File file = fileRepository.findById(fileId)
                    .orElseThrow(() -> new IllegalArgumentException("Файл не найден: " + fileId));

            if (!file.getUser().getId().equals(userId)) {
                if (file.getFolder() != null) {
                    checkFolderAccess(file.getFolder(), userId, FolderAccess.AccessLevel.WRITE);
                } else {
                    throw new SecurityException("Нет прав на перемещение файла");
                }
            }

            if (request.getCopy()) {
                File copiedFile = copyFile(file, targetFolder);
                movedFiles.add(copiedFile);
            } else {
                file.setFolder(targetFolder);
                movedFiles.add(fileRepository.save(file));
            }
        }
        return movedFiles;
    }

    public boolean hasActivePassword(UUID folderId) {
        Folder folder = folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));
        return folderPasswordRepository.findByFolderAndIsActive(folder, true).isPresent();
    }

    private File copyFile(File originalFile, Folder targetFolder) {
        File copiedFile = File.builder()
                .name(originalFile.getName() + " (копия)")
                .originalName(originalFile.getOriginalName())
                .s3Key(originalFile.getS3Key())
                .s3Url(originalFile.getS3Url())
                .size(originalFile.getSize())
                .mimeType(originalFile.getMimeType())
                .user(originalFile.getUser())
                .folder(targetFolder)
                .isEncrypted(originalFile.getIsEncrypted())
                .isPublic(originalFile.getIsPublic())
                .build();
        return fileRepository.save(copiedFile);
    }

    @Transactional
    public File removeFileFromFolder(UUID fileId, UUID userId) {
        return addFileToFolder(fileId, null, userId);
    }

    @Transactional
    public Folder closeFolderForOthers(UUID folderId, UUID userId) {
        Folder folder = folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));
        checkFolderAccess(folder, userId, FolderAccess.AccessLevel.OWNER);

        List<FolderAccess> accesses = folderAccessRepository.findByFolder(folder);
        for (FolderAccess access : accesses) {
            if (!access.getUser().getId().equals(userId) &&
                    access.getAccessLevel() != FolderAccess.AccessLevel.OWNER) {
                folderAccessRepository.delete(access);
            }
        }
        log.info("Папка закрыта для других пользователей: {}", folderId);
        return folder;
    }

    @Transactional
    public List<FolderAccess> shareFolder(FolderShareDto request, UUID userId) {
        Folder folder = folderRepository.findById(request.getFolderId())
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));
        checkFolderAccess(folder, userId, FolderAccess.AccessLevel.ADMIN);
        if (!request.getCanShare()) {
            throw new IllegalArgumentException("У вас нет прав на предоставление доступа");
        }

        List<FolderAccess> newAccesses = new ArrayList<>();
        for (UUID sharedUserId : request.getUserIds()) {
            User sharedUser = userRepository.findById(sharedUserId)
                    .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден: " + sharedUserId));

            if (!folderAccessRepository.existsByFolderAndUser(folder, sharedUser)) {
                FolderAccess access = FolderAccess.builder()
                        .folder(folder)
                        .user(sharedUser)
                        .accessLevel(FolderAccess.AccessLevel.READ)
                        .canEdit(request.getCanEdit())
                        .canDelete(request.getCanDelete())
                        .canShare(request.getCanShare())
                        .grantedBy(userId)
                        .grantedAt(LocalDateTime.now())
                        .build();
                newAccesses.add(folderAccessRepository.save(access));
            }
        }
        return newAccesses;
    }

    public void checkFolderAccess(Folder folder, UUID userId, FolderAccess.AccessLevel requiredLevel) {
        if (folder.getUser().getId().equals(userId)) {
            return;
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));

        Optional<FolderAccess> accessOpt = folderAccessRepository.findByFolderAndUser(folder, user);
        if (accessOpt.isEmpty()) {
            throw new SecurityException("Доступ к папке запрещен");
        }

        FolderAccess access = accessOpt.get();
        if (!access.getIsActive()) {
            throw new SecurityException("Доступ к папке отозван");
        }

        if (access.getAccessLevel().ordinal() < requiredLevel.ordinal()) {
            throw new SecurityException("Недостаточно прав для выполнения операции");
        }
    }

    @Transactional
    public void setFolderPassword(UUID folderId, String password, UUID userId) {
        Folder folder = folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));
        checkFolderAccess(folder, userId, FolderAccess.AccessLevel.OWNER);

        folderPasswordRepository.deactivateByFolder(folder);

        if (password != null && !password.isEmpty()) {
            String salt = generateSalt();
            String hashedPassword = hashPassword(password, salt);
            FolderPassword folderPassword = FolderPassword.builder()
                    .folder(folder)
                    .passwordHash(hashedPassword)
                    .salt(salt)
                    .isActive(true)
                    .createdAt(LocalDateTime.now())
                    .build();
            folderPasswordRepository.save(folderPassword);
        }
    }

    public boolean checkFolderPassword(UUID folderId, String password) {
        Folder folder = folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));
        Optional<FolderPassword> passwordOpt = folderPasswordRepository.findByFolderAndIsActive(folder, true);
        if (passwordOpt.isEmpty()) {
            return true;
        }
        FolderPassword folderPassword = passwordOpt.get();
        String hashedInput = hashPassword(password, folderPassword.getSalt());
        return folderPassword.getPasswordHash().equals(hashedInput);
    }

    private void setFolderPassword(Folder folder, String password) {
        String salt = generateSalt();
        String hashedPassword = hashPassword(password, salt);
        FolderPassword folderPassword = FolderPassword.builder()
                .folder(folder)
                .passwordHash(hashedPassword)
                .salt(salt)
                .createdAt(LocalDateTime.now())
                .build();
        folderPasswordRepository.save(folderPassword);
    }

    private void setHiddenFolderKey(Folder folder, String key) {
        String keyHash = passwordEncoder.encode(key);
        folder.setHiddenFolderKeyHash(keyHash);
        log.debug("Установлен ключ для скрытой папки {}", folder.getId());
    }

    private void createOwnerAccess(Folder folder, UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));
        FolderAccess ownerAccess = FolderAccess.builder()
                .folder(folder)
                .user(user)
                .accessLevel(FolderAccess.AccessLevel.OWNER)
                .canEdit(true)
                .canDelete(true)
                .canShare(true)
                .grantedBy(userId)
                .grantedAt(LocalDateTime.now())
                .build();
        folderAccessRepository.save(ownerAccess);
    }

    private String hashPassword(String password, String salt) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            md.update(salt.getBytes(StandardCharsets.UTF_8));
            byte[] hashedBytes = md.digest(password.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hashedBytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Ошибка при хешировании пароля", e);
        }
    }

    private String generateSalt() {
        SecureRandom random = new SecureRandom();
        byte[] salt = new byte[16];
        random.nextBytes(salt);
        return Base64.getEncoder().encodeToString(salt);
    }

    public List<Folder> getFolderTree(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));
        List<Folder> rootFolders = folderRepository.findByUserAndParentFolderIsNull(user);
        return rootFolders.stream()
                .map(this::enrichFolderWithSubfolders)
                .collect(Collectors.toList());
    }

    private Folder enrichFolderWithSubfolders(Folder folder) {
        List<Folder> subfolders = folderRepository.findByParentFolder(folder);
        List<Folder> enrichedSubfolders = subfolders.stream()
                .map(this::enrichFolderWithSubfolders)
                .collect(Collectors.toList());
        folder.setSubfolders(enrichedSubfolders);
        return folder;
    }

    public List<File> getFolderFiles(UUID folderId, UUID userId) {
        Folder folder = folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));
        checkFolderAccess(folder, userId, FolderAccess.AccessLevel.READ);
        return fileRepository.findByFolderId(folderId);
    }

    public boolean checkHiddenFolderKey(UUID folderId, String key) {
        Folder folder = folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));
        if (folder.getHiddenFolderKeyHash() == null) {
            return false;
        }
        return passwordEncoder.matches(key, folder.getHiddenFolderKeyHash());
    }
}
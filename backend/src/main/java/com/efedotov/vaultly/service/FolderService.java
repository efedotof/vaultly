package com.efedotov.vaultly.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.efedotov.vaultly.dto.folder.FolderCreateDto;
import com.efedotov.vaultly.dto.folder.FolderMoveDto;
import com.efedotov.vaultly.dto.folder.FolderShareDto;
import com.efedotov.vaultly.dto.folder.FolderUpdateDto;
import com.efedotov.vaultly.exception.BadRequestException;
import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.model.FileContent;
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
    private final LoginAttemptService loginAttemptService;

    private static final int MAX_FOLDER_DEPTH = 100;

    public Folder getFolderById(UUID folderId) {
        return folderRepository.findByIdWithUser(folderId)
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
        if (parentFolder != null) {
            int depth = 0;
            Folder current = parentFolder;
            while (current != null) {
                depth++;
                if (depth >= MAX_FOLDER_DEPTH) {
                    throw new BadRequestException("Folder hierarchy too deep");
                }
                current = current.getParentFolder();
            }
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

        softDeleteFolderRecursive(folder);
        log.info("Папка мягко удалена: {}", folderId);
    }

    private void softDeleteFolderRecursive(Folder folder) {
        if (Boolean.TRUE.equals(folder.getIsDeleted())) {
            return;
        }

        List<File> files = fileRepository.findByFolderId(folder.getId());
        for (File file : files) {
            if (Boolean.TRUE.equals(file.getIsDeleted())) {
                continue;
            }
            file.setIsDeleted(true);
            file.setDeletedAt(LocalDateTime.now());
            fileRepository.save(file);
        }

        List<Folder> subfolders = folderRepository.findByParentFolder(folder);
        for (Folder sub : subfolders) {
            softDeleteFolderRecursive(sub);
        }

        folder.setIsDeleted(true);
        folder.setDeletedAt(LocalDateTime.now());
        folderRepository.save(folder);
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

        if (!file.getUser().getId().equals(userId)) {
            throw new SecurityException("Нет прав на перемещение этого файла");
        }

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
                throw new SecurityException("Нет прав на перемещение этого файла");
            }

            if (Boolean.TRUE.equals(request.getCopy())) {
                File copiedFile = copyFile(file, targetFolder);
                movedFiles.add(copiedFile);
            } else {
                file.setFolder(targetFolder);
                movedFiles.add(fileRepository.save(file));
            }
        }
        return movedFiles;
    }

    
    @Transactional(readOnly = true)
    public boolean hasActivePassword(UUID folderId, UUID userId) {
        Folder folder = folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));
        checkFolderAccess(folder, userId, FolderAccess.AccessLevel.READ);
        return folderPasswordRepository.findByFolderAndIsActive(folder, true).isPresent();
    }

    private File copyFile(File originalFile, Folder targetFolder) {
        FileContent originalContent = originalFile.getFileContent();
        File copiedFile = File.builder()
                .name(originalFile.getName() + " (копия)")
                .originalName(originalFile.getOriginalName())
                .fileContent(originalContent)
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

        checkCanShare(folder, userId);

        if (request.getUserIds() == null || request.getUserIds().isEmpty()) {
            return List.of();
        }

        List<FolderAccess> newAccesses = new ArrayList<>();
        for (UUID sharedUserId : request.getUserIds()) {
            User sharedUser = userRepository.findById(sharedUserId)
                    .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден: " + sharedUserId));

            if (!folderAccessRepository.existsByFolderIdAndUserId(folder.getId(), sharedUserId)) {
                FolderAccess access = FolderAccess.builder()
                        .folder(folder)
                        .user(sharedUser)
                        .accessLevel(FolderAccess.AccessLevel.READ)
                        .canEdit(Boolean.TRUE.equals(request.getCanEdit()))
                        .canDelete(Boolean.TRUE.equals(request.getCanDelete()))
                        .canShare(Boolean.TRUE.equals(request.getCanShare()))
                        .grantedBy(userId)
                        .grantedAt(LocalDateTime.now())
                        .expiresAt(request.getExpiresAt())
                        .build();
                newAccesses.add(folderAccessRepository.save(access));
            }
        }
        return newAccesses;
    }

    private void checkCanShare(Folder folder, UUID userId) {
        if (folder.getUser().getId().equals(userId)) {
            return;
        }

        FolderAccess access = folderAccessRepository
                .findByFolderIdAndUserId(folder.getId(), userId)
                .orElseThrow(() -> new SecurityException("Доступ к папке запрещен"));

        if (!Boolean.TRUE.equals(access.getIsActive())) {
            throw new SecurityException("Доступ к папке отозван");
        }
        if (!Boolean.TRUE.equals(access.getCanShare())) {
            throw new SecurityException("Нет прав на шаринг этой папки");
        }
    }

    public void checkFolderAccess(Folder folder, UUID userId, FolderAccess.AccessLevel requiredLevel) {
        if (Boolean.TRUE.equals(folder.getIsDeleted())) {
            throw new SecurityException("Папка удалена");
        }
        if (folder.getUser().getId().equals(userId)) {
            return;
        }

        FolderAccess access = folderAccessRepository
                .findByFolderIdAndUserId(folder.getId(), userId)
                .orElseThrow(() -> new SecurityException("Доступ к папке запрещен"));

        if (!Boolean.TRUE.equals(access.getIsActive())) {
            throw new SecurityException("Доступ к папке отозван");
        }

        if (!access.getAccessLevel().isAtLeast(requiredLevel)) {
            throw new SecurityException("Недостаточно прав для выполнения операции");
        }
    }

    public PasswordCheckResult checkFolderPassword(UUID folderId, String password) {
        Folder folder = folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));

        String key = "folder:" + folderId;
        if (loginAttemptService.isFolderPasswordBlocked(key)) {
            return PasswordCheckResult.BLOCKED;
        }

        Optional<FolderPassword> passwordOpt = folderPasswordRepository
                .findByFolderAndIsActive(folder, true);
        if (passwordOpt.isEmpty()) {
            return PasswordCheckResult.OK;
        }
        FolderPassword folderPassword = passwordOpt.get();
        boolean ok = verifyPassword(
                password,
                folderPassword.getPasswordHash(),
                folderPassword.getAlgorithm());
        if (!ok) {
            loginAttemptService.folderPasswordFailed(key);
            return PasswordCheckResult.INVALID;
        }
        loginAttemptService.folderPasswordSucceeded(key);
        return PasswordCheckResult.OK;
    }

    @Transactional
    public void setFolderPassword(UUID folderId, String password, UUID userId) {
        Folder folder = folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));
        checkFolderAccess(folder, userId, FolderAccess.AccessLevel.OWNER);

        folderPasswordRepository.deactivateByFolder(folder);

        if (password != null && !password.isEmpty()) {
            FolderPassword folderPassword = FolderPassword.builder()
                    .folder(folder)
                    .passwordHash(hashPassword(password))
                    .salt("")
                    .algorithm("BCRYPT")
                    .isActive(true)
                    .createdAt(LocalDateTime.now())
                    .build();
            folderPasswordRepository.save(folderPassword);
        }
    }

    private void setFolderPassword(Folder folder, String password) {
        FolderPassword folderPassword = FolderPassword.builder()
                .folder(folder)
                .passwordHash(hashPassword(password))
                .salt("")
                .algorithm("BCRYPT")
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

    private String hashPassword(String password) {
        return passwordEncoder.encode(password);
    }

    
    private boolean verifyPassword(String password, String storedHash, String algorithm) {
        if (password == null || storedHash == null) {
            return false;
        }
        if (algorithm == null || "BCRYPT".equalsIgnoreCase(algorithm) || storedHash.startsWith("$2")) {
            return passwordEncoder.matches(password, storedHash);
        }
        if ("LEGACY-SHA256".equalsIgnoreCase(algorithm)) {
            String legacy = sha256Hex(password);
            return MessageDigest.isEqual(
                    legacy.getBytes(StandardCharsets.UTF_8),
                    storedHash.getBytes(StandardCharsets.UTF_8));
        }
        throw new IllegalStateException("Unknown password algorithm: " + algorithm);
    }

    private static String sha256Hex(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(input.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }

    @Transactional(readOnly = true)
    public List<Folder> getFolderTree(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));

        List<Folder> roots = folderRepository.findByUserAndParentFolderIsNull(user);
        return roots.stream()
                .filter(f -> !Boolean.TRUE.equals(f.getIsDeleted()))
                .filter(f -> !Boolean.TRUE.equals(f.getIsHidden()))
                .map(f -> enrichFolderWithSubfolders(f, 0))
                .collect(Collectors.toList());
    }

    private Folder enrichFolderWithSubfolders(Folder folder, int depth) {
        if (depth >= MAX_FOLDER_DEPTH) {
            log.warn("Folder tree depth exceeds {} for folder {}",
                    MAX_FOLDER_DEPTH, folder.getId());
            return folder;
        }
        List<Folder> subfolders = folderRepository.findByParentFolder(folder).stream()
                .filter(f -> !Boolean.TRUE.equals(f.getIsDeleted()))
                .filter(f -> !Boolean.TRUE.equals(f.getIsHidden()))
                .collect(Collectors.toList());

        List<Folder> enriched = subfolders.stream()
                .map(f -> enrichFolderWithSubfolders(f, depth + 1))
                .collect(Collectors.toList());
        folder.setSubfolders(enriched);
        return folder;
    }

    public boolean checkHiddenFolderKey(UUID folderId, String key) {
        Folder folder = folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));

        if (folder.getHiddenFolderKeyHash() == null) {
            return false;
        }

        String attemptKey = "hidden:" + folderId;
        if (loginAttemptService.isFolderPasswordBlocked(attemptKey)) {
            throw new SecurityException("Too many attempts, try again later");
        }

        boolean ok = passwordEncoder.matches(key, folder.getHiddenFolderKeyHash());
        if (ok) {
            loginAttemptService.folderPasswordSucceeded(attemptKey);
        } else {
            loginAttemptService.folderPasswordFailed(attemptKey);
        }
        return ok;
    }

    @Transactional(readOnly = true)
    public Page<File> getFolderFilesPaged(UUID folderId, UUID userId, Pageable pageable) {
        Folder folder = folderRepository.findById(folderId)
                .orElseThrow(() -> new IllegalArgumentException("Папка не найдена"));
        checkFolderAccess(folder, userId, FolderAccess.AccessLevel.READ);
        return fileRepository.findByFolderIdAndIsDeletedFalse(folderId, pageable);
    }
}
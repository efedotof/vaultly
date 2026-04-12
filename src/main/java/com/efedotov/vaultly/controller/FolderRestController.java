package com.efedotov.vaultly.controller;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.efedotov.vaultly.dto.file.FileDto;
import com.efedotov.vaultly.dto.folder.AddFileToFolderRequest;
import com.efedotov.vaultly.dto.folder.FolderAccessDto;
import com.efedotov.vaultly.dto.folder.FolderCreateDto;
import com.efedotov.vaultly.dto.folder.FolderDto;
import com.efedotov.vaultly.dto.folder.FolderMoveDto;
import com.efedotov.vaultly.dto.folder.FolderPasswordDto;
import com.efedotov.vaultly.dto.folder.FolderShareDto;
import com.efedotov.vaultly.dto.folder.FolderUpdateDto;
import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.model.Folder;
import com.efedotov.vaultly.model.FolderAccess;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.FolderService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/folders")
@RequiredArgsConstructor
@Slf4j
public class FolderRestController {

    private final FolderService folderService;

    @PostMapping
    public FolderDto createFolder(@RequestBody FolderCreateDto request,
            @AuthenticationPrincipal CustomUserDetails user) {
        log.info("REST create folder request for user: {}", user.getUsername());
        try {
            Folder folder = folderService.createFolder(request, user.getUserId());
            log.info("Папка создана: {} пользователем {}", folder.getName(), user.getUsername());
            return convertToDto(folder);
        } catch (Exception e) {
            log.error("Ошибка при создании папки: {}", e.getMessage());
            throw e;
        }
    }

    @DeleteMapping("/{folderId}")
    public void deleteFolder(@PathVariable UUID folderId,
            @AuthenticationPrincipal CustomUserDetails user) {
        log.info("REST delete folder request for user: {}", user.getUsername());
        try {
            folderService.deleteFolder(folderId, user.getUserId());
            log.info("Папка удалена: {} пользователем {}", folderId, user.getUsername());
        } catch (Exception e) {
            log.error("Ошибка при удалении папки: {}", e.getMessage());
            throw e;
        }
    }

    @PutMapping("/{folderId}")
    public FolderDto renameFolder(@PathVariable UUID folderId,
            @RequestBody FolderUpdateDto request,
            @AuthenticationPrincipal CustomUserDetails user) {
        log.info("REST rename folder request for user: {}", user.getUsername());
        try {
            Folder folder = folderService.renameFolder(folderId, request, user.getUserId());
            log.info("Папка переименована: {} -> {}", folderId, folder.getName());
            return convertToDto(folder);
        } catch (Exception e) {
            log.error("Ошибка при переименовании папки: {}", e.getMessage());
            throw e;
        }
    }

    @PostMapping("/{folderId}/files")
    public FileDto addFileToFolder(@PathVariable UUID folderId,
            @RequestBody AddFileToFolderRequest request,
            @AuthenticationPrincipal CustomUserDetails user) {
        log.info("REST add file to folder request for user: {}", user.getUsername());
        try {
            File file = folderService.addFileToFolder(request.getFileId(), folderId, user.getUserId());
            log.info("Файл {} добавлен в папку {}", request.getFileId(), folderId);
            return convertFileToDto(file);
        } catch (Exception e) {
            log.error("Ошибка при добавлении файла в папку: {}", e.getMessage());
            throw e;
        }
    }

    @PostMapping("/move")
    public List<FileDto> moveFiles(@RequestBody FolderMoveDto request,
            @AuthenticationPrincipal CustomUserDetails user) {
        log.info("REST move files request for user: {}", user.getUsername());
        try {
            List<File> movedFiles = folderService.moveFiles(request, user.getUserId());
            log.info("Файлы перемещены в папку {}", request.getTargetFolderId());
            return movedFiles.stream().map(this::convertFileToDto).collect(Collectors.toList());
        } catch (Exception e) {
            log.error("Ошибка при перемещении файлов: {}", e.getMessage());
            throw e;
        }
    }

    @DeleteMapping("/{folderId}/files/{fileId}")
    public FileDto removeFileFromFolder(@PathVariable UUID folderId,
            @PathVariable UUID fileId,
            @AuthenticationPrincipal CustomUserDetails user) {
        log.info("REST remove file from folder request for user: {}", user.getUsername());
        try {
            File file = folderService.removeFileFromFolder(fileId, user.getUserId());
            log.info("Файл {} удален из папки {}", fileId, folderId);
            return convertFileToDto(file);
        } catch (Exception e) {
            log.error("Ошибка при удалении файла из папки: {}", e.getMessage());
            throw e;
        }
    }

    @PostMapping("/{folderId}/close")
    public FolderDto closeFolderForOthers(@PathVariable UUID folderId,
            @AuthenticationPrincipal CustomUserDetails user) {
        log.info("REST close folder for others request for user: {}", user.getUsername());
        try {
            Folder folder = folderService.closeFolderForOthers(folderId, user.getUserId());
            log.info("Папка {} закрыта для других пользователей", folderId);
            return convertToDto(folder);
        } catch (Exception e) {
            log.error("Ошибка при закрытии папки: {}", e.getMessage());
            throw e;
        }
    }

    @PostMapping("/{folderId}/share")
    public List<FolderAccess> shareFolder(@PathVariable UUID folderId,
            @RequestBody FolderShareDto request,
            @AuthenticationPrincipal CustomUserDetails user) {
        log.info("REST share folder request for user: {}", user.getUsername());
        try {
            request.setFolderId(folderId);
            List<FolderAccess> accesses = folderService.shareFolder(request, user.getUserId());
            log.info("Доступ к папке {} предоставлен пользователям", folderId);
            return accesses;
        } catch (Exception e) {
            log.error("Ошибка при предоставлении доступа: {}", e.getMessage());
            throw e;
        }
    }

    @PostMapping("/{folderId}/access/check")
    public boolean checkFolderAccess(@PathVariable UUID folderId,
            @RequestBody FolderAccessDto request,
            @AuthenticationPrincipal CustomUserDetails user) {
        log.info("REST check folder access request for user: {}", user.getUsername());
        try {
            Folder folder = folderService.getFolderById(folderId);

            if (folderService.hasActivePassword(folderId)) {
                if (request.getPassword() == null) {
                    return false;
                }
                return folderService.checkFolderPassword(folderId, request.getPassword());
            }

            if (request.getHiddenFolderKey() != null) {
                return folderService.checkHiddenFolderKey(folderId, request.getHiddenFolderKey());
            }
            folderService.checkFolderAccess(folder, user.getUserId(), FolderAccess.AccessLevel.READ);
            return true;
        } catch (SecurityException e) {
            return false;
        } catch (Exception e) {
            log.error("Ошибка при проверке доступа к папке: {}", e.getMessage());
            throw e;
        }
    }

    @GetMapping("/tree")
    public List<FolderDto> getFolderTree(@AuthenticationPrincipal CustomUserDetails user) {
        log.info("REST get folder tree request for user: {}", user.getUsername());
        try {
            List<Folder> folders = folderService.getFolderTree(user.getUserId());
            return folders.stream()
                    .map(this::convertToDto)
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.error("Ошибка при получении дерева папок: {}", e.getMessage());
            throw e;
        }
    }

    @GetMapping("/{folderId}/files")
    public List<FileDto> getFolderFiles(@PathVariable UUID folderId,
            @AuthenticationPrincipal CustomUserDetails user) {
        log.info("REST get folder files request for user: {}", user.getUsername());
        try {
            List<File> files = folderService.getFolderFiles(folderId, user.getUserId());
            return files.stream()
                    .map(this::convertFileToDto)
                    .collect(Collectors.toList());
        } catch (Exception e) {
            log.error("Ошибка при получении файлов папки: {}", e.getMessage());
            throw e;
        }
    }

    private FolderDto convertToDto(Folder folder) {
        if (folder == null)
            return null;

        FolderDto dto = new FolderDto();
        dto.setId(folder.getId());
        dto.setName(folder.getName());
        dto.setPath(folder.getPath());
        dto.setType(folder.getType());
        dto.setIsHidden(folder.getIsHidden());
        dto.setIsLocked(folder.getIsLocked());
        dto.setAllowedUsers(folder.getAllowedUsers());
        dto.setCreatedAt(folder.getCreatedAt());
        dto.setUpdatedAt(folder.getUpdatedAt());

        if (folder.getParentFolder() != null) {
            dto.setParentFolderId(folder.getParentFolder().getId());
            dto.setParentFolderName(folder.getParentFolder().getName());
        }

        if (folder.getSubfolders() != null && !folder.getSubfolders().isEmpty()) {
            List<FolderDto> subfolderDtos = folder.getSubfolders().stream()
                    .map(this::convertToDto)
                    .collect(Collectors.toList());
            dto.setSubfolders(subfolderDtos);
        }

        if (folder.getFiles() != null && !folder.getFiles().isEmpty()) {
            List<FileDto> fileDtos = folder.getFiles().stream()
                    .map(this::convertFileToDto)
                    .collect(Collectors.toList());
            dto.setFiles(fileDtos);
        }

        return dto;
    }

    @PostMapping("/{folderId}/password")
    public void setFolderPassword(@PathVariable UUID folderId,
            @RequestBody FolderPasswordDto request,
            @AuthenticationPrincipal CustomUserDetails user) {
        log.info("REST set folder password request for user: {}", user.getUsername());
        folderService.setFolderPassword(folderId, request.getPassword(), user.getUserId());
    }

    private FileDto convertFileToDto(File file) {
        if (file == null)
            return null;

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
        }
        return dto;
    }
}
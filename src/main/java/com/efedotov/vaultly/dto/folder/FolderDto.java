package com.efedotov.vaultly.dto.folder;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import com.efedotov.vaultly.dto.file.FileDto;
import com.efedotov.vaultly.model.FolderType;

import lombok.Data;

@Data
public class FolderDto {
    private UUID id;
    private String name;
    private String path;
    private FolderType type;
    private Boolean isHidden;
    private Boolean isLocked;
    private String allowedUsers;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private UUID parentFolderId;
    private String parentFolderName;
    private List<FolderDto> subfolders;
    private List<FileDto> files;
}
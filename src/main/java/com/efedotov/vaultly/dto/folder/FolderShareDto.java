package com.efedotov.vaultly.dto.folder;

import lombok.Data;

import java.util.UUID;
import java.util.List;

@Data
public class FolderShareDto {
    private UUID folderId;
    private List<UUID> userIds;
    private Boolean canEdit = false;
    private Boolean canDelete = false;
    private Boolean canShare = false;
    private String message;
}
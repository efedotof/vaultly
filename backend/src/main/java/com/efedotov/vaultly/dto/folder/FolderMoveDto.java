package com.efedotov.vaultly.dto.folder;

import java.util.List;
import java.util.UUID;

import lombok.Data;

@Data
public class FolderMoveDto {
    private List<UUID> fileIds;
    private UUID targetFolderId;
    private UUID sourceFolderId;
    private Boolean copy = false;
}
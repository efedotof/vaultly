package com.efedotov.vaultly.dto.folder;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
public class FolderShareDto {
    private UUID folderId;

    @NotEmpty(message = "userIds не должен быть пустым")
    @Size(max = 100, message = "userIds: не более 100 записей за раз")
    private List<UUID> userIds;

    private Boolean canEdit = false;
    private Boolean canDelete = false;
    private Boolean canShare = false;
    private String message;
    private LocalDateTime expiresAt;
}
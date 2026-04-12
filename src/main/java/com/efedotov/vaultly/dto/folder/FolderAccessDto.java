package com.efedotov.vaultly.dto.folder;

import lombok.Data;

import java.util.UUID;

@Data
public class FolderAccessDto {
    private UUID folderId;
    private String password;
    private String hiddenFolderKey;
}
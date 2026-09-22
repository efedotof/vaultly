package com.efedotov.vaultly.dto.folder;

import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.UUID;

@Data
public class FolderAccessDto {
    private UUID folderId;

    @Size(max = 128)
    private String password;

    @Size(max = 255)
    private String hiddenFolderKey;
}
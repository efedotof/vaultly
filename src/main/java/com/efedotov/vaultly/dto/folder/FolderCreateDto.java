package com.efedotov.vaultly.dto.folder;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.UUID;

@Data
public class FolderCreateDto {
    @NotBlank(message = "Имя папки обязательно")
    private String name;

    private UUID parentFolderId;

    private Boolean isHidden = false;

    private String hiddenFolderKey;

    private Boolean isPrivate = true;

    private String password;

    private String description;
}
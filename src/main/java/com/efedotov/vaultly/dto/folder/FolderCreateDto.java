package com.efedotov.vaultly.dto.folder;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.UUID;

@Data
public class FolderCreateDto {
    @NotBlank(message = "Имя папки обязательно")
    @Size(max = 255)
    private String name;

    private UUID parentFolderId;

    private Boolean isHidden = false;

    @Size(max = 255)
    private String hiddenFolderKey;

    @Size(max = 128)
    private String password;

    @Size(max = 500)
    private String description;
}
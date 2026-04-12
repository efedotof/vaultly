package com.efedotov.vaultly.dto.folder;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class FolderUpdateDto {
    @NotBlank(message = "Новое имя обязательно")
    private String name;

    private String description;
}
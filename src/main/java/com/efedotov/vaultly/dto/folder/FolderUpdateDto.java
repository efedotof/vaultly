package com.efedotov.vaultly.dto.folder;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class FolderUpdateDto {
    @NotBlank(message = "Новое имя обязательно")
    @Size(max = 255)
    private String name;

    @Size(max = 500)
    private String description;
}
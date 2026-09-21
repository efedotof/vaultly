package com.efedotov.vaultly.dto.file;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class FileRenameRequest {
    @NotBlank
    private String newName;
}

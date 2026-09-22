package com.efedotov.vaultly.dto.folder;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class FolderPasswordDto {
    @Size(max = 128)
    private String password;
}
package com.efedotov.vaultly.dto.user;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UpdateKeysRequest {
    @NotBlank
    private String publicKey;

    @NotBlank
    private String currentPassword;
}

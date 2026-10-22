package com.efedotov.vaultly.dto.user;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UpdateRecoveryKeysRequest {

    @NotBlank
    private String currentPassword;

    @NotBlank
    private String recoveryPublicKey;

    @NotBlank
    private String recoveryEncryptedRsaKey;

}
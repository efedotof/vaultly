package com.efedotov.vaultly.dto.user;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UpdateRecoveryKeysRequest {
    @NotBlank
    private String recoveryPublicKey;
    @NotBlank
    private String recoveryPrivateKeyEncrypted;
    @NotBlank
    private String recoveryEncryptedRsaKey;
    @NotBlank
    private String currentPassword;
}
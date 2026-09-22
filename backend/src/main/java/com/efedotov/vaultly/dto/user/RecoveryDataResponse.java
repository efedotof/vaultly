package com.efedotov.vaultly.dto.user;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class RecoveryDataResponse {
    private String recoveryEncryptedRsaKey;
    private String salt;
}
package com.efedotov.vaultly.dto.auth;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RecoveryChallengeRequest {
    @NotBlank
    private String publicKey;
}
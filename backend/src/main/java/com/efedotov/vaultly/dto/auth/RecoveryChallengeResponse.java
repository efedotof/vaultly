package com.efedotov.vaultly.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class RecoveryChallengeResponse {
    private String challenge;
    private long expiresInSeconds;
}
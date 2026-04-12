package com.efedotov.vaultly.dto.auth;

import java.util.Set;
import java.util.UUID;

import lombok.Data;

@Data
public class AuthResponse {
    private String accessToken;
    private String refreshToken;
    private UUID userId;
    private String email;
    private String username;
    private Long storageUsed;
    private Long storageLimit;
    private Set<String> roles;
}
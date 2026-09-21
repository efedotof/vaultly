package com.efedotov.vaultly.dto.auth;

import lombok.Data;
import java.util.Set;
import java.util.UUID;

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
    private Boolean totpEnabled;
}
package com.efedotov.vaultly.dto.auth;

import lombok.Data;

@Data
public class TokenValidationRequest {
    private String token;
}
package com.efedotov.vaultly.dto.auth;

import lombok.Data;

@Data
public class LogoutRequest {
    private String token;
}
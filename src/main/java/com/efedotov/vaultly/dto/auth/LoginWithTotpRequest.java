package com.efedotov.vaultly.dto.auth;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginWithTotpRequest {
    @NotBlank
    private String preAuthToken;
    @NotBlank
    private String totpCode;
}
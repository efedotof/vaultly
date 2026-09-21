package com.efedotov.vaultly.dto.auth;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class TotpVerifyRequest {
    @NotBlank
    private String code;
}
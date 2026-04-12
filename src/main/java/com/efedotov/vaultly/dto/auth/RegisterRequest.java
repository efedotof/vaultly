package com.efedotov.vaultly.dto.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterRequest {
    @NotBlank
    @Size(min = 3, max = 50)
    private String username;
    @NotBlank
    @Size(min = 6)
    private String password;
    private String firstName;
    private String lastName;
    private String publicKey;
    private String privateKeyEncrypted;
    private String salt;
}
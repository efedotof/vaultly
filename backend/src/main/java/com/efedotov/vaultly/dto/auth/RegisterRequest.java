package com.efedotov.vaultly.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterRequest {
    @NotBlank
    @Size(min = 3, max = 50)
    @Pattern(regexp = "^[a-zA-Z0-9_.-]+$", message = "Username: a-z, A-Z, 0-9, _, ., -")
    private String username;

    @NotBlank
    @Size(min = 12, max = 64, message = "Пароль должен быть от 12 до 64 символов")
    @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^A-Za-z0-9]).+$", message = "Пароль должен содержать строчную, заглавную буквы, цифру и спецсимвол")
    private String password;

    private String firstName;
    private String lastName;
    private String publicKey;
    private String privateKeyEncrypted;
    private String salt;

    @Email
    @Size(max = 255)
    private String email;
}
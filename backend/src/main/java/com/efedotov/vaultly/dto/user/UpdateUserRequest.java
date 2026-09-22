package com.efedotov.vaultly.dto.user;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateUserRequest {
    @Size(min = 3, max = 50)
    @Pattern(regexp = "^[a-zA-Z0-9_.-]+$", message = "Username: a-z, A-Z, 0-9, _, ., -")
    private String username;

    @Size(max = 100)
    private String firstName;

    @Size(max = 100)
    private String lastName;
}
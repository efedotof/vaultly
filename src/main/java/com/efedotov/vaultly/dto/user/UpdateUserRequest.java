package com.efedotov.vaultly.dto.user;

import lombok.Data;

@Data
public class UpdateUserRequest {
    private String username;
    private String firstName;
    private String lastName;
}

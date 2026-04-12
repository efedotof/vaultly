package com.efedotov.vaultly.dto.user;

import java.util.UUID;

import lombok.Data;

@Data
public class UserProfileDto {
    private UUID id;
    private String email;
    private String username;
    private String firstName;
    private String lastName;
    private String avatarUrl;
    private Long storageUsed;
    private Long storageLimit;
    private String publicKey;
}
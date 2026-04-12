package com.efedotov.vaultly.dto.user;

import lombok.Data;

@Data
public class AvatarUploadResponse {
    private String avatarUrl;
    private Long fileSize;
}

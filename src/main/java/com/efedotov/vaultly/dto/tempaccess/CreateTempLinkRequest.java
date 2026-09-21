package com.efedotov.vaultly.dto.tempaccess;

import java.time.LocalDateTime;
import java.util.UUID;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateTempLinkRequest {
    @NotNull
    private UUID fileId;
    @NotNull
    private LocalDateTime expiresAt;
    private Integer maxDownloads;
    private String password;
}

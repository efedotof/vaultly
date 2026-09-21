package com.efedotov.vaultly.dto.tempaccess;

import java.time.LocalDateTime;
import java.util.UUID;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateTempLinkRequest {
    @NotNull
    private UUID fileId;

    @NotNull
    private LocalDateTime expiresAt;

    @Min(1)
    @Max(100_000)
    private Integer maxDownloads;

    @Size(max = 128)
    private String password;
}
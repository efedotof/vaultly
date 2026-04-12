package com.efedotov.vaultly.dto.tempaccess;

import java.time.LocalDateTime;

import lombok.Data;

@Data
public class TempLinkResponse {
    private String token;
    private String accessUrl;
    private LocalDateTime expiresAt;
    private Integer maxDownloads;
    private Integer downloadsCount;
}

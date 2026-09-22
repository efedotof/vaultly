package com.efedotov.vaultly.dto.tempaccess;

import java.time.LocalDateTime;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class TempLinkInfo {
    private String fileName;
    private LocalDateTime expiresAt;
    private String mimeType;
    private boolean hasPassword;
}
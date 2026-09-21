package com.efedotov.vaultly.dto.device;

import java.time.LocalDateTime;
import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeviceResponse {
    private UUID id;
    private String uniqueId;
    private String deviceName;
    private String deviceType;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime lastUsedAt;
}
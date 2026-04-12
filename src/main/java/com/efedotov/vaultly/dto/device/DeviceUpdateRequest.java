package com.efedotov.vaultly.dto.device;

import lombok.Data;

@Data
public class DeviceUpdateRequest {
    private String deviceName;
    private Boolean isActive;
}
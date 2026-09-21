package com.efedotov.vaultly.dto.device;

import lombok.Data;

@Data
public class DeviceRegisterRequest {
    private String deviceName;
    private String uniqueId;
    private String deviceType;
    private String publicKey;
    private String encryptedPrivateKey;
}
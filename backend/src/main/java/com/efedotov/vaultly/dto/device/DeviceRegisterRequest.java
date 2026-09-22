package com.efedotov.vaultly.dto.device;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class DeviceRegisterRequest {
    @NotBlank
    @Size(max = 255)
    private String deviceName;

    @NotBlank
    @Size(max = 255)
    private String uniqueId;

    @Size(max = 50)
    private String deviceType;

    private String publicKey;
    private String encryptedPrivateKey;
}
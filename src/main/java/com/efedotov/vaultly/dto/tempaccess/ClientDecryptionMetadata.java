package com.efedotov.vaultly.dto.tempaccess;

import lombok.Data;

@Data
public class ClientDecryptionMetadata {
    private String presignedUrl;
    private String encryptedKey;
    private String iv;
    private String fileName;
    private String mimeType;
    private Long originalSize;
}
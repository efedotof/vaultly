package com.efedotov.vaultly.dto.file;

import lombok.Data;

@Data
public class DecryptionMetadata {
    private String presignedUrl;
    private String encryptedKey;
    private String iv;
    private long originalSize;
    private String mimeType;
    private String fileName;
}

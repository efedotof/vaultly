package com.efedotov.vaultly.dto.pair;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class PairBlobUploadRequest {
    @NotBlank
    @Size(max = 200)
    private String responderPublicKey;

    @NotBlank
    @Size(max = 32)
    private String responderAlgorithm;

    @NotBlank
    @Size(max = 16_384)                       // RSA-4096 private key ≈ 3.2 KB
    private String blobCiphertext;            // Base64(AES-GCM ciphertext+tag)

    @NotBlank
    @Size(max = 64)
    private String blobNonce;                 // Base64(12-byte IV)

    @NotBlank
    @Size(max = 64)
    private String blobAlgorithm;             // e.g. "X25519-HKDF-SHA256-AES256-GCM"
}
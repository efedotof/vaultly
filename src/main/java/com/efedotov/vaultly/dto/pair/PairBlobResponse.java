package com.efedotov.vaultly.dto.pair;

import java.time.LocalDateTime;
import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class PairBlobResponse {
    private UUID pairingId;
    private String responderPublicKey;
    private String responderAlgorithm;
    private String blobCiphertext;
    private String blobNonce;
    private String blobAlgorithm;
    private LocalDateTime expiresAt;
}
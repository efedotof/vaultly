package com.efedotov.vaultly.dto.pair;

import java.time.LocalDateTime;
import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class PairInfoResponse {
    private UUID pairingId;
    private String initiatorPublicKey;
    private String initiatorAlgorithm;
    private LocalDateTime expiresAt;
    private boolean blobAlreadySet;
}
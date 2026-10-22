package com.efedotov.vaultly.dto.pair;

import java.time.LocalDateTime;
import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class PairInitResponse {
    private UUID pairingId;
    private LocalDateTime expiresAt;
}
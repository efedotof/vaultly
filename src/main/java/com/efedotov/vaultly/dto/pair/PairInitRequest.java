package com.efedotov.vaultly.dto.pair;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class PairInitRequest {
    @NotBlank
    @Size(max = 200)
    private String initiatorPublicKey;        // Base64(X25519 or P-256 pubkey)

    @NotBlank
    @Size(max = 32)
    private String initiatorAlgorithm;        // "X25519" | "P-256"
}
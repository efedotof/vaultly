package com.efedotov.vaultly.model;

import java.time.LocalDateTime;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "device_pairings")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DevicePairing {

    @Id
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "initiator_public_key", nullable = false, columnDefinition = "TEXT")
    private String initiatorPublicKey;

    @Column(name = "initiator_algorithm", nullable = false, length = 32)
    private String initiatorAlgorithm;

    @Column(name = "responder_public_key", columnDefinition = "TEXT")
    private String responderPublicKey;

    @Column(name = "responder_algorithm", length = 32)
    private String responderAlgorithm;

    @Column(name = "blob_ciphertext", columnDefinition = "TEXT")
    private String blobCiphertext;

    @Column(name = "blob_nonce", columnDefinition = "TEXT")
    private String blobNonce;

    @Column(name = "blob_algorithm", length = 64)
    private String blobAlgorithm;

    @Column(name = "blob_created_at")
    private LocalDateTime blobCreatedAt;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(name = "consumed_at")
    private LocalDateTime consumedAt;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
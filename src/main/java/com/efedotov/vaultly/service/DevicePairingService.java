package com.efedotov.vaultly.service;

import java.time.LocalDateTime;
import java.util.UUID;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.efedotov.vaultly.dto.pair.PairBlobResponse;
import com.efedotov.vaultly.dto.pair.PairBlobUploadRequest;
import com.efedotov.vaultly.dto.pair.PairInfoResponse;
import com.efedotov.vaultly.dto.pair.PairInitRequest;
import com.efedotov.vaultly.dto.pair.PairInitResponse;
import com.efedotov.vaultly.exception.BadRequestException;
import com.efedotov.vaultly.exception.NotFoundException;
import com.efedotov.vaultly.model.DevicePairing;
import com.efedotov.vaultly.repository.DevicePairingRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class DevicePairingService {

    private static final int PAIRING_TTL_MINUTES = 10;
    private static final int MAX_ACTIVE_PAIRINGS_PER_USER = 5;
    private static final int MAX_BLOB_BYTES = 8 * 1024;

    private final DevicePairingRepository pairingRepository;

    @Transactional
    public PairInitResponse initPairing(UUID userId, PairInitRequest request) {
        LocalDateTime now = LocalDateTime.now();

        long active = pairingRepository.countActiveByUserId(userId, now);
        if (active >= MAX_ACTIVE_PAIRINGS_PER_USER) {
            throw new BadRequestException(
                    "Too many active pairings. Wait for them to expire or consume existing ones.");
        }

        DevicePairing pairing = DevicePairing.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .initiatorPublicKey(request.getInitiatorPublicKey())
                .initiatorAlgorithm(request.getInitiatorAlgorithm())
                .expiresAt(now.plusMinutes(PAIRING_TTL_MINUTES))
                .createdAt(now)
                .build();
        pairingRepository.save(pairing);

        log.info("Pairing {} created for user {} (expires at {})",
                pairing.getId(), userId, pairing.getExpiresAt());
        return new PairInitResponse(pairing.getId(), pairing.getExpiresAt());
    }

    @Transactional(readOnly = true)
    public PairInfoResponse getInfo(UUID userId, UUID pairingId) {
        DevicePairing p = loadActive(userId, pairingId, false);
        return new PairInfoResponse(
                p.getId(),
                p.getInitiatorPublicKey(),
                p.getInitiatorAlgorithm(),
                p.getExpiresAt(),
                p.getBlobCiphertext() != null);
    }

    @Transactional
    public void uploadBlob(UUID userId, UUID pairingId, PairBlobUploadRequest request) {
        DevicePairing p = loadActive(userId, pairingId, false);

        if (p.getBlobCiphertext() != null) {
            throw new BadRequestException("Blob already uploaded for this pairing");
        }
        if (request.getBlobCiphertext().length() > MAX_BLOB_BYTES * 2) {
            throw new BadRequestException("Blob too large");
        }

        p.setResponderPublicKey(request.getResponderPublicKey());
        p.setResponderAlgorithm(request.getResponderAlgorithm());
        p.setBlobCiphertext(request.getBlobCiphertext());
        p.setBlobNonce(request.getBlobNonce());
        p.setBlobAlgorithm(request.getBlobAlgorithm());
        p.setBlobCreatedAt(LocalDateTime.now());
        pairingRepository.save(p);

        log.info("Blob uploaded for pairing {} (user {})", pairingId, userId);
    }

    @Transactional
    public PairBlobResponse fetchBlob(UUID userId, UUID pairingId) {
        DevicePairing p = loadActive(userId, pairingId, true);

        if (p.getBlobCiphertext() == null) {
            throw new NotFoundException("Blob not yet uploaded");
        }

        p.setConsumedAt(LocalDateTime.now());
        pairingRepository.save(p);

        log.info("Pairing {} consumed by user {}", pairingId, userId);

        return new PairBlobResponse(
                p.getId(),
                p.getResponderPublicKey(),
                p.getResponderAlgorithm(),
                p.getBlobCiphertext(),
                p.getBlobNonce(),
                p.getBlobAlgorithm(),
                p.getExpiresAt());
    }

    private DevicePairing loadActive(UUID userId, UUID pairingId, boolean requireNotConsumed) {
        DevicePairing p = pairingRepository.findByIdAndUserId(pairingId, userId)
                .orElseThrow(() -> new NotFoundException("Pairing not found"));

        LocalDateTime now = LocalDateTime.now();
        if (p.getExpiresAt().isBefore(now)) {
            throw new NotFoundException("Pairing expired");
        }
        if (requireNotConsumed && p.getConsumedAt() != null) {
            throw new NotFoundException("Pairing already consumed");
        }
        return p;
    }

    @Scheduled(fixedRate = 300_000)  
    @Transactional
    public void cleanupExpired() {
        pairingRepository.deleteExpired(LocalDateTime.now());
    }
}
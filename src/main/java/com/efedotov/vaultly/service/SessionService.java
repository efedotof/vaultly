package com.efedotov.vaultly.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.efedotov.vaultly.model.UserSession;
import com.efedotov.vaultly.repository.UserSessionRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class SessionService {

    private final UserSessionRepository sessionRepository;

    private static final long SESSION_DURATION_HOURS = 12;
    private static final int TOKEN_BYTES = 32;

    @Transactional
    public CreatedSession createSession(UUID userId) {
        String plaintextToken = generateOpaqueToken();
        String tokenHash = sha256Hex(plaintextToken);

        Instant now = Instant.now();
        UserSession session = UserSession.builder()
                .tokenHash(tokenHash)
                .userId(userId)
                .createdAt(now)
                .expiresAt(now.plus(SESSION_DURATION_HOURS, ChronoUnit.HOURS))
                .build();

        sessionRepository.save(session);
        return new CreatedSession(plaintextToken, session);
    }

    @Transactional(readOnly = true)
    public Optional<UserSession> findValidSession(String plaintextToken) {
        if (plaintextToken == null || plaintextToken.isBlank()) {
            return Optional.empty();
        }
        return sessionRepository.findValidSession(sha256Hex(plaintextToken), Instant.now());
    }

    @Transactional
    public void deleteSession(String plaintextToken) {
        if (plaintextToken == null || plaintextToken.isBlank()) {
            return;
        }
        String tokenHash = sha256Hex(plaintextToken);
        sessionRepository.deleteById(tokenHash);
        log.info("Session deleted (token hash prefix: {}...)", tokenHash.substring(0, 8));
    }

    @Transactional
    @Scheduled(fixedRate = 86400000)
    public void cleanExpiredSessions() {
        sessionRepository.deleteExpiredSessions(Instant.now());
        log.info("Очистка просроченных сессий выполнена");
    }

    private String generateOpaqueToken() {
        byte[] randomBytes = new byte[TOKEN_BYTES];
        new SecureRandom().nextBytes(randomBytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);
    }

    private String sha256Hex(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(input.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }

    public record CreatedSession(String plaintextToken, UserSession session) {
    }
}
package com.efedotov.vaultly.service;

import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
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

    @Transactional
    public UserSession createSession(UUID userId) {
        String token = generateOpaqueToken();

        UserSession session = UserSession.builder()
                .token(token)
                .userId(userId)
                .createdAt(Instant.now())
                .expiresAt(Instant.now().plus(SESSION_DURATION_HOURS, ChronoUnit.HOURS))
                .build();

        return sessionRepository.save(session);
    }

    private String generateOpaqueToken() {
        byte[] randomBytes = new byte[32];
        new SecureRandom().nextBytes(randomBytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);
    }

    @Transactional(readOnly = true)
    public Optional<UserSession> findValidSession(String token) {
        return sessionRepository.findValidSession(token, Instant.now());
    }

    @Transactional
    public void deleteSession(String token) {
        sessionRepository.deleteById(token);
        log.info("Session deleted for token: {}", token);
    }

    @Transactional
    @Scheduled(fixedRate = 86400000)
    public void cleanExpiredSessions() {
        sessionRepository.deleteExpiredSessions(Instant.now());
        log.info("Очистка просроченных сессий выполнена");
    }
}
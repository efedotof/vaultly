package com.efedotov.vaultly.service;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
public class PreAuthTokenService {

    private static final Duration TTL = Duration.ofMinutes(3);
    private static final int MAX_ENTRIES = 50_000;

    private final Map<String, Entry> tokens = new ConcurrentHashMap<>();
    private final SecureRandom secureRandom = new SecureRandom();

    public String issue(UUID userId) {
        if (tokens.size() > MAX_ENTRIES) {
            cleanExpired();
        }
        byte[] nonce = new byte[32];
        secureRandom.nextBytes(nonce);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(nonce);
        tokens.put(token, new Entry(userId, Instant.now().plus(TTL)));
        return token;
    }

    public UUID consume(String token) {
        Entry e = tokens.remove(token);
        if (e == null || Instant.now().isAfter(e.expiresAt)) {
            return null;
        }
        return e.userId;
    }

    @Scheduled(fixedRate = 600_000)
    public void cleanExpired() {
        Instant now = Instant.now();
        tokens.entrySet().removeIf(en -> now.isAfter(en.getValue().expiresAt));
    }

    private record Entry(UUID userId, Instant expiresAt) {
    }
}
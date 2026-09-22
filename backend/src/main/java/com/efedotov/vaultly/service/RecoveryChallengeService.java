package com.efedotov.vaultly.service;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
public class RecoveryChallengeService {

    private static final Duration TTL = Duration.ofMinutes(5);
    private static final int MAX_ENTRIES = 10_000;

    private final Map<String, Entry> challenges = new ConcurrentHashMap<>();
    private final SecureRandom secureRandom = new SecureRandom();

    public String issue(String publicKeyHash) {
        if (challenges.size() > MAX_ENTRIES) {
            cleanExpired();
        }
        byte[] nonce = new byte[32];
        secureRandom.nextBytes(nonce);
        String challenge = Base64.getUrlEncoder().withoutPadding().encodeToString(nonce);
        challenges.put(challenge, new Entry(Instant.now().plus(TTL), publicKeyHash));
        return challenge;
    }

    public boolean consume(String challenge, String publicKeyHash) {
        Entry entry = challenges.remove(challenge);
        return entry != null
                && Instant.now().isBefore(entry.expiresAt)
                && entry.publicKeyHash.equals(publicKeyHash);
    }

    @Scheduled(fixedRate = 600_000)
    public void cleanExpired() {
        Instant now = Instant.now();
        challenges.entrySet().removeIf(e -> now.isAfter(e.getValue().expiresAt));
    }

    private record Entry(Instant expiresAt, String publicKeyHash) {
    }
}
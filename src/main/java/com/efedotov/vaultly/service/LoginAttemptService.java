package com.efedotov.vaultly.service;

import org.springframework.stereotype.Service;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class LoginAttemptService {
    private static final int MAX_ATTEMPTS = 5;
    private static final long BLOCK_DURATION_SECONDS = 900;

    private final Map<String, AttemptInfo> attemptsCache = new ConcurrentHashMap<>();

    public void loginFailed(String username) {
        AttemptInfo info = attemptsCache.computeIfAbsent(username, k -> new AttemptInfo());
        info.failures++;
        info.lastAttempt = Instant.now();
    }

    public boolean isBlocked(String username) {
        AttemptInfo info = attemptsCache.get(username);
        if (info == null)
            return false;
        if (info.failures >= MAX_ATTEMPTS) {
            if (Instant.now().isBefore(info.lastAttempt.plusSeconds(BLOCK_DURATION_SECONDS))) {
                return true;
            } else {
                attemptsCache.remove(username);
                return false;
            }
        }
        return false;
    }

    public void loginSucceeded(String username) {
        attemptsCache.remove(username);
    }

    private static class AttemptInfo {
        int failures = 0;
        Instant lastAttempt = Instant.now();
    }
}
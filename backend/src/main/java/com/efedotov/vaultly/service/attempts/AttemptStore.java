package com.efedotov.vaultly.service.attempts;

import java.time.Duration;

public interface AttemptStore {

    int incrementAndGet(String key, Duration ttl);

    int get(String key);

    void reset(String key);

    boolean isBlocked(String key, int maxAttempts, Duration blockDuration);

    void evictExpired();
}
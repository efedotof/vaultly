package com.efedotov.vaultly.service.attempts;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;

@Component
public class InMemoryAttemptStore implements AttemptStore {

    private static final Duration ENTRY_TTL = Duration.ofHours(2);
    private static final int MAX_ENTRIES = 100_000;

    private final Map<String, Entry> entries = new ConcurrentHashMap<>();

    @Override
    public int incrementAndGet(String key, Duration ttl) {
        Entry e = entries.compute(key, (k, existing) -> {
            Entry cur = existing == null ? new Entry() : existing;
            cur.failures++;
            cur.lastAttempt = Instant.now();
            return cur;
        });
        return e.failures;
    }

    @Override
    public int get(String key) {
        Entry e = entries.get(key);
        return e == null ? 0 : e.failures;
    }

    @Override
    public void reset(String key) {
        entries.remove(key);
    }

    @Override
    public boolean isBlocked(String key, int maxAttempts, Duration blockDuration) {
        Entry e = entries.get(key);
        if (e == null)
            return false;
        if (e.failures >= maxAttempts) {
            if (Instant.now().isBefore(e.lastAttempt.plus(blockDuration))) {
                return true;
            }
            entries.remove(key);
        }
        return false;
    }

    @Override
    public void evictExpired() {
        Instant threshold = Instant.now().minus(ENTRY_TTL);
        entries.entrySet().removeIf(en -> en.getValue().lastAttempt.isBefore(threshold));
        if (entries.size() > MAX_ENTRIES) {
            entries.entrySet().stream()
                    .sorted(Map.Entry.comparingByValue(
                            (a, b) -> a.lastAttempt.compareTo(b.lastAttempt)))
                    .limit(entries.size() - MAX_ENTRIES)
                    .forEach(en -> entries.remove(en.getKey(), en.getValue()));
        }
    }

    private static class Entry {
        int failures = 0;
        Instant lastAttempt = Instant.now();
    }
}
package com.efedotov.vaultly.service.attempts;

import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class InMemoryAttemptStoreTest {

    private final InMemoryAttemptStore store = new InMemoryAttemptStore();

    @Test
    void incrementAndGet_increasesOnEachCall() {
        Duration ttl = Duration.ofMinutes(5);
        assertThat(store.incrementAndGet("k", ttl)).isEqualTo(1);
        assertThat(store.incrementAndGet("k", ttl)).isEqualTo(2);
        assertThat(store.incrementAndGet("k", ttl)).isEqualTo(3);
    }

    @Test
    void get_returnsZeroForMissingKey() {
        assertThat(store.get("missing")).isZero();
    }

    @Test
    void reset_clearsCounter() {
        store.incrementAndGet("k", Duration.ofMinutes(5));
        store.reset("k");
        assertThat(store.get("k")).isZero();
    }

    @Test
    void isBlocked_falseBelowThreshold() {
        for (int i = 0; i < 4; i++)
            store.incrementAndGet("k", Duration.ofMinutes(5));
        assertThat(store.isBlocked("k", 5, Duration.ofMinutes(15))).isFalse();
    }

    @Test
    void isBlocked_trueAtThreshold() {
        for (int i = 0; i < 5; i++)
            store.incrementAndGet("k", Duration.ofMinutes(5));
        assertThat(store.isBlocked("k", 5, Duration.ofMinutes(15))).isTrue();
    }

    @Test
    void isBlocked_falseForMissingKey() {
        assertThat(store.isBlocked("missing", 5, Duration.ofMinutes(15))).isFalse();
    }

    @Test
    void isBlocked_unblocksAfterDuration() throws InterruptedException {
        store.incrementAndGet("k", Duration.ofMinutes(5));
        assertThat(store.isBlocked("k", 1, Duration.ofMillis(50))).isTrue();
        Thread.sleep(80);
        assertThat(store.isBlocked("k", 1, Duration.ofMillis(50))).isFalse();
    }

    @Test
    void evictExpired_doesNotThrow_andKeepsFreshEntries() {
        store.incrementAndGet("k", Duration.ofMinutes(5));
        store.evictExpired();
        assertThat(store.get("k")).isEqualTo(1);
    }

    @Test
    void evictExpired_removesEntriesOlderThanTtl() throws Exception {
        store.incrementAndGet("stale", Duration.ofMinutes(1));
        store.incrementAndGet("fresh", Duration.ofMinutes(1));

        Map<String, ?> entries = entriesMap(store);
        Object staleEntry = entries.get("stale");
        setLastAttempt(staleEntry, Instant.now().minus(Duration.ofHours(5)));

        store.evictExpired();

        assertThat(store.get("stale")).isZero();
        assertThat(store.get("fresh")).isEqualTo(1);
    }

    @Test
    void evictExpired_whenExceedsMaxEntries_trimsOldest() throws Exception {
        int maxEntries = 100_000;
        for (int i = 0; i <= maxEntries; i++) {
            store.incrementAndGet("k" + i, Duration.ofHours(1));
        }

        assertThat(entriesMap(store)).hasSize(maxEntries + 1);

        store.evictExpired();

        assertThat(entriesMap(store)).hasSize(maxEntries);

        assertThat(store.get("k" + maxEntries)).isEqualTo(1);
    }

    @SuppressWarnings("unchecked")
    private static Map<String, ?> entriesMap(InMemoryAttemptStore store) throws Exception {
        Field f = InMemoryAttemptStore.class.getDeclaredField("entries");
        f.setAccessible(true);
        return (Map<String, ?>) f.get(store);
    }

    private static void setLastAttempt(Object entry, Instant value) throws Exception {
        Field f = entry.getClass().getDeclaredField("lastAttempt");
        f.setAccessible(true);
        f.set(entry, value);
    }
}
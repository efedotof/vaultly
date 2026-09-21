package com.efedotov.vaultly.service;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class RecoveryChallengeServiceTest {

    private final RecoveryChallengeService service = new RecoveryChallengeService();

    @Test
    void issue_thenConsume_withMatchingHash_returnsTrue() {
        String challenge = service.issue("abc");
        assertThat(service.consume(challenge, "abc")).isTrue();
    }

    @Test
    void consume_withMismatchedHash_returnsFalse() {
        String challenge = service.issue("abc");
        assertThat(service.consume(challenge, "different")).isFalse();
    }

    @Test
    void consume_twice_secondTimeFalse() {
        String challenge = service.issue("abc");
        assertThat(service.consume(challenge, "abc")).isTrue();
        assertThat(service.consume(challenge, "abc")).isFalse();
    }

    @Test
    void consume_unknown_returnsFalse() {
        assertThat(service.consume("nope", "abc")).isFalse();
    }

    @Test
    void cleanExpired_keepsFreshEntries() {
        String challenge = service.issue("hash-1");
        service.cleanExpired();

        assertThat(service.consume(challenge, "hash-1")).isTrue();
    }
}
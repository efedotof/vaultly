package com.efedotov.vaultly.service;

import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class PreAuthTokenServiceTest {

    private final PreAuthTokenService service = new PreAuthTokenService();

    @Test
    void issue_thenConsume_returnsUserId() {
        UUID userId = UUID.randomUUID();
        String token = service.issue(userId);
        assertThat(token).isNotBlank();
        assertThat(service.consume(token)).isEqualTo(userId);
    }

    @Test
    void consume_secondTime_returnsNull() {
        UUID userId = UUID.randomUUID();
        String token = service.issue(userId);
        assertThat(service.consume(token)).isEqualTo(userId);
        assertThat(service.consume(token)).isNull();
    }

    @Test
    void consume_unknownToken_returnsNull() {
        assertThat(service.consume("nope")).isNull();
    }

    @Test
    void issue_producesUniqueTokens() {
        Set<String> tokens = new HashSet<>();
        for (int i = 0; i < 100; i++)
            tokens.add(service.issue(UUID.randomUUID()));
        assertThat(tokens).hasSize(100);
    }

    @Test
    void cleanExpired_keepsFreshTokens() {
        UUID userId = UUID.randomUUID();
        String token = service.issue(userId);

        service.cleanExpired();

        assertThat(service.consume(token)).isEqualTo(userId);
    }

    @Test
    void cleanExpired_onEmptyState_isNoop() {
        service.cleanExpired();
    }
}
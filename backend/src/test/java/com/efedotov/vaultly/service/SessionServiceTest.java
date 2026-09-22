package com.efedotov.vaultly.service;

import com.efedotov.vaultly.model.UserSession;
import com.efedotov.vaultly.repository.UserSessionRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SessionServiceTest {

    @Mock
    UserSessionRepository sessionRepository;
    @InjectMocks
    SessionService service;

    @Test
    void createSession_savesHashedToken_returnsPlaintext() {
        UUID userId = UUID.randomUUID();
        when(sessionRepository.save(any(UserSession.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        SessionService.CreatedSession created = service.createSession(userId);

        assertThat(created.plaintextToken()).isNotBlank();
        UserSession saved = created.session();
        assertThat(saved.getUserId()).isEqualTo(userId);
        assertThat(saved.getTokenHash()).isEqualTo(sha256Hex(created.plaintextToken()));
        assertThat(saved.getTokenHash()).hasSize(64);
        assertThat(saved.getExpiresAt()).isAfter(saved.getCreatedAt());
    }

    @Test
    void findValidSession_blank_returnsEmpty() {
        assertThat(service.findValidSession(null)).isEmpty();
        assertThat(service.findValidSession("")).isEmpty();
        assertThat(service.findValidSession("   ")).isEmpty();
        verifyNoInteractions(sessionRepository);
    }

    @Test
    void findValidSession_delegatesWithHashedToken() {
        when(sessionRepository.findValidSession(anyString(), any())).thenReturn(Optional.empty());
        service.findValidSession("tok");
        verify(sessionRepository).findValidSession(eq(sha256Hex("tok")), any());
    }

    @Test
    void deleteSession_nullOrBlank_noOp() {
        service.deleteSession(null);
        service.deleteSession("");
        verifyNoInteractions(sessionRepository);
    }

    @Test
    void deleteSession_hashesToken() {
        service.deleteSession("tok");
        verify(sessionRepository).deleteById(sha256Hex("tok"));
    }

    private static String sha256Hex(String s) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(s.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    @Test
    void cleanExpiredSessions_delegatesToRepository() {
        service.cleanExpiredSessions();
        verify(sessionRepository).deleteExpiredSessions(any(java.time.Instant.class));
    }
}
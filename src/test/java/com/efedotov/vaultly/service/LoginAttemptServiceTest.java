package com.efedotov.vaultly.service;

import com.efedotov.vaultly.service.attempts.InMemoryAttemptStore;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class LoginAttemptServiceTest {

    private final InMemoryAttemptStore store = new InMemoryAttemptStore();
    private final LoginAttemptService service = new LoginAttemptService(store);

    @Test
    void loginFailed_then_isBlocked_afterMaxAttempts() {
        for (int i = 0; i < 5; i++)
            service.loginFailed("alice");
        assertThat(service.isBlocked("alice")).isTrue();
    }

    @Test
    void loginFailed_belowThreshold_notBlocked() {
        for (int i = 0; i < 4; i++)
            service.loginFailed("alice");
        assertThat(service.isBlocked("alice")).isFalse();
    }

    @Test
    void loginSucceeded_resetsCounter() {
        for (int i = 0; i < 4; i++)
            service.loginFailed("alice");
        service.loginSucceeded("alice");
        assertThat(service.isBlocked("alice")).isFalse();
        assertThat(store.get("login:u:alice")).isZero();
    }

    @Test
    void loginFailed_null_isSafe() {
        service.loginFailed(null);
    }

    @Test
    void isBlocked_null_returnsFalse() {
        assertThat(service.isBlocked(null)).isFalse();
    }

    @Test
    void loginSucceeded_null_isSafe() {
        service.loginSucceeded(null);
    }

    @Test
    void ipFailed_then_isIpBlocked_afterMaxAttempts() {
        for (int i = 0; i < 50; i++)
            service.ipFailed("1.2.3.4");
        assertThat(service.isIpBlocked("1.2.3.4")).isTrue();
    }

    @Test
    void ipFailed_belowThreshold_notBlocked() {
        for (int i = 0; i < 49; i++)
            service.ipFailed("1.2.3.4");
        assertThat(service.isIpBlocked("1.2.3.4")).isFalse();
    }

    @Test
    void ipFailed_null_isSafe() {
        service.ipFailed(null);
    }

    @Test
    void ipFailed_blank_isSafe() {
        service.ipFailed("");
        service.ipFailed("   ");
    }

    @Test
    void isIpBlocked_null_returnsFalse() {
        assertThat(service.isIpBlocked(null)).isFalse();
    }

    @Test
    void isIpBlocked_blank_returnsFalse() {
        assertThat(service.isIpBlocked("")).isFalse();
        assertThat(service.isIpBlocked("   ")).isFalse();
    }

    @Test
    void folderPasswordFailed_then_blocked_afterMaxAttempts() {
        for (int i = 0; i < 10; i++)
            service.folderPasswordFailed("f1");
        assertThat(service.isFolderPasswordBlocked("f1")).isTrue();
    }

    @Test
    void folderPasswordSucceeded_resets() {
        for (int i = 0; i < 10; i++)
            service.folderPasswordFailed("f1");
        service.folderPasswordSucceeded("f1");
        assertThat(service.isFolderPasswordBlocked("f1")).isFalse();
    }

    @Test
    void folderPasswordFailed_null_isSafe() {
        service.folderPasswordFailed(null);
    }

    @Test
    void isFolderPasswordBlocked_null_returnsFalse() {
        assertThat(service.isFolderPasswordBlocked(null)).isFalse();
    }

    @Test
    void folderPasswordSucceeded_null_isSafe() {
        service.folderPasswordSucceeded(null);
    }

    @Test
    void folderCheckAttempt_then_blocked_afterMaxAttempts() {
        for (int i = 0; i < 100; i++)
            service.folderCheckAttempt("u1");
        assertThat(service.isFolderCheckBlocked("u1")).isTrue();
    }

    @Test
    void folderCheckAttempt_belowThreshold_notBlocked() {
        for (int i = 0; i < 99; i++)
            service.folderCheckAttempt("u1");
        assertThat(service.isFolderCheckBlocked("u1")).isFalse();
    }

    @Test
    void folderCheckAttempt_null_isSafe() {
        service.folderCheckAttempt(null);
    }

    @Test
    void isFolderCheckBlocked_null_returnsFalse() {
        assertThat(service.isFolderCheckBlocked(null)).isFalse();
    }

    @Test
    void backupCodeFailed_then_blocked_afterMaxAttempts() {
        for (int i = 0; i < 5; i++)
            service.backupCodeFailed("u1");
        assertThat(service.isBackupCodeBlocked("u1")).isTrue();
    }

    @Test
    void backupCodeFailed_belowThreshold_notBlocked() {
        for (int i = 0; i < 4; i++)
            service.backupCodeFailed("u1");
        assertThat(service.isBackupCodeBlocked("u1")).isFalse();
    }

    @Test
    void backupCodeSucceeded_resets() {
        for (int i = 0; i < 5; i++)
            service.backupCodeFailed("u1");
        service.backupCodeSucceeded("u1");
        assertThat(service.isBackupCodeBlocked("u1")).isFalse();
    }

    @Test
    void backupCodeFailed_null_isSafe() {
        service.backupCodeFailed(null);
    }

    @Test
    void isBackupCodeBlocked_null_returnsFalse() {
        assertThat(service.isBackupCodeBlocked(null)).isFalse();
    }

    @Test
    void backupCodeSucceeded_null_isSafe() {
        service.backupCodeSucceeded(null);
    }

    @Test
    void evictExpired_delegatesToStore() {
        InMemoryAttemptStore mockStore = mock(InMemoryAttemptStore.class);
        LoginAttemptService s = new LoginAttemptService(mockStore);

        s.evictExpired();

        verify(mockStore).evictExpired();
    }
}
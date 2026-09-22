package com.efedotov.vaultly.service;

import java.time.Duration;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import com.efedotov.vaultly.service.attempts.AttemptStore;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class LoginAttemptService {

    private static final Duration ENTRY_TTL = Duration.ofHours(2);

    private static final int MAX_ATTEMPTS = 5;
    private static final Duration BLOCK_DURATION = Duration.ofMinutes(15);

    private static final int MAX_IP_ATTEMPTS = 50;
    private static final Duration IP_BLOCK_DURATION = Duration.ofMinutes(15);

    private static final int MAX_FOLDER_PW_ATTEMPTS = 10;
    private static final Duration FOLDER_PW_BLOCK_DURATION = Duration.ofMinutes(15);

    private static final int MAX_FOLDER_CHECK_ATTEMPTS = 100;
    private static final Duration FOLDER_CHECK_BLOCK_DURATION = Duration.ofMinutes(15);

    private static final int MAX_BACKUP_CODE_ATTEMPTS = 5;
    private static final Duration BACKUP_CODE_BLOCK_DURATION = Duration.ofMinutes(15);

    private final AttemptStore store;

    public void loginFailed(String username) {
        if (username == null)
            return;
        int n = store.incrementAndGet("login:u:" + username, ENTRY_TTL);
        if (n == MAX_ATTEMPTS) {
            log.warn("User {} blocked after {} failed attempts", username, MAX_ATTEMPTS);
        }
    }

    public boolean isBlocked(String username) {
        if (username == null)
            return false;
        return store.isBlocked("login:u:" + username, MAX_ATTEMPTS, BLOCK_DURATION);
    }

    public void loginSucceeded(String username) {
        if (username == null)
            return;
        store.reset("login:u:" + username);
    }

    public void ipFailed(String ip) {
        if (ip == null || ip.isBlank())
            return;
        int n = store.incrementAndGet("login:ip:" + ip, ENTRY_TTL);
        if (n == MAX_IP_ATTEMPTS) {
            log.warn("IP {} blocked after {} failed attempts", ip, MAX_IP_ATTEMPTS);
        }
    }

    public boolean isIpBlocked(String ip) {
        if (ip == null || ip.isBlank())
            return false;
        return store.isBlocked("login:ip:" + ip, MAX_IP_ATTEMPTS, IP_BLOCK_DURATION);
    }

    public void folderPasswordFailed(String key) {
        if (key == null)
            return;
        store.incrementAndGet("folder:pw:" + key, ENTRY_TTL);
    }

    public boolean isFolderPasswordBlocked(String key) {
        if (key == null)
            return false;
        return store.isBlocked("folder:pw:" + key, MAX_FOLDER_PW_ATTEMPTS, FOLDER_PW_BLOCK_DURATION);
    }

    public void folderPasswordSucceeded(String key) {
        if (key == null)
            return;
        store.reset("folder:pw:" + key);
    }

    public void folderCheckAttempt(String key) {
        if (key == null)
            return;
        store.incrementAndGet("folder:check:" + key, ENTRY_TTL);
    }

    public boolean isFolderCheckBlocked(String key) {
        if (key == null)
            return false;
        return store.isBlocked("folder:check:" + key,
                MAX_FOLDER_CHECK_ATTEMPTS, FOLDER_CHECK_BLOCK_DURATION);
    }

    public void backupCodeFailed(String userKey) {
        if (userKey == null)
            return;
        store.incrementAndGet("backup:" + userKey, ENTRY_TTL);
    }

    public boolean isBackupCodeBlocked(String userKey) {
        if (userKey == null)
            return false;
        return store.isBlocked("backup:" + userKey,
                MAX_BACKUP_CODE_ATTEMPTS, BACKUP_CODE_BLOCK_DURATION);
    }

    public void backupCodeSucceeded(String userKey) {
        if (userKey == null)
            return;
        store.reset("backup:" + userKey);
    }

    @Scheduled(fixedRate = 600_000)
    public void evictExpired() {
        store.evictExpired();
    }
}
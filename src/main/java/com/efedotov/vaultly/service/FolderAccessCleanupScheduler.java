package com.efedotov.vaultly.service;

import java.time.LocalDateTime;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.efedotov.vaultly.repository.FolderAccessRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class FolderAccessCleanupScheduler {

    private final FolderAccessRepository folderAccessRepository;

    @Scheduled(fixedRate = 3_600_000)
    @Transactional
    public void deactivateExpired() {
        folderAccessRepository.deactivateExpiredAccesses(LocalDateTime.now());
        log.debug("Deactivated expired folder accesses");
    }
}
package com.efedotov.vaultly.service;

import com.efedotov.vaultly.repository.FolderAccessRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class FolderAccessCleanupSchedulerTest {

    @Mock
    FolderAccessRepository folderAccessRepository;
    @InjectMocks
    FolderAccessCleanupScheduler scheduler;

    @Test
    void deactivateExpired_callsRepositoryWithNow() {
        LocalDateTime before = LocalDateTime.now().minusSeconds(2);
        LocalDateTime after = LocalDateTime.now().plusSeconds(2);

        scheduler.deactivateExpired();

        ArgumentCaptor<LocalDateTime> captor = ArgumentCaptor.forClass(LocalDateTime.class);
        verify(folderAccessRepository).deactivateExpiredAccesses(captor.capture());

        assertThat(captor.getValue()).isAfter(before).isBefore(after);
    }
}
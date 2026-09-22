package com.efedotov.vaultly.service;

import com.efedotov.vaultly.model.FileContent;
import com.efedotov.vaultly.repository.FileContentRepository;
import com.efedotov.vaultly.repository.FileRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class S3CleanupServiceTest {

        private static final int BATCH_SIZE = 100;

        @Mock
        FileContentRepository fileContentRepository;
        @Mock
        FileRepository fileRepository;
        @Mock
        S3Service s3Service;

        @InjectMocks
        S3CleanupService service;

        @Test
        void cleanup_emptyRepository_doesNothing() {
                when(fileContentRepository.findOrphanedContentOlderThan(any(), any()))
                                .thenReturn(List.of());

                service.cleanupOrphanedFileContents();

                verify(fileContentRepository, never()).deleteById(any());
                verify(s3Service, never()).deleteFile(any());
        }

        @Test
        void cleanup_singleBatch_processesAll() {
                FileContent fc1 = fileContent("https://cdn/a.shps");
                FileContent fc2 = fileContent("https://cdn/b.shps");
                when(fileContentRepository.findOrphanedContentOlderThan(any(), any()))
                                .thenReturn(List.of(fc1, fc2));
                when(fileRepository.countActiveLinksByFileContent(any())).thenReturn(0L);

                service.cleanupOrphanedFileContents();

                verify(s3Service).deleteFile("https://cdn/a.shps");
                verify(s3Service).deleteFile("https://cdn/b.shps");
                verify(fileContentRepository).deleteById(fc1.getId());
                verify(fileContentRepository).deleteById(fc2.getId());
        }

        @Test
        void cleanup_fullBatch_thenEmptyBatch_loopsTwice() {

                List<FileContent> fullBatch = new ArrayList<>();
                for (int i = 0; i < BATCH_SIZE; i++) {
                        fullBatch.add(fileContent("https://cdn/" + i + ".shps"));
                }

                when(fileContentRepository.findOrphanedContentOlderThan(any(), any()))
                                .thenReturn(fullBatch)
                                .thenReturn(List.of());

                when(fileRepository.countActiveLinksByFileContent(any())).thenReturn(0L);

                service.cleanupOrphanedFileContents();

                verify(fileContentRepository, times(BATCH_SIZE)).deleteById(any());
                verify(fileContentRepository, times(2)).findOrphanedContentOlderThan(any(), any());
        }

        @Test
        void cleanup_skipsContentWithActiveLinks() {
                FileContent used = fileContent("https://cdn/used.shps");
                when(fileContentRepository.findOrphanedContentOlderThan(any(), any()))
                                .thenReturn(List.of(used));
                when(fileRepository.countActiveLinksByFileContent(used)).thenReturn(3L);

                service.cleanupOrphanedFileContents();

                verify(s3Service, never()).deleteFile(any());
                verify(fileContentRepository, never()).deleteById(any());
        }

        @Test
        void cleanup_s3Error_logsAndContinues() {
                FileContent failing = fileContent("https://cdn/fail.shps");
                FileContent ok = fileContent("https://cdn/ok.shps");
                when(fileContentRepository.findOrphanedContentOlderThan(any(), any()))
                                .thenReturn(List.of(failing, ok));
                when(fileRepository.countActiveLinksByFileContent(any())).thenReturn(0L);

                doThrow(new RuntimeException("S3 down")).when(s3Service).deleteFile("https://cdn/fail.shps");

                service.cleanupOrphanedFileContents();

                verify(fileContentRepository, never()).deleteById(failing.getId());
                verify(fileContentRepository).deleteById(ok.getId());
        }

        @Test
        void cleanup_dbError_logsAndContinues() {
                FileContent failing = fileContent("https://cdn/fail.shps");
                FileContent ok = fileContent("https://cdn/ok.shps");
                when(fileContentRepository.findOrphanedContentOlderThan(any(), any()))
                                .thenReturn(List.of(failing, ok));
                when(fileRepository.countActiveLinksByFileContent(any())).thenReturn(0L);

                doThrow(new RuntimeException("DB constraint"))
                                .when(fileContentRepository).deleteById(failing.getId());

                service.cleanupOrphanedFileContents();

                verify(fileContentRepository).deleteById(ok.getId());
        }

        @Test
        void cleanup_usesGraceThreshold_aboutOneHourAgo() {
                LocalDateTime before = LocalDateTime.now().minusHours(1).minusSeconds(2);
                LocalDateTime after = LocalDateTime.now().minusHours(1).plusSeconds(2);

                when(fileContentRepository.findOrphanedContentOlderThan(any(), any()))
                                .thenReturn(List.of());

                service.cleanupOrphanedFileContents();

                org.mockito.ArgumentCaptor<LocalDateTime> captor = org.mockito.ArgumentCaptor
                                .forClass(LocalDateTime.class);
                verify(fileContentRepository).findOrphanedContentOlderThan(captor.capture(), any());

                LocalDateTime threshold = captor.getValue();
                org.assertj.core.api.Assertions.assertThat(threshold)
                                .isAfter(before).isBefore(after);
        }

        @Test
        void cleanup_usesPageRequestZeroAndBatchSize() {
                when(fileContentRepository.findOrphanedContentOlderThan(any(), any()))
                                .thenReturn(List.of());

                service.cleanupOrphanedFileContents();

                org.mockito.ArgumentCaptor<org.springframework.data.domain.Pageable> captor = org.mockito.ArgumentCaptor
                                .forClass(org.springframework.data.domain.Pageable.class);
                verify(fileContentRepository).findOrphanedContentOlderThan(any(), captor.capture());

                org.assertj.core.api.Assertions.assertThat(captor.getValue().getPageNumber()).isZero();
                org.assertj.core.api.Assertions.assertThat(captor.getValue().getPageSize())
                                .isEqualTo(BATCH_SIZE);
        }

        private FileContent fileContent(String s3Url) {
                return FileContent.builder()
                                .id(UUID.randomUUID())
                                .s3Key(s3Url.substring(s3Url.lastIndexOf('/') + 1))
                                .s3Url(s3Url)
                                .size(100L)
                                .isPublic(false)
                                .build();
        }
}
package com.efedotov.vaultly.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import com.efedotov.vaultly.model.FileContent;
import com.efedotov.vaultly.repository.FileContentRepository;
import com.efedotov.vaultly.repository.FileRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class S3CleanupService {

    private static final int BATCH_SIZE = 100;
    private static final int GRACE_PERIOD_HOURS = 1;

    private final FileContentRepository fileContentRepository;
    private final FileRepository fileRepository;
    private final S3Service s3Service;

    @Scheduled(cron = "0 0 */6 * * *")
    public void cleanupOrphanedFileContents() {
        LocalDateTime threshold = LocalDateTime.now().minusHours(GRACE_PERIOD_HOURS);
        int processed = 0;

        while (true) {
            List<FileContent> batch = fileContentRepository
                    .findOrphanedContentOlderThan(threshold, PageRequest.of(0, BATCH_SIZE));

            if (batch.isEmpty()) {
                break;
            }

            for (FileContent fc : batch) {
                try {

                    if (fileRepository.countActiveLinksByFileContent(fc) > 0) {
                        continue;
                    }

                    s3Service.deleteFile(fc.getS3Url());

                    fileContentRepository.deleteById(fc.getId());
                    processed++;

                } catch (Exception e) {
                    log.warn("S3 cleanup failed for FileContent {} (key={}): {}",
                            fc.getId(), fc.getS3Key(), e.getMessage());
                }
            }
            if (batch.size() < BATCH_SIZE) {
                break;
            }
        }

        if (processed > 0) {
            log.info("S3 cleanup: removed {} orphaned file contents", processed);
        } else {
            log.debug("S3 cleanup: nothing to remove");
        }
    }
}
package com.efedotov.vaultly.config;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import software.amazon.awssdk.awscore.exception.AwsServiceException;
import software.amazon.awssdk.core.exception.SdkClientException;
import software.amazon.awssdk.services.s3.S3Client;

@Component
@Slf4j
@RequiredArgsConstructor
public class S3ConfigValidator implements ApplicationRunner {

    private final S3Client s3Client;

    @Override
    public void run(ApplicationArguments args) {
        try {
            s3Client.listBuckets();
            log.info("S3 connection test successful");
        } catch (AwsServiceException | SdkClientException e) {
            log.error("S3 connection test failed: {}", e.getMessage(), e);
        }
    }
}
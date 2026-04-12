package com.efedotov.vaultly.config;

import java.net.URI;
import java.time.Duration;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.client.config.ClientOverrideConfiguration;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3AsyncClient;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

@Configuration
public class S3Config {

        @Value("${cloud.aws.s3.endpoint}")
        private String endpoint;

        @Value("${cloud.aws.s3.region}")
        private String region;

        @Value("${cloud.aws.s3.access-key:}")
        private String accessKey;

        @Value("${cloud.aws.s3.secret-key:}")
        private String secretKey;

        private StaticCredentialsProvider credentialsProvider() {
                return StaticCredentialsProvider.create(AwsBasicCredentials.create(accessKey, secretKey));
        }

        private S3Configuration s3Configuration() {
                return S3Configuration.builder()
                                .pathStyleAccessEnabled(true)
                                .chunkedEncodingEnabled(false)
                                .build();
        }

        private ClientOverrideConfiguration overrideConfiguration() {
                return ClientOverrideConfiguration.builder()
                                .apiCallTimeout(Duration.ofMinutes(2))
                                .apiCallAttemptTimeout(Duration.ofSeconds(60))
                                .putHeader("Expect", "")
                                .build();
        }

        @Bean
        public S3Client s3Client() {
                return S3Client.builder()
                                .endpointOverride(URI.create(endpoint))
                                .region(Region.of(region))
                                .credentialsProvider(credentialsProvider())
                                .serviceConfiguration(s3Configuration())
                                .overrideConfiguration(overrideConfiguration())
                                .build();
        }

        @Bean
        public S3AsyncClient s3AsyncClient() {
                return S3AsyncClient.builder()
                                .endpointOverride(URI.create(endpoint))
                                .region(Region.of(region))
                                .credentialsProvider(credentialsProvider())
                                .serviceConfiguration(s3Configuration())
                                .overrideConfiguration(overrideConfiguration())
                                .multipartEnabled(true)
                                .multipartConfiguration(conf -> conf
                                                .apiCallBufferSizeInBytes(16L * 1024 * 1024)
                                                .minimumPartSizeInBytes(5L * 1024 * 1024))
                                .build();
        }

        @Bean
        public S3Presigner s3Presigner() {
                return S3Presigner.builder()
                                .endpointOverride(URI.create(endpoint))
                                .region(Region.of(region))
                                .credentialsProvider(credentialsProvider())
                                .serviceConfiguration(S3Configuration.builder().pathStyleAccessEnabled(true).build())
                                .build();
        }
}
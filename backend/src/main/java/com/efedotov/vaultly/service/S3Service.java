package com.efedotov.vaultly.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.core.sync.ResponseTransformer;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;

import java.io.*;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class S3Service {

    private static final String ALLOWED_EXTENSION = ".shps";

    private final S3Client s3Client;
    private final S3Presigner s3Presigner;

    @Value("${cloud.aws.s3.bucket}")
    private String bucketName;

    @Value("${S3_PUBLIC_URL:}")
    private String s3PublicUrl;

    @Value("${cloud.aws.s3.endpoint:}")
    private String s3Endpoint;

    
    String uploadFileWithMultipart(Path filePath, String originalFilename, String contentType) {
        validateShpsFile(originalFilename, contentType);
        String key = UUID.randomUUID() + ALLOWED_EXTENSION;

        try {
            long fileSize = Files.size(filePath);
            log.info("Uploading file to S3: bucket={}, key={}, file={}, size={} bytes",
                    bucketName, key, filePath, fileSize);

            String safeFilename = URLEncoder.encode(originalFilename, StandardCharsets.UTF_8);

            Map<String, String> metadata = Map.of(
                    "Original-Filename", safeFilename,
                    "Content-Type", contentType);

            PutObjectRequest request = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .contentType(contentType)
                    .metadata(metadata)
                    .contentLength(fileSize)
                    .build();

            s3Client.putObject(request, RequestBody.fromFile(filePath));

            log.info("Upload completed: bucket={}, key={}", bucketName, key);
            return key;

        } catch (IOException e) {
            throw new RuntimeException("Failed to upload file: " + filePath, e);
        }
    }

    private void validateShpsFile(String filename, String contentType) {
        if (filename == null || !filename.toLowerCase().endsWith(ALLOWED_EXTENSION)) {
            throw new IllegalArgumentException("Only .shps files are allowed");
        }
        if (contentType != null && !contentType.equals("application/x-shirmps")) {
            log.warn("Unexpected MIME type for SHPS file: {}", contentType);
        }
    }

    public String generatePresignedUrl(String objectKey, Duration duration) {
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(objectKey)
                .build();
        GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(duration)
                .getObjectRequest(getObjectRequest)
                .build();
        PresignedGetObjectRequest presignedRequest = s3Presigner.presignGetObject(presignRequest);
        return presignedRequest.url().toString();
    }

    public String getPublicUrl(String key) {
        if (key == null)
            return null;
        if (s3PublicUrl != null && !s3PublicUrl.isEmpty()) {
            return s3PublicUrl + "/" + key;
        } else {
            return s3Endpoint + "/" + bucketName + "/" + key;
        }
    }

    public String getObjectKeyFromUrl(String fileUrl) {
        if (fileUrl == null || fileUrl.isBlank()) {
            return null;
        }

        String key = fileUrl.trim();

        if (!key.startsWith("http://") && !key.startsWith("https://")) {
            return key;
        }

        if (s3PublicUrl != null && !s3PublicUrl.isEmpty() && key.startsWith(s3PublicUrl)) {
            String tail = key.substring(s3PublicUrl.length());
            return tail.startsWith("/") ? tail.substring(1) : tail;
        }

        try {
            java.net.URI uri = java.net.URI.create(key);
            String path = uri.getPath();
            if (path == null || path.isEmpty())
                return null;
            int lastSlash = path.lastIndexOf('/');
            return lastSlash >= 0 ? path.substring(lastSlash + 1) : path;
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    public byte[] downloadFile(String objectKey) {
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(objectKey)
                .build();
        try (var response = s3Client.getObject(getObjectRequest)) {
            return response.readAllBytes();
        } catch (IOException e) {
            throw new RuntimeException("Failed to read file data", e);
        }
    }

    public void streamFileTo(String objectKey, OutputStream outputStream) {
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(objectKey)
                .build();
        try (var response = s3Client.getObject(getObjectRequest)) {
            response.transferTo(outputStream);
            outputStream.flush();
        } catch (IOException e) {
            throw new RuntimeException("Failed to stream file", e);
        }
    }

    public InputStream getObjectStream(String objectKey) {
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(objectKey)
                .build();
        return s3Client.getObject(getObjectRequest, ResponseTransformer.toInputStream());
    }

    public void deleteFile(String fileUrl) {
        String objectKey = getObjectKeyFromUrl(fileUrl);
        if (objectKey == null || objectKey.isBlank()) {
            log.warn("Cannot delete S3 object: null/blank key from URL '{}'", fileUrl);
            return;
        }
        log.info("Deleting file from S3: {}", objectKey);
        DeleteObjectRequest deleteObjectRequest = DeleteObjectRequest.builder()
                .bucket(bucketName)
                .key(objectKey)
                .build();
        s3Client.deleteObject(deleteObjectRequest);
        log.info("File successfully deleted from S3: {}", objectKey);
    }
}
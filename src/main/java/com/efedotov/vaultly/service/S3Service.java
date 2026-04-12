package com.efedotov.vaultly.service;

import io.github.cdimascio.dotenv.Dotenv;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
    private final Dotenv dotenv;

    /**
     * Загрузка byte[]
     */
    public String uploadShpsFileBytes(byte[] fileBytes, String originalFilename, String contentType) {
        validateShpsFile(originalFilename, contentType);
        String bucketName = dotenv.get("S3_BUCKET");
        String key = UUID.randomUUID() + ALLOWED_EXTENSION;

        log.info("Uploading SHPS file (byte[]) to S3: bucket={}, key={}, size={} bytes",
                bucketName, key, fileBytes.length);

        Map<String, String> metadata = Map.of(
                "Original-Filename", originalFilename,
                "Content-Type", contentType);

        PutObjectRequest request = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .contentType(contentType)
                .metadata(metadata)
                .build();

        s3Client.putObject(request, RequestBody.fromBytes(fileBytes));
        log.info("Successfully uploaded SHPS file to S3: bucket={}, key={}", bucketName, key);
        return dotenv.get("S3_PUBLIC_URL") + "/" + key;
    }

    /**
     * Загрузка локального файла с автоматической многокомпонентной отправкой
     */
    public String uploadFileWithMultipart(Path filePath, String originalFilename, String contentType) {
        validateShpsFile(originalFilename, contentType);
        String bucketName = dotenv.get("S3_BUCKET");
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
            return dotenv.get("S3_PUBLIC_URL") + "/" + key;

        } catch (IOException e) {
            throw new RuntimeException("Failed to upload file: " + filePath, e);
        }
    }

    /**
     * Загрузка данных из InputStream с предварительным сохранением во временный
     * файл.
     */
    public String uploadStreamWithMultipart(InputStream inputStream, long contentLength,
            String originalFilename, String contentType) throws IOException {
        Path tempFile = Files.createTempFile("upload-", ".tmp");
        try {
            Files.copy(inputStream, tempFile, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            return uploadFileWithMultipart(tempFile, originalFilename, contentType);
        } finally {
            Files.deleteIfExists(tempFile);
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
        String bucketName = dotenv.get("S3_BUCKET");
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

    public String getObjectKeyFromUrl(String fileUrl) {
        String bucketName = dotenv.get("S3_BUCKET");
        String prefix = "https://s3.ru1.storage.beget.cloud/" + bucketName + "/";
        if (fileUrl.startsWith(prefix)) {
            return fileUrl.substring(prefix.length());
        }
        return fileUrl;
    }

    public byte[] downloadFile(String objectKey) {
        String bucketName = dotenv.get("S3_BUCKET");
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
        String bucketName = dotenv.get("S3_BUCKET");
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
        String bucketName = dotenv.get("S3_BUCKET");
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(objectKey)
                .build();
        return s3Client.getObject(getObjectRequest, ResponseTransformer.toInputStream());
    }

    public void deleteFile(String fileUrl) {
        String bucketName = dotenv.get("S3_BUCKET");
        String objectKey = getObjectKeyFromUrl(fileUrl);
        log.info("Deleting file from S3: {}", objectKey);
        DeleteObjectRequest deleteObjectRequest = DeleteObjectRequest.builder()
                .bucket(bucketName)
                .key(objectKey)
                .build();
        s3Client.deleteObject(deleteObjectRequest);
        log.info("File successfully deleted from S3: {}", objectKey);
    }
}
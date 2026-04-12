package com.efedotov.vaultly.dto.file;

import java.time.LocalDateTime;
import java.util.UUID;
import lombok.Data;

@Data
public class FileDto {
    private UUID id;
    private String name;
    private String originalName;
    private Long size;
    private String mimeType;
    private String s3Url;
    private Boolean isEncrypted;
    private Boolean isPublic;
    private LocalDateTime createdAt;
    private UUID folderId;
    private String folderName;
}
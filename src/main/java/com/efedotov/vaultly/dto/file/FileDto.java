package com.efedotov.vaultly.dto.file;

import lombok.Data;
import java.time.LocalDateTime;
import java.util.UUID;

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
    private Boolean isNote;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private UUID folderId;
    private String folderName;
}
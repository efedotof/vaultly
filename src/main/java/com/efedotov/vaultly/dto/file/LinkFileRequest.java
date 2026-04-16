package com.efedotov.vaultly.dto.file;

import lombok.Data;
import java.util.UUID;

@Data
public class LinkFileRequest {
    private UUID fileContentId;
    private String fileName;
    private UUID folderId;
    private Boolean isPublic;
}
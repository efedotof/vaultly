package com.efedotov.vaultly.dto.file;

import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.UUID;

@Data
public class LinkFileRequest {
    private UUID fileContentId;

    @Size(max = 500)
    private String fileName;

    private UUID folderId;
    private Boolean isPublic;
}
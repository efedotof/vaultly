package com.efedotov.vaultly.dto.file;

import org.springframework.web.multipart.MultipartFile;

import lombok.Data;

@Data
public class FileUploadRequest {
    private MultipartFile file;
    private Long folderId;
    private Boolean encrypt = false;
    private String encryptionPassword;
}

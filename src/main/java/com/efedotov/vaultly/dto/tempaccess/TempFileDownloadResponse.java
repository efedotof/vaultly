package com.efedotov.vaultly.dto.tempaccess;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class TempFileDownloadResponse {
    private byte[] data;
    private String fileName;
    private String mimeType;
}
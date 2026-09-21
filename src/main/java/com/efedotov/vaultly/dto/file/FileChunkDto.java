package com.efedotov.vaultly.dto.file;

import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class FileChunkDto {
    private String fileName;
    private String contentType;
    private byte[] data;
    private boolean lastChunk;
    private UUID folderId;
}
package com.efedotov.vaultly.dto.folder;

import java.util.UUID;

import lombok.Data;

@Data
public class AddFileToFolderRequest {
    private UUID fileId;
}

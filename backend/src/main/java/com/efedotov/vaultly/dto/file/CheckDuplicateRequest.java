package com.efedotov.vaultly.dto.file;

import lombok.Data;

@Data
public class CheckDuplicateRequest {
    private String hash;
    private Boolean isPublic;
}
package com.efedotov.vaultly.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Data;
import java.util.List;

@Data
@AllArgsConstructor
public class TotpVerifyResponse {
    private boolean success;
    private List<String> backupCodes;
}
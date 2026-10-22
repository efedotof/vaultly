package com.efedotov.vaultly.controller;

import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.efedotov.vaultly.dto.pair.PairBlobResponse;
import com.efedotov.vaultly.dto.pair.PairBlobUploadRequest;
import com.efedotov.vaultly.dto.pair.PairInfoResponse;
import com.efedotov.vaultly.dto.pair.PairInitRequest;
import com.efedotov.vaultly.dto.pair.PairInitResponse;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.DevicePairingService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/devices/pair")
@RequiredArgsConstructor
@Slf4j
public class DevicePairingController {

    private final DevicePairingService pairingService;

    @PostMapping("/init")
    public PairInitResponse init(@Valid @RequestBody PairInitRequest request,
            @AuthenticationPrincipal CustomUserDetails user) {
        return pairingService.initPairing(user.getUserId(), request);
    }

    @GetMapping("/{pairingId}")
    public PairInfoResponse getInfo(@PathVariable UUID pairingId,
            @AuthenticationPrincipal CustomUserDetails user) {
        return pairingService.getInfo(user.getUserId(), pairingId);
    }


    @PutMapping("/{pairingId}/blob")
    public ResponseEntity<Void> uploadBlob(@PathVariable UUID pairingId,
            @Valid @RequestBody PairBlobUploadRequest request,
            @AuthenticationPrincipal CustomUserDetails user) {
        pairingService.uploadBlob(user.getUserId(), pairingId, request);
        return ResponseEntity.ok().build();
    }


    @GetMapping("/{pairingId}/blob")
    public PairBlobResponse fetchBlob(@PathVariable UUID pairingId,
            @AuthenticationPrincipal CustomUserDetails user) {
        return pairingService.fetchBlob(user.getUserId(), pairingId);
    }
}
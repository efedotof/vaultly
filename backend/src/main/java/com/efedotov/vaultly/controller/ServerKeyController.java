package com.efedotov.vaultly.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.efedotov.vaultly.service.ServerKeyService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/server-key")
@RequiredArgsConstructor
@Slf4j
public class ServerKeyController {

    private final ServerKeyService serverKeyService;

    @GetMapping("/public")
    public ResponseEntity<String> getServerPublicKey() {
        try {
            String publicKeyPem = serverKeyService.getPublicKeyPem();
            return ResponseEntity.ok(publicKeyPem);
        } catch (Exception e) {
            log.error("Failed to retrieve server public key", e);
            return ResponseEntity.internalServerError().body("Server public key not available");
        }
    }
}
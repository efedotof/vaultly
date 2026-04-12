package com.efedotov.vaultly.controller;

import com.efedotov.vaultly.dto.auth.AuthResponse;
import com.efedotov.vaultly.dto.auth.LoginRequest;
import com.efedotov.vaultly.dto.auth.LogoutRequest;
import com.efedotov.vaultly.dto.auth.RegisterRequest;
import com.efedotov.vaultly.dto.auth.TokenValidationRequest;
import com.efedotov.vaultly.service.AuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public AuthResponse register(@RequestBody RegisterRequest request) {
        log.info("REST register request for username: {}", request.getUsername());
        try {
            return authService.registration(request);
        } catch (Exception e) {
            log.error("Registration error", e);
            throw new RuntimeException("Registration failed: " + e.getMessage());
        }
    }

    @PostMapping("/login")
    public AuthResponse login(@RequestBody LoginRequest request) {
        log.info("REST login request for username: {}", request.getUsername());
        try {
            return authService.login(request);
        } catch (Exception e) {
            log.error("Login error", e);
            throw new RuntimeException("Login failed: " + e.getMessage());
        }
    }

    @PostMapping("/validate")
    public AuthResponse validateToken(@RequestBody TokenValidationRequest request) {
        log.debug("REST token validation request");
        try {
            return authService.validateToken(request.getToken());
        } catch (Exception e) {
            log.error("Token validation error", e);
            throw new RuntimeException("Token validation failed: " + e.getMessage());
        }
    }

    @PostMapping("/logout")
    public void logout(@RequestBody LogoutRequest request) {
        log.info("REST logout request");
        try {
            authService.logout(request.getToken());
        } catch (Exception e) {
            log.error("Logout error", e);
            throw new RuntimeException("Logout failed: " + e.getMessage());
        }
    }

    @GetMapping("/health")
    public String healthCheck() {
        return "Auth service is healthy";
    }
}
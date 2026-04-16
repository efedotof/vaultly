package com.efedotov.vaultly.controller;

import com.efedotov.vaultly.dto.auth.*;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public AuthResponse register(@RequestBody RegisterRequest request) {
        log.info("REST register request for username: {}", request.getUsername());
        return authService.registration(request);
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        log.info("REST login request for username: {}", request.getUsername());
        try {
            AuthResponse response = authService.login(request);
            return ResponseEntity.ok(response);
        } catch (AuthService.TotpRequiredException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "totp_required", "message", e.getMessage()));
        } catch (Exception e) {
            log.error("Login error", e);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "login_failed", "message", e.getMessage()));
        }
    }

    @PostMapping("/totp/setup")
    public ResponseEntity<TotpSetupResponse> setupTotp(@AuthenticationPrincipal CustomUserDetails user) {
        log.info("TOTP setup requested for user: {}", user.getUsername());
        TotpSetupResponse response = authService.setupTotp(user.getUserId());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/totp/verify")
    public ResponseEntity<TotpVerifyResponse> verifyTotp(
            @AuthenticationPrincipal CustomUserDetails user,
            @RequestBody TotpVerifyRequest request) {
        log.info("TOTP verification requested for user: {}", user.getUsername());
        TotpVerifyResponse response = authService.verifyAndEnableTotp(user.getUserId(), request.getCode());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/totp/disable")
    public ResponseEntity<Void> disableTotp(
            @AuthenticationPrincipal CustomUserDetails user,
            @RequestBody TotpDisableRequest request) {
        log.info("TOTP disable requested for user: {}", user.getUsername());
        authService.disableTotp(user.getUserId(), request.getCode());
        return ResponseEntity.ok().build();
    }

    @PostMapping("/validate")
    public AuthResponse validateToken(@RequestBody TokenValidationRequest request) {
        log.debug("REST token validation request");
        return authService.validateToken(request.getToken());
    }

    @PostMapping("/logout")
    public void logout(@RequestBody LogoutRequest request) {
        log.info("REST logout request");
        authService.logout(request.getToken());
    }

    @GetMapping("/health")
    public String healthCheck() {
        return "Auth service is healthy";
    }

    @PostMapping("/recover")
    public ResponseEntity<AuthResponse> recoverAccess(@Valid @RequestBody RecoverRequest request) {
        log.info("REST recover access request with publicKey");
        AuthResponse response = authService.recoverAccess(request);
        return ResponseEntity.ok(response);
    }
}
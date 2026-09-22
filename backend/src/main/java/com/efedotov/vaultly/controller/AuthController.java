package com.efedotov.vaultly.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.efedotov.vaultly.dto.auth.AuthResponse;
import com.efedotov.vaultly.dto.auth.LoginRequest;
import com.efedotov.vaultly.dto.auth.LoginWithTotpRequest;
import com.efedotov.vaultly.dto.auth.LogoutRequest;
import com.efedotov.vaultly.dto.auth.RecoverRequest;
import com.efedotov.vaultly.dto.auth.RecoveryChallengeRequest;
import com.efedotov.vaultly.dto.auth.RecoveryChallengeResponse;
import com.efedotov.vaultly.dto.auth.RegisterRequest;
import com.efedotov.vaultly.dto.auth.TokenValidationRequest;
import com.efedotov.vaultly.dto.auth.TotpDisableRequest;
import com.efedotov.vaultly.dto.auth.TotpSetupResponse;
import com.efedotov.vaultly.dto.auth.TotpVerifyRequest;
import com.efedotov.vaultly.dto.auth.TotpVerifyResponse;
import com.efedotov.vaultly.exception.BadRequestException;
import com.efedotov.vaultly.exception.TotpRequiredException;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.AuthService;
import com.efedotov.vaultly.service.LoginAttemptService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final LoginAttemptService loginAttemptService;

    @Value("${app.security.trust-forwarded-headers}")
    private boolean trustForwardedHeaders;

    @PostMapping("/register")
    public AuthResponse register(@Valid @RequestBody RegisterRequest request,
            HttpServletRequest httpRequest) {

        log.debug("REST register request");

        String ip = extractClientIp(httpRequest);
        if (loginAttemptService.isIpBlocked(ip)) {
            throw new BadRequestException("Too many attempts");
        }

        try {
            return authService.registration(request);
        } catch (Exception e) {
            loginAttemptService.ipFailed(ip);
            throw e;
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request,
            HttpServletRequest httpRequest) {
        log.debug("REST login request");

        String ip = extractClientIp(httpRequest);

        if (loginAttemptService.isIpBlocked(ip)) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .body(Map.of("error", "rate_limited", "message", "Too many attempts"));
        }

        try {
            AuthResponse response = authService.login(request);
            return ResponseEntity.ok(response);
        } catch (TotpRequiredException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of(
                            "error", "totp_required",
                            "preAuthToken", e.getPreAuthToken()));
        } catch (Exception e) {
            loginAttemptService.ipFailed(ip);
            log.warn("Login failed");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "login_failed", "message", "Invalid credentials"));
        }
    }

    private String extractClientIp(HttpServletRequest request) {
        if (trustForwardedHeaders) {
            String xff = request.getHeader("X-Forwarded-For");
            if (xff != null && !xff.isBlank()) {
                String[] parts = xff.split(",");
                String last = parts[parts.length - 1].trim();
                if (!last.isEmpty()) {
                    return last;
                }
            }
        }
        return request.getRemoteAddr();
    }

    @PostMapping("/login/totp")
    public ResponseEntity<?> loginWithTotp(@Valid @RequestBody LoginWithTotpRequest request,
            HttpServletRequest httpRequest) {
        log.debug("REST login with TOTP");
        String ip = extractClientIp(httpRequest);
        try {
            AuthResponse response = authService.loginWithTotp(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            loginAttemptService.ipFailed(ip);
            log.warn("Login with TOTP failed");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "login_failed", "message", "Invalid credentials"));
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
            @Valid @RequestBody TotpVerifyRequest request) {
        log.info("TOTP verification requested for user: {}", user.getUsername());
        TotpVerifyResponse response = authService.verifyAndEnableTotp(user.getUserId(), request.getCode());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/totp/disable")
    public ResponseEntity<Void> disableTotp(
            @AuthenticationPrincipal CustomUserDetails user,
            @Valid @RequestBody TotpDisableRequest request) {
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
        log.debug("REST logout request");
        authService.logout(request.getToken());
    }

    @GetMapping("/health")
    public String healthCheck() {
        return "Auth service is healthy";
    }

    @PostMapping("/recover")
    public ResponseEntity<AuthResponse> recoverAccess(@Valid @RequestBody RecoverRequest request) {
        log.info("REST recover access request (signed)");
        AuthResponse response = authService.recoverAccess(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/recover/challenge")
    public ResponseEntity<RecoveryChallengeResponse> recoverChallenge(
            @Valid @RequestBody RecoveryChallengeRequest request) {
        return ResponseEntity.ok(authService.createRecoveryChallenge(request));
    }
}
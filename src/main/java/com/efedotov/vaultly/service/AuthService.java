package com.efedotov.vaultly.service;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.efedotov.vaultly.dto.auth.AuthResponse;
import com.efedotov.vaultly.dto.auth.LoginRequest;
import com.efedotov.vaultly.dto.auth.RegisterRequest;
import com.efedotov.vaultly.dto.auth.TotpSetupResponse;
import com.efedotov.vaultly.dto.auth.TotpVerifyResponse;
import com.efedotov.vaultly.model.Role;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.model.UserSession;
import com.efedotov.vaultly.repository.RoleRepository;
import com.efedotov.vaultly.repository.UserRepository;

import dev.samstevens.totp.exceptions.QrGenerationException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final SessionService sessionService;
    private final PasswordEncoder passwordEncoder;
    private final RoleRepository roleRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final TotpService totpService;
    private final LoginAttemptService loginAttemptService;

    @Transactional
    public AuthResponse login(LoginRequest request) {
        log.info("Login attempt for username: {}", request.getUsername());

        if (loginAttemptService.isBlocked(request.getUsername())) {
            throw new RuntimeException("Too many failed attempts. Try again later.");
        }

        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            loginAttemptService.loginFailed(request.getUsername());
            throw new RuntimeException("Invalid password");
        }

        if (!user.getIsActive()) {
            throw new RuntimeException("User account is disabled");
        }

        if (Boolean.TRUE.equals(user.getTotpEnabled())) {
            String totpCode = request.getTotpCode();
            if (totpCode == null || totpCode.isBlank()) {
                throw new TotpRequiredException("TOTP code required");
            }

            boolean isValid = totpService.verifyCode(user.getTotpSecret(), totpCode);
            if (!isValid && user.getBackupCodesHash() != null) {
                isValid = totpService.verifyBackupCode(totpCode, user.getBackupCodesHash());
                if (isValid) {
                    String updatedHashes = totpService.removeUsedBackupCode(totpCode, user.getBackupCodesHash());
                    user.setBackupCodesHash(updatedHashes);
                    userRepository.save(user);
                    log.info("Backup code used for user: {}", user.getUsername());
                }
            }

            if (!isValid) {
                loginAttemptService.loginFailed(request.getUsername());
                throw new RuntimeException("Invalid TOTP or backup code");
            }
        }

        loginAttemptService.loginSucceeded(request.getUsername());

        UserSession session = sessionService.createSession(user.getId());
        return createAuthResponse(user, session.getToken());
    }

    public static class TotpRequiredException extends RuntimeException {
        public TotpRequiredException(String message) {
            super(message);
        }
    }

    @Transactional
    public AuthResponse registration(RegisterRequest request) {
        log.info("Registration attempt for username: {}", request.getUsername());

        if (userRepository.findByUsername(request.getUsername()).isPresent()) {
            throw new RuntimeException("Username already exists");
        }

        Role userRole = roleRepository.findByRoleName("USER")
                .orElseGet(() -> {
                    Role newRole = new Role();
                    newRole.setRoleName("USER");
                    return roleRepository.save(newRole);
                });

        String normalizedPrivateKey = normalizePrivateKeyEncrypted(request.getPrivateKeyEncrypted());
        String normalizedSalt = normalizeBase64String(request.getSalt());

        User user = User.builder()
                .username(request.getUsername())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .publicKey(request.getPublicKey())
                .privateKeyEncrypted(normalizedPrivateKey)
                .salt(normalizedSalt)
                .roles(new HashSet<>(Set.of(userRole)))
                .build();

        user = userRepository.save(user);
        log.info("User created with ID: {}", user.getId());

        UserSession session = sessionService.createSession(user.getId());

        return createAuthResponse(user, session.getToken());
    }

    private String normalizePrivateKeyEncrypted(String raw) {
        if (raw == null)
            return null;
        String cleaned = raw.trim();
        cleaned = cleaned.replaceFirst("^\uFEFF", "");
        while ((cleaned.startsWith("\"") && cleaned.endsWith("\"")) ||
                (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
            cleaned = cleaned.substring(1, cleaned.length() - 1).trim();
        }
        cleaned = cleaned.replace("\\\"", "\"");
        cleaned = cleaned.replaceAll("[\\x00-\\x1F\\x7F]", "");
        try {
            Object json = objectMapper.readValue(cleaned, Object.class);
            return objectMapper.writeValueAsString(json);
        } catch (JacksonException e) {
            log.warn("Failed to parse privateKeyEncrypted as JSON, storing as is: {}", e.getMessage());
            return cleaned;
        }
    }

    private String normalizeBase64String(String raw) {
        if (raw == null)
            return null;
        return raw.trim().replaceAll("[^A-Za-z0-9+/=]", "");
    }

    @Transactional(readOnly = true)
    public AuthResponse validateToken(String token) {
        log.debug("Validating token");

        Optional<UserSession> sessionOpt = sessionService.findValidSession(token);

        if (sessionOpt.isEmpty()) {
            throw new RuntimeException("Invalid or expired token");
        }

        UserSession session = sessionOpt.get();
        User user = userRepository.findById(session.getUserId())
                .orElseThrow(() -> new RuntimeException("User not found"));

        return createAuthResponse(user, token);
    }

    @Transactional
    public void logout(String token) {
        log.info("Logout for token");
        sessionService.deleteSession(token);
    }

    private AuthResponse createAuthResponse(User user, String accessToken) {
        AuthResponse response = new AuthResponse();
        response.setAccessToken(accessToken);
        response.setRefreshToken(null);
        response.setUserId(user.getId());
        response.setEmail(user.getEmail());
        response.setUsername(user.getUsername());
        response.setStorageUsed(user.getStorageUsed());
        response.setStorageLimit(user.getStorageLimit());

        Set<String> roles = user.getRoles().stream()
                .map(Role::getRoleName)
                .collect(Collectors.toSet());
        response.setRoles(roles);
        response.setTotpEnabled(user.getTotpEnabled());
        return response;
    }

    @Transactional
    public TotpSetupResponse setupTotp(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (Boolean.TRUE.equals(user.getTotpEnabled())) {
            throw new RuntimeException("TOTP is already enabled");
        }

        String secret = totpService.generateSecret();
        user.setTotpSecret(secret);
        user.setTotpEnabled(false);
        userRepository.save(user);

        try {
            String qrUrl = totpService.generateQrCodeUrl(secret, user.getUsername());
            return new TotpSetupResponse(secret, qrUrl);
        } catch (QrGenerationException e) {
            throw new RuntimeException("Failed to generate QR code", e);
        }
    }

    @Transactional
    public TotpVerifyResponse verifyAndEnableTotp(UUID userId, String code) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (user.getTotpSecret() == null) {
            throw new RuntimeException("TOTP setup not initiated");
        }

        if (!totpService.verifyCode(user.getTotpSecret(), code)) {
            throw new RuntimeException("Invalid TOTP code");
        }

        TotpService.BackupCodes backupCodes = totpService.generateBackupCodes();

        user.setTotpEnabled(true);
        user.setTotpVerifiedAt(LocalDateTime.now());
        user.setBackupCodesHash(backupCodes.hashesJson());
        userRepository.save(user);

        log.info("TOTP enabled for user: {}", user.getUsername());
        return new TotpVerifyResponse(true, backupCodes.plainCodes());
    }

    @Transactional
    public void disableTotp(UUID userId, String code) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!Boolean.TRUE.equals(user.getTotpEnabled())) {
            throw new RuntimeException("TOTP is not enabled");
        }

        boolean isValid = totpService.verifyCode(user.getTotpSecret(), code);
        if (!isValid) {
            if (user.getBackupCodesHash() != null) {
                isValid = totpService.verifyBackupCode(code, user.getBackupCodesHash());
                if (isValid) {
                    String updatedHashes = totpService.removeUsedBackupCode(code, user.getBackupCodesHash());
                    user.setBackupCodesHash(updatedHashes);
                }
            }
        }

        if (!isValid) {
            throw new RuntimeException("Invalid TOTP or backup code");
        }

        user.setTotpEnabled(false);
        user.setTotpSecret(null);
        user.setTotpVerifiedAt(null);
        user.setBackupCodesHash(null);
        userRepository.save(user);

        log.info("TOTP disabled for user: {}", user.getUsername());
    }

}
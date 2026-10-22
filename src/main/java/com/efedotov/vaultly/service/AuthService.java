package com.efedotov.vaultly.service;

import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import com.efedotov.vaultly.exception.UsernameAlreadyExistsException;
import org.apache.commons.codec.digest.DigestUtils;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.dao.DataIntegrityViolationException;
import com.efedotov.vaultly.dto.auth.AuthResponse;
import com.efedotov.vaultly.dto.auth.LoginRequest;
import com.efedotov.vaultly.dto.auth.LoginWithTotpRequest;
import com.efedotov.vaultly.dto.auth.RecoverRequest;
import com.efedotov.vaultly.dto.auth.RecoveryChallengeRequest;
import com.efedotov.vaultly.dto.auth.RecoveryChallengeResponse;
import com.efedotov.vaultly.dto.auth.RegisterRequest;
import com.efedotov.vaultly.dto.auth.TotpSetupResponse;
import com.efedotov.vaultly.dto.auth.TotpVerifyResponse;
import com.efedotov.vaultly.exception.TotpRequiredException;
import com.efedotov.vaultly.model.Role;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.model.UserSession;
import com.efedotov.vaultly.repository.RoleRepository;
import com.efedotov.vaultly.repository.UserRepository;
import dev.samstevens.totp.exceptions.QrGenerationException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private static final String DUMMY_BCRYPT_HASH = "$2a$12$HfiR86pa3YfuxiPkAxUAeOhmRHWqqPWRYMlbmWAQAxUMsbyaKCuEy";

    private final UserRepository userRepository;
    private final SessionService sessionService;
    private final PasswordEncoder passwordEncoder;
    private final RoleRepository roleRepository;
    private final TotpService totpService;
    private final LoginAttemptService loginAttemptService;
    private final EncryptionService encryptionService;
    private final RecoveryChallengeService recoveryChallengeService;
    private final PreAuthTokenService preAuthTokenService;

    @Transactional
    public AuthResponse login(LoginRequest request) {
        log.debug("Login attempt");

        if (loginAttemptService.isBlocked(request.getUsername())) {
            throw new RuntimeException("Invalid credentials");
        }

        User user = userRepository.findByUsername(request.getUsername()).orElse(null);

        if (user == null) {
            
            passwordEncoder.matches(request.getPassword(), DUMMY_BCRYPT_HASH);
            loginAttemptService.loginFailed(request.getUsername());
            throw new RuntimeException("Invalid credentials");
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            loginAttemptService.loginFailed(request.getUsername());
            throw new RuntimeException("Invalid credentials");
        }

        if (!Boolean.TRUE.equals(user.getIsActive())) {
            loginAttemptService.loginFailed(request.getUsername());
            throw new RuntimeException("Invalid credentials");
        }

        if (Boolean.TRUE.equals(user.getTotpEnabled())) {
            String totpCode = request.getTotpCode();
            if (totpCode == null || totpCode.isBlank()) {
                String preAuthToken = preAuthTokenService.issue(user.getId());
                throw new TotpRequiredException(preAuthToken);
            }

            if (!verifyTotpOrBackup(user, totpCode)) {
                loginAttemptService.loginFailed(request.getUsername());
                throw new RuntimeException("Invalid credentials");
            }
        }

        loginAttemptService.loginSucceeded(request.getUsername());
        SessionService.CreatedSession created = sessionService.createSession(user.getId());
        return createAuthResponse(user, created.plaintextToken());
    }

    private boolean verifyTotpOrBackup(User user, String code) {
        String plainSecret;
        try {
            plainSecret = encryptionService.decrypt(user.getTotpSecret());
        } catch (Exception e) {
            return false;
        }

        if (totpService.verifyCode(plainSecret, code)) {
            return true;
        }

        if (user.getBackupCodesHash() != null) {
            String key = "backup:" + user.getId();
            if (loginAttemptService.isBackupCodeBlocked(key)) {
                log.warn("Backup code attempts blocked for user {}", user.getId());
                return false;
            }

            boolean validBackup = totpService.verifyBackupCode(code, user.getBackupCodesHash());
            if (validBackup) {
                loginAttemptService.backupCodeSucceeded(key);
                String updatedHashes = totpService.removeUsedBackupCode(code, user.getBackupCodesHash());
                user.setBackupCodesHash(updatedHashes);
                userRepository.save(user);
                log.info("Backup code used for user: {}", user.getUsername());
                return true;
            }
            loginAttemptService.backupCodeFailed(key);
        }
        return false;
    }

    @Transactional
    public AuthResponse loginWithTotp(LoginWithTotpRequest request) {
        UUID userId = preAuthTokenService.consume(request.getPreAuthToken());

        if (userId == null) {

            dummyBcrypt(request.getTotpCode());
            throw new RuntimeException("Invalid credentials");
        }

        User user = userRepository.findById(userId).orElse(null);
        if (user == null) {
            dummyBcrypt(request.getTotpCode());
            throw new RuntimeException("Invalid credentials");
        }

        if (!Boolean.TRUE.equals(user.getIsActive())) {
            dummyBcrypt(request.getTotpCode());
            throw new RuntimeException("Invalid credentials");
        }

        if (loginAttemptService.isBlocked(user.getUsername())) {
            dummyBcrypt(request.getTotpCode());
            throw new RuntimeException("Invalid credentials");
        }

        if (Boolean.TRUE.equals(user.getTotpEnabled())) {
            if (!verifyTotpOrBackup(user, request.getTotpCode())) {
                loginAttemptService.loginFailed(user.getUsername());
                throw new RuntimeException("Invalid credentials");
            }
        }

        loginAttemptService.loginSucceeded(user.getUsername());
        SessionService.CreatedSession created = sessionService.createSession(user.getId());
        return createAuthResponse(user, created.plaintextToken());
    }

    
    @Transactional
    public AuthResponse registration(RegisterRequest request) {
        log.debug("Registration attempt");

        if (userRepository.findByUsername(request.getUsername()).isPresent()) {
            throw new UsernameAlreadyExistsException("Username already exists");
        }

        UserService.validatePublicKeyFormat(request.getPublicKey());

        Role userRole = roleRepository.findByRoleName("USER")
                .orElseGet(() -> {
                    Role newRole = new Role();
                    newRole.setRoleName("USER");
                    return roleRepository.save(newRole);
                });

        User user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .publicKey(request.getPublicKey())
                .roles(new HashSet<>(Set.of(userRole)))
                .build();

        try {
            user = userRepository.save(user);
        } catch (DataIntegrityViolationException e) {
            throw new UsernameAlreadyExistsException("Username already exists", e);
        }

        log.info("User created with ID: {}", user.getId());

        SessionService.CreatedSession created = sessionService.createSession(user.getId());
        return createAuthResponse(user, created.plaintextToken());
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
        log.debug("Logout");
        sessionService.deleteSession(token);
    }

    private AuthResponse createAuthResponse(User user, String accessToken) {
        AuthResponse response = new AuthResponse();
        response.setAccessToken(accessToken);

        response.setUserId(user.getId());
        response.setEmail(user.getEmail());
        response.setUsername(user.getUsername());
        response.setStorageUsed(user.getStorageUsed());
        response.setStorageLimit(user.getStorageLimit());

        Set<String> roles = user.getRoles().stream()
                .map(role -> role.getRoleName())
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

        String plainSecret = totpService.generateSecret();
        String encryptedSecret = encryptionService.encrypt(plainSecret);

        user.setTotpSecret(encryptedSecret);
        user.setTotpEnabled(false);
        userRepository.save(user);

        try {
            String qrUrl = totpService.generateQrCodeUrl(plainSecret, user.getUsername());
            return new TotpSetupResponse(qrUrl);
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

        String plainSecret;
        try {
            plainSecret = encryptionService.decrypt(user.getTotpSecret());
        } catch (Exception e) {
            throw new RuntimeException("Failed to decrypt TOTP secret", e);
        }

        if (!totpService.verifyCode(plainSecret, code)) {
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

        String plainSecret;
        try {
            plainSecret = encryptionService.decrypt(user.getTotpSecret());
        } catch (Exception e) {
            throw new RuntimeException("Failed to decrypt TOTP secret", e);
        }

        boolean isValid = totpService.verifyCode(plainSecret, code);
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

    @Transactional
    public AuthResponse recoverAccess(RecoverRequest request) {
        String publicKeyHash = DigestUtils.sha256Hex(request.getPublicKey());

        if (!recoveryChallengeService.consume(request.getChallenge(), publicKeyHash)) {
            throw new RuntimeException("Invalid or expired challenge");
        }

        String normalizedPublicKey = normalizePublicKey(request.getPublicKey());
        User user = userRepository.findByRecoveryPublicKey(normalizedPublicKey)
                .orElseThrow(() -> new RuntimeException("Recovery failed"));

        if (!user.getIsActive()) {
            throw new RuntimeException("Recovery failed");
        }

        if (!verifyRecoverySignature(
                user.getRecoveryPublicKey(), request.getChallenge(), request.getSignature())) {
            log.warn("Recovery signature verification failed for user {}", user.getId());
            throw new RuntimeException("Recovery failed");
        }

        SessionService.CreatedSession created = sessionService.createSession(user.getId());
        return createAuthResponse(user, created.plaintextToken());
    }

    public static String normalizePublicKey(String raw) {
        if (raw == null) {
            return null;
        }
        return raw.trim()
                .replaceAll("-----BEGIN [A-Z ]+-----", "")
                .replaceAll("-----END [A-Z ]+-----", "")
                .replaceAll("\\s+", "");
    }

    public RecoveryChallengeResponse createRecoveryChallenge(RecoveryChallengeRequest request) {
        String publicKeyHash = DigestUtils.sha256Hex(request.getPublicKey());
        String challenge = recoveryChallengeService.issue(publicKeyHash);
        return new RecoveryChallengeResponse(challenge, 300);
    }

    private boolean verifyRecoverySignature(String storedPublicKey, String challenge, String signatureBase64) {
        try {
            PublicKey publicKey = parsePublicKey(normalizePublicKey(storedPublicKey));
            java.security.Signature sig = java.security.Signature.getInstance("SHA256withRSA");
            sig.initVerify(publicKey);
            sig.update(challenge.getBytes(StandardCharsets.UTF_8));
            return sig.verify(Base64.getDecoder().decode(signatureBase64));
        } catch (Exception e) {
            log.warn("Recovery signature verification failed: {}", e.getMessage());
            return false;
        }
    }

    private PublicKey parsePublicKey(String normalizedBase64) throws Exception {
        byte[] der = Base64.getDecoder().decode(normalizedBase64);
        X509EncodedKeySpec spec = new X509EncodedKeySpec(der);
        return KeyFactory.getInstance("RSA").generatePublic(spec);
    }

    private void dummyBcrypt(String input) {
        passwordEncoder.matches(input != null && !input.isEmpty() ? input : "dummy-input", DUMMY_BCRYPT_HASH);
    }
}
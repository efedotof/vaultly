package com.efedotov.vaultly.service;

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
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.Signature;
import java.time.Instant;
import java.util.Base64;
import java.util.HashSet;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    UserRepository userRepository;
    @Mock
    SessionService sessionService;
    @Mock
    PasswordEncoder passwordEncoder;
    @Mock
    RoleRepository roleRepository;
    @Mock
    TotpService totpService;
    @Mock
    LoginAttemptService loginAttemptService;
    @Mock
    EncryptionService encryptionService;
    @Mock
    RecoveryChallengeService recoveryChallengeService;
    @Mock
    PreAuthTokenService preAuthTokenService;

    @InjectMocks
    AuthService service;

    private User activeUser() {
        return User.builder()
                .id(UUID.randomUUID())
                .username("alice")
                .passwordHash("hash")
                .isActive(true)
                .totpEnabled(false)
                .storageUsed(0L)
                .storageLimit(100L)
                .roles(new HashSet<>())
                .build();
    }

    private LoginRequest loginReq(String u, String p) {
        LoginRequest r = new LoginRequest();
        r.setUsername(u);
        r.setPassword(p);
        return r;
    }

    private SessionService.CreatedSession dummySession() {
        UserSession session = UserSession.builder()
                .tokenHash("hash")
                .userId(UUID.randomUUID())
                .createdAt(Instant.now())
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();
        return new SessionService.CreatedSession("plain-token", session);
    }

    @Test
    void login_userNotFound_throws_andDoesTimingEqualization() {
        when(loginAttemptService.isBlocked("alice")).thenReturn(false);
        when(userRepository.findByUsername("alice")).thenReturn(Optional.empty());
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(false);

        assertThatThrownBy(() -> service.login(loginReq("alice", "pw")))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Invalid credentials");

        verify(passwordEncoder).matches(eq("pw"), anyString());
        verify(loginAttemptService).loginFailed("alice");
    }

    @Test
    void login_blocked_throwsImmediately() {
        when(loginAttemptService.isBlocked("alice")).thenReturn(true);

        assertThatThrownBy(() -> service.login(loginReq("alice", "pw")))
                .isInstanceOf(RuntimeException.class);

        verify(userRepository, never()).findByUsername(anyString());
    }

    @Test
    void login_wrongPassword_throws() {
        User user = activeUser();
        when(loginAttemptService.isBlocked("alice")).thenReturn(false);
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("bad", "hash")).thenReturn(false);

        assertThatThrownBy(() -> service.login(loginReq("alice", "bad")))
                .isInstanceOf(RuntimeException.class);
        verify(loginAttemptService).loginFailed("alice");
    }

    @Test
    void login_inactiveUser_throws() {
        User user = activeUser();
        user.setIsActive(false);
        when(loginAttemptService.isBlocked("alice")).thenReturn(false);
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("pw", "hash")).thenReturn(true);

        assertThatThrownBy(() -> service.login(loginReq("alice", "pw")))
                .isInstanceOf(RuntimeException.class);
        verify(loginAttemptService).loginFailed("alice");
    }

    @Test
    void login_success_noTotp_returnsResponse() {
        User user = activeUser();
        when(loginAttemptService.isBlocked("alice")).thenReturn(false);
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("pw", "hash")).thenReturn(true);
        when(sessionService.createSession(user.getId())).thenReturn(dummySession());

        AuthResponse resp = service.login(loginReq("alice", "pw"));

        assertThat(resp.getAccessToken()).isEqualTo("plain-token");
        assertThat(resp.getUsername()).isEqualTo("alice");
        verify(loginAttemptService).loginSucceeded("alice");
    }

    @Test
    void login_totpEnabledNoCode_throwsTotpRequired() {
        User user = activeUser();
        user.setTotpEnabled(true);
        user.setTotpSecret("enc");
        when(loginAttemptService.isBlocked("alice")).thenReturn(false);
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("pw", "hash")).thenReturn(true);
        when(preAuthTokenService.issue(user.getId())).thenReturn("pre-123");

        assertThatThrownBy(() -> service.login(loginReq("alice", "pw")))
                .isInstanceOf(TotpRequiredException.class)
                .extracting(e -> ((TotpRequiredException) e).getPreAuthToken())
                .isEqualTo("pre-123");
    }

    @Test
    void login_totpEnabledValidCode_returnsResponse() {
        User user = activeUser();
        user.setTotpEnabled(true);
        user.setTotpSecret("enc");
        LoginRequest req = loginReq("alice", "pw");
        req.setTotpCode("123456");

        when(loginAttemptService.isBlocked("alice")).thenReturn(false);
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("pw", "hash")).thenReturn(true);
        when(encryptionService.decrypt("enc")).thenReturn("PLAIN");
        when(totpService.verifyCode("PLAIN", "123456")).thenReturn(true);
        when(sessionService.createSession(user.getId())).thenReturn(dummySession());

        AuthResponse resp = service.login(req);

        assertThat(resp.getAccessToken()).isEqualTo("plain-token");
    }

    @Test
    void login_totpEnabledInvalidCode_throws() {
        User user = activeUser();
        user.setTotpEnabled(true);
        user.setTotpSecret("enc");
        LoginRequest req = loginReq("alice", "pw");
        req.setTotpCode("000000");

        when(loginAttemptService.isBlocked("alice")).thenReturn(false);
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("pw", "hash")).thenReturn(true);
        when(encryptionService.decrypt("enc")).thenReturn("PLAIN");
        when(totpService.verifyCode("PLAIN", "000000")).thenReturn(false);

        assertThatThrownBy(() -> service.login(req))
                .isInstanceOf(RuntimeException.class);
        verify(loginAttemptService).loginFailed("alice");
    }

    @Test
    void login_totpBackupCode_success_consumesCode() {
        User user = activeUser();
        user.setTotpEnabled(true);
        user.setTotpSecret("enc");
        user.setBackupCodesHash("[hashes]");
        LoginRequest req = loginReq("alice", "pw");
        req.setTotpCode("BACKUPCODE");

        when(loginAttemptService.isBlocked("alice")).thenReturn(false);
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("pw", "hash")).thenReturn(true);
        when(encryptionService.decrypt("enc")).thenReturn("PLAIN");
        when(totpService.verifyCode("PLAIN", "BACKUPCODE")).thenReturn(false);
        when(loginAttemptService.isBackupCodeBlocked(anyString())).thenReturn(false);
        when(totpService.verifyBackupCode("BACKUPCODE", "[hashes]")).thenReturn(true);
        when(totpService.removeUsedBackupCode("BACKUPCODE", "[hashes]")).thenReturn("[remaining]");
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(sessionService.createSession(user.getId())).thenReturn(dummySession());

        AuthResponse resp = service.login(req);

        assertThat(resp.getAccessToken()).isEqualTo("plain-token");
        verify(loginAttemptService).backupCodeSucceeded(anyString());
        assertThat(user.getBackupCodesHash()).isEqualTo("[remaining]");
    }

    @Test
    void login_totpBackupBlocked_returnsFailure() {
        User user = activeUser();
        user.setTotpEnabled(true);
        user.setTotpSecret("enc");
        user.setBackupCodesHash("[hashes]");
        LoginRequest req = loginReq("alice", "pw");
        req.setTotpCode("X");

        when(loginAttemptService.isBlocked("alice")).thenReturn(false);
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("pw", "hash")).thenReturn(true);
        when(encryptionService.decrypt("enc")).thenReturn("PLAIN");
        when(totpService.verifyCode("PLAIN", "X")).thenReturn(false);
        when(loginAttemptService.isBackupCodeBlocked(anyString())).thenReturn(true);

        assertThatThrownBy(() -> service.login(req))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void login_totpDecryptionFails_returnsFailure() {
        User user = activeUser();
        user.setTotpEnabled(true);
        user.setTotpSecret("corrupted");
        LoginRequest req = loginReq("alice", "pw");
        req.setTotpCode("123456");

        when(loginAttemptService.isBlocked("alice")).thenReturn(false);
        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("pw", "hash")).thenReturn(true);
        when(encryptionService.decrypt("corrupted")).thenThrow(new RuntimeException("bad"));

        assertThatThrownBy(() -> service.login(req))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void loginWithTotp_invalidPreAuthToken_throws() {
        LoginWithTotpRequest req = new LoginWithTotpRequest();
        req.setPreAuthToken("bad");
        req.setTotpCode("123456");

        when(preAuthTokenService.consume("bad")).thenReturn(null);

        assertThatThrownBy(() -> service.loginWithTotp(req))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("pre-auth");
    }

    @Test
    void loginWithTotp_userMissing_throws() {
        UUID userId = UUID.randomUUID();
        LoginWithTotpRequest req = new LoginWithTotpRequest();
        req.setPreAuthToken("tok");
        req.setTotpCode("123456");

        when(preAuthTokenService.consume("tok")).thenReturn(userId);
        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.loginWithTotp(req))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void loginWithTotp_success() {
        User user = activeUser();
        user.setTotpEnabled(true);
        user.setTotpSecret("enc");
        LoginWithTotpRequest req = new LoginWithTotpRequest();
        req.setPreAuthToken("tok");
        req.setTotpCode("123456");

        when(preAuthTokenService.consume("tok")).thenReturn(user.getId());
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));
        when(encryptionService.decrypt("enc")).thenReturn("PLAIN");
        when(totpService.verifyCode("PLAIN", "123456")).thenReturn(true);
        when(sessionService.createSession(user.getId())).thenReturn(dummySession());

        AuthResponse resp = service.loginWithTotp(req);

        assertThat(resp.getAccessToken()).isEqualTo("plain-token");
        verify(loginAttemptService).loginSucceeded("alice");
    }

    @Test
    void loginWithTotp_inactiveUser_throws() {
        User user = activeUser();
        user.setIsActive(false);
        LoginWithTotpRequest req = new LoginWithTotpRequest();
        req.setPreAuthToken("tok");
        req.setTotpCode("123456");

        when(preAuthTokenService.consume("tok")).thenReturn(user.getId());
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> service.loginWithTotp(req))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void loginWithTotp_wrongCode_throws() {
        User user = activeUser();
        user.setTotpEnabled(true);
        user.setTotpSecret("enc");
        LoginWithTotpRequest req = new LoginWithTotpRequest();
        req.setPreAuthToken("tok");
        req.setTotpCode("000000");

        when(preAuthTokenService.consume("tok")).thenReturn(user.getId());
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));
        when(encryptionService.decrypt("enc")).thenReturn("PLAIN");
        when(totpService.verifyCode("PLAIN", "000000")).thenReturn(false);

        assertThatThrownBy(() -> service.loginWithTotp(req))
                .isInstanceOf(RuntimeException.class);
        verify(loginAttemptService).loginFailed("alice");
    }

    @Test
    void registration_usernameExists_throws() {
        RegisterRequest req = new RegisterRequest();
        req.setUsername("alice");
        req.setPassword("Password1!@#");

        when(userRepository.findByUsername("alice")).thenReturn(Optional.of(activeUser()));

        assertThatThrownBy(() -> service.registration(req))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Username already exists");
    }

    @Test
    void registration_existingRole_success() throws Exception {
        Role userRole = new Role();
        userRole.setId(1);
        userRole.setRoleName("USER");

        when(userRepository.findByUsername("alice")).thenReturn(Optional.empty());
        when(roleRepository.findByRoleName("USER")).thenReturn(Optional.of(userRole));
        when(passwordEncoder.encode("Password1!@#")).thenReturn("hash");
        when(userRepository.save(any(User.class))).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            u.setId(UUID.randomUUID());
            return u;
        });
        when(sessionService.createSession(any())).thenReturn(dummySession());

        RegisterRequest req = new RegisterRequest();
        req.setUsername("alice");
        req.setPassword("Password1!@#");
        req.setPublicKey(generateValidRsaPublicKeyPem());
        req.setPrivateKeyEncrypted("  \"key\"  ");
        req.setSalt("salt===+value");

        AuthResponse resp = service.registration(req);

        assertThat(resp.getUsername()).isEqualTo("alice");
    }

    @Test
    void registration_createsRoleIfMissing() throws Exception {
        Role newRole = new Role();
        newRole.setId(1);
        newRole.setRoleName("USER");

        when(userRepository.findByUsername("alice")).thenReturn(Optional.empty());
        when(roleRepository.findByRoleName("USER")).thenReturn(Optional.empty());
        when(roleRepository.save(any(Role.class))).thenReturn(newRole);
        when(passwordEncoder.encode(anyString())).thenReturn("hash");
        when(userRepository.save(any(User.class))).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            u.setId(UUID.randomUUID());
            return u;
        });
        when(sessionService.createSession(any())).thenReturn(dummySession());

        RegisterRequest req = new RegisterRequest();
        req.setUsername("alice");
        req.setPassword("Password1!@#");
        req.setPublicKey(generateValidRsaPublicKeyPem());
        req.setSalt("salt");

        service.registration(req);

        verify(roleRepository).save(any(Role.class));
    }

    @Test
    void registration_invalidPublicKey_throws() {
        when(userRepository.findByUsername("alice")).thenReturn(Optional.empty());
        when(roleRepository.findByRoleName("USER")).thenReturn(Optional.of(new Role()));
        when(passwordEncoder.encode(anyString())).thenReturn("hash");

        RegisterRequest req = new RegisterRequest();
        req.setUsername("alice");
        req.setPassword("Password1!@#");
        req.setPublicKey("not-a-valid-key");

        assertThatThrownBy(() -> service.registration(req))
                .isInstanceOf(com.efedotov.vaultly.exception.BadRequestException.class);
    }

    @Test
    void validateToken_noSession_throws() {
        when(sessionService.findValidSession("tok")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.validateToken("tok"))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void validateToken_userMissing_throws() {
        UserSession session = UserSession.builder()
                .tokenHash("h").userId(UUID.randomUUID())
                .createdAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        when(sessionService.findValidSession("tok")).thenReturn(Optional.of(session));
        when(userRepository.findById(session.getUserId())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.validateToken("tok"))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void validateToken_success_returnsResponse() {
        User user = activeUser();
        UserSession session = UserSession.builder()
                .tokenHash("h").userId(user.getId())
                .createdAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        when(sessionService.findValidSession("tok")).thenReturn(Optional.of(session));
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));

        AuthResponse resp = service.validateToken("tok");

        assertThat(resp.getAccessToken()).isEqualTo("tok");
        assertThat(resp.getUserId()).isEqualTo(user.getId());
    }

    @Test
    void logout_delegatesToSessionService() {
        service.logout("tok");
        verify(sessionService).deleteSession("tok");
    }

    @Test
    void setupTotp_userNotFound_throws() {
        UUID id = UUID.randomUUID();
        when(userRepository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.setupTotp(id))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void setupTotp_alreadyEnabled_throws() {
        User user = activeUser();
        user.setTotpEnabled(true);
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> service.setupTotp(user.getId()))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("already enabled");
    }

    @Test
    void setupTotp_success_returnsQr() throws Exception {
        User user = activeUser();
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));
        when(totpService.generateSecret()).thenReturn("PLAIN");
        when(encryptionService.encrypt("PLAIN")).thenReturn("enc");
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(totpService.generateQrCodeUrl("PLAIN", "alice")).thenReturn("data:image/png;base64,QR");

        TotpSetupResponse resp = service.setupTotp(user.getId());

        assertThat(resp.getQrCodeUrl()).startsWith("data:image/png;base64,");
        assertThat(user.getTotpSecret()).isEqualTo("enc");
        assertThat(user.getTotpEnabled()).isFalse();
    }

    @Test
    void verifyAndEnableTotp_userNotFound_throws() {
        UUID id = UUID.randomUUID();
        when(userRepository.findById(id)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.verifyAndEnableTotp(id, "123456"))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void verifyAndEnableTotp_noSecret_throws() {
        User user = activeUser();
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> service.verifyAndEnableTotp(user.getId(), "123456"))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("setup not initiated");
    }

    @Test
    void verifyAndEnableTotp_decryptFails_throws() {
        User user = activeUser();
        user.setTotpSecret("bad");
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));
        when(encryptionService.decrypt("bad")).thenThrow(new RuntimeException("fail"));

        assertThatThrownBy(() -> service.verifyAndEnableTotp(user.getId(), "123456"))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void verifyAndEnableTotp_wrongCode_throws() {
        User user = activeUser();
        user.setTotpSecret("enc");
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));
        when(encryptionService.decrypt("enc")).thenReturn("PLAIN");
        when(totpService.verifyCode("PLAIN", "000000")).thenReturn(false);

        assertThatThrownBy(() -> service.verifyAndEnableTotp(user.getId(), "000000"))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Invalid TOTP code");
    }

    @Test
    void verifyAndEnableTotp_success_enablesAndReturnsBackupCodes() {
        User user = activeUser();
        user.setTotpSecret("enc");
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));
        when(encryptionService.decrypt("enc")).thenReturn("PLAIN");
        when(totpService.verifyCode("PLAIN", "123456")).thenReturn(true);
        when(totpService.generateBackupCodes())
                .thenReturn(new TotpService.BackupCodes(
                        java.util.List.of("A", "B", "C"), "[hashes]"));
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        TotpVerifyResponse resp = service.verifyAndEnableTotp(user.getId(), "123456");

        assertThat(resp.isSuccess()).isTrue();
        assertThat(resp.getBackupCodes()).containsExactly("A", "B", "C");
        assertThat(user.getTotpEnabled()).isTrue();
        assertThat(user.getTotpVerifiedAt()).isNotNull();
    }

    @Test
    void disableTotp_userNotFound_throws() {
        UUID id = UUID.randomUUID();
        when(userRepository.findById(id)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.disableTotp(id, "123456"))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void disableTotp_notEnabled_throws() {
        User user = activeUser();
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> service.disableTotp(user.getId(), "123456"))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("not enabled");
    }

    @Test
    void disableTotp_validTotp_disables() {
        User user = activeUser();
        user.setTotpEnabled(true);
        user.setTotpSecret("enc");
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));
        when(encryptionService.decrypt("enc")).thenReturn("PLAIN");
        when(totpService.verifyCode("PLAIN", "123456")).thenReturn(true);
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.disableTotp(user.getId(), "123456");

        assertThat(user.getTotpEnabled()).isFalse();
        assertThat(user.getTotpSecret()).isNull();
        assertThat(user.getBackupCodesHash()).isNull();
    }

    @Test
    void disableTotp_validBackupCode_disables() {
        User user = activeUser();
        user.setTotpEnabled(true);
        user.setTotpSecret("enc");
        user.setBackupCodesHash("[hashes]");
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));
        when(encryptionService.decrypt("enc")).thenReturn("PLAIN");
        when(totpService.verifyCode("PLAIN", "BACKUP")).thenReturn(false);
        when(totpService.verifyBackupCode("BACKUP", "[hashes]")).thenReturn(true);
        when(totpService.removeUsedBackupCode("BACKUP", "[hashes]")).thenReturn("[]");
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.disableTotp(user.getId(), "BACKUP");

        assertThat(user.getTotpEnabled()).isFalse();
    }

    @Test
    void disableTotp_invalidCode_throws() {
        User user = activeUser();
        user.setTotpEnabled(true);
        user.setTotpSecret("enc");
        user.setBackupCodesHash("[hashes]");
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));
        when(encryptionService.decrypt("enc")).thenReturn("PLAIN");
        when(totpService.verifyCode("PLAIN", "BAD")).thenReturn(false);
        when(totpService.verifyBackupCode("BAD", "[hashes]")).thenReturn(false);

        assertThatThrownBy(() -> service.disableTotp(user.getId(), "BAD"))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Invalid TOTP");
    }

    @Test
    void createRecoveryChallenge_success() {
        RecoveryChallengeRequest req = new RecoveryChallengeRequest();
        req.setPublicKey("PUBKEY");

        when(loginAttemptService.isBlocked(anyString())).thenReturn(false);
        when(recoveryChallengeService.issue(anyString())).thenReturn("challenge-xyz");

        RecoveryChallengeResponse resp = service.createRecoveryChallenge(req);

        assertThat(resp.getChallenge()).isEqualTo("challenge-xyz");
        assertThat(resp.getExpiresInSeconds()).isEqualTo(300);
    }

    @Test
    void createRecoveryChallenge_blocked_throws() {
        RecoveryChallengeRequest req = new RecoveryChallengeRequest();
        req.setPublicKey("PUBKEY");

        when(loginAttemptService.isBlocked(anyString())).thenReturn(true);

        assertThatThrownBy(() -> service.createRecoveryChallenge(req))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Too many");
    }

    @Test
    void recoverAccess_blocked_throws() {
        RecoverRequest req = new RecoverRequest();
        req.setPublicKey("PK");
        req.setChallenge("ch");
        req.setSignature("sig");

        when(loginAttemptService.isBlocked(anyString())).thenReturn(true);

        assertThatThrownBy(() -> service.recoverAccess(req))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Too many");
    }

    @Test
    void recoverAccess_invalidChallenge_throws() {
        RecoverRequest req = new RecoverRequest();
        req.setPublicKey("PK");
        req.setChallenge("ch");
        req.setSignature("sig");

        when(loginAttemptService.isBlocked(anyString())).thenReturn(false);
        when(recoveryChallengeService.consume(anyString(), anyString())).thenReturn(false);

        assertThatThrownBy(() -> service.recoverAccess(req))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Invalid or expired challenge");
        verify(loginAttemptService).loginFailed(anyString());
    }

    @Test
    void recoverAccess_userNotFound_throws() throws Exception {
        KeyPair kp = generateKeyPair();
        String publicKeyPem = toPem("PUBLIC KEY", kp.getPublic().getEncoded());

        RecoverRequest req = new RecoverRequest();
        req.setPublicKey(publicKeyPem);
        req.setChallenge("challenge");
        req.setSignature("sig");

        when(loginAttemptService.isBlocked(anyString())).thenReturn(false);
        when(recoveryChallengeService.consume(anyString(), anyString())).thenReturn(true);
        when(userRepository.findByRecoveryPublicKey(anyString())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.recoverAccess(req))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Recovery failed");
    }

    @Test
    void recoverAccess_validSignature_returnsAuthResponse() throws Exception {
        KeyPair kp = generateKeyPair();
        String publicKeyPem = toPem("PUBLIC KEY", kp.getPublic().getEncoded());
        String challenge = "challenge-xyz";

        Signature signer = Signature.getInstance("SHA256withRSA");
        signer.initSign(kp.getPrivate());
        signer.update(challenge.getBytes(StandardCharsets.UTF_8));
        String signatureB64 = Base64.getEncoder().encodeToString(signer.sign());

        User user = activeUser();
        user.setRecoveryPublicKey(AuthService.normalizePublicKey(publicKeyPem));

        RecoverRequest req = new RecoverRequest();
        req.setPublicKey(publicKeyPem);
        req.setChallenge(challenge);
        req.setSignature(signatureB64);

        when(loginAttemptService.isBlocked(anyString())).thenReturn(false);
        when(recoveryChallengeService.consume(anyString(), anyString())).thenReturn(true);
        when(userRepository.findByRecoveryPublicKey(anyString())).thenReturn(Optional.of(user));
        when(sessionService.createSession(user.getId())).thenReturn(dummySession());

        AuthResponse resp = service.recoverAccess(req);

        assertThat(resp.getAccessToken()).isEqualTo("plain-token");
        assertThat(resp.getUsername()).isEqualTo("alice");
    }

    @Test
    void recoverAccess_badSignature_throws() throws Exception {
        KeyPair kp = generateKeyPair();
        String publicKeyPem = toPem("PUBLIC KEY", kp.getPublic().getEncoded());

        User user = activeUser();
        user.setRecoveryPublicKey(AuthService.normalizePublicKey(publicKeyPem));

        RecoverRequest req = new RecoverRequest();
        req.setPublicKey(publicKeyPem);
        req.setChallenge("challenge");

        req.setSignature(Base64.getEncoder().encodeToString(new byte[256]));

        when(loginAttemptService.isBlocked(anyString())).thenReturn(false);
        when(recoveryChallengeService.consume(anyString(), anyString())).thenReturn(true);
        when(userRepository.findByRecoveryPublicKey(anyString())).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> service.recoverAccess(req))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Recovery failed");
    }

    @Test
    void normalizePublicKey_null_returnsNull() {
        assertThat(AuthService.normalizePublicKey(null)).isNull();
    }

    @Test
    void normalizePublicKey_stripsPemAndWhitespace() {
        String raw = "-----BEGIN PUBLIC KEY-----\nABC DEF\n-----END PUBLIC KEY-----";
        assertThat(AuthService.normalizePublicKey(raw)).isEqualTo("ABCDEF");
    }

    private static KeyPair generateKeyPair() throws Exception {
        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(2048);
        return kpg.generateKeyPair();
    }

    private static String toPem(String label, byte[] der) {
        return "-----BEGIN " + label + "-----\n"
                + Base64.getMimeEncoder().encodeToString(der)
                + "\n-----END " + label + "-----";
    }

    private static String generateValidRsaPublicKeyPem() throws Exception {
        return toPem("PUBLIC KEY", generateKeyPair().getPublic().getEncoded());
    }

    @Test
    void setupTotp_qrGenerationFails_throws() throws Exception {
        User user = activeUser();
        when(userRepository.findById(user.getId())).thenReturn(Optional.of(user));
        when(totpService.generateSecret()).thenReturn("PLAIN");
        when(encryptionService.encrypt("PLAIN")).thenReturn("enc");
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(totpService.generateQrCodeUrl("PLAIN", "alice"))
                .thenThrow(new dev.samstevens.totp.exceptions.QrGenerationException("fail", null));

        assertThatThrownBy(() -> service.setupTotp(user.getId()))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("QR code");
    }

    @Test
    void recoverAccess_inactiveUser_throws() throws Exception {
        KeyPair kp = generateKeyPair();
        String pem = toPem("PUBLIC KEY", kp.getPublic().getEncoded());

        User user = activeUser();
        user.setIsActive(false);
        user.setRecoveryPublicKey(AuthService.normalizePublicKey(pem));

        RecoverRequest req = new RecoverRequest();
        req.setPublicKey(pem);
        req.setChallenge("challenge");
        req.setSignature("sig");

        when(loginAttemptService.isBlocked(anyString())).thenReturn(false);
        when(recoveryChallengeService.consume(anyString(), anyString())).thenReturn(true);
        when(userRepository.findByRecoveryPublicKey(anyString())).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> service.recoverAccess(req))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Recovery failed");
    }

    @Test
    void registration_withBomAndQuotedPrivateKey_normalizes() throws Exception {
        Role userRole = new Role();
        userRole.setRoleName("USER");

        when(userRepository.findByUsername("alice")).thenReturn(Optional.empty());
        when(roleRepository.findByRoleName("USER")).thenReturn(Optional.of(userRole));
        when(passwordEncoder.encode(anyString())).thenReturn("hash");
        when(userRepository.save(any(User.class))).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            u.setId(UUID.randomUUID());
            return u;
        });
        when(sessionService.createSession(any())).thenReturn(dummySession());

        String jsonQuoted = "\uFEFF\"{\\\"encrypted\\\":\\\"value\\\"}\"";

        RegisterRequest req = new RegisterRequest();
        req.setUsername("alice");
        req.setPassword("Password1!@#");
        req.setPublicKey(generateValidRsaPublicKeyPem());
        req.setPrivateKeyEncrypted(jsonQuoted);
        req.setSalt("salt");

        service.registration(req);

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());

        assertThat(captor.getValue().getPrivateKeyEncrypted()).doesNotContain("\uFEFF");
    }

    @Test
    void registration_privateKeyEmptyString_passesThrough() throws Exception {
        Role userRole = new Role();
        userRole.setRoleName("USER");
        when(userRepository.findByUsername("alice")).thenReturn(Optional.empty());
        when(roleRepository.findByRoleName("USER")).thenReturn(Optional.of(userRole));
        when(passwordEncoder.encode(anyString())).thenReturn("hash");
        when(userRepository.save(any(User.class))).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            u.setId(UUID.randomUUID());
            return u;
        });
        when(sessionService.createSession(any())).thenReturn(dummySession());

        RegisterRequest req = new RegisterRequest();
        req.setUsername("alice");
        req.setPassword("Password1!@#");
        req.setPublicKey(generateValidRsaPublicKeyPem());
        req.setPrivateKeyEncrypted("just-a-plain-string");
        req.setSalt("salt!@#");

        service.registration(req);
    }
}
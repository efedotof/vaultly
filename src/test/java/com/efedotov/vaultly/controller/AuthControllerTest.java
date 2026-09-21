package com.efedotov.vaultly.controller;

import com.efedotov.vaultly.dto.auth.AuthResponse;
import com.efedotov.vaultly.dto.auth.LoginRequest;
import com.efedotov.vaultly.dto.auth.LoginWithTotpRequest;
import com.efedotov.vaultly.dto.auth.RecoverRequest;
import com.efedotov.vaultly.dto.auth.RecoveryChallengeRequest;
import com.efedotov.vaultly.dto.auth.RecoveryChallengeResponse;
import com.efedotov.vaultly.dto.auth.TotpSetupResponse;
import com.efedotov.vaultly.dto.auth.TotpVerifyResponse;
import com.efedotov.vaultly.exception.TotpRequiredException;
import com.efedotov.vaultly.exception.UsernameAlreadyExistsException;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.AuthService;
import com.efedotov.vaultly.service.LoginAttemptService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = AuthController.class)
class AuthControllerTest extends BaseControllerTest {

        @Autowired
        MockMvc mockMvc;
        @Autowired
        AuthController authController;

        @MockitoBean
        AuthService authService;
        @MockitoBean
        LoginAttemptService loginAttemptService;

        private UUID userId;
        private UsernamePasswordAuthenticationToken auth;

        @BeforeEach
        void setUp() {
                userId = UUID.randomUUID();
                User user = User.builder().id(userId).username("alice").isActive(true).build();
                CustomUserDetails principal = new CustomUserDetails(user);
                auth = new UsernamePasswordAuthenticationToken(principal, null, List.of());
                SecurityContextHolder.getContext().setAuthentication(auth);
        }

        @AfterEach
        void tearDown() {
                SecurityContextHolder.clearContext();
                ReflectionTestUtils.setField(authController, "trustForwardedHeaders", false);
        }

        @Test
        void health_isPublic() throws Exception {
                mockMvc.perform(get("/api/auth/health"))
                                .andExpect(status().isOk());
        }

        @Test
        void login_success_returns200WithToken() throws Exception {
                when(loginAttemptService.isIpBlocked(anyString())).thenReturn(false);

                AuthResponse resp = new AuthResponse();
                resp.setAccessToken("tok");
                resp.setUsername("alice");
                when(authService.login(any(LoginRequest.class))).thenReturn(resp);

                String body = """
                                {"username":"alice","password":"Password1!"}
                                """;

                mockMvc.perform(post("/api/auth/login")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.accessToken").value("tok"))
                                .andExpect(jsonPath("$.username").value("alice"));
        }

        @Test
        void login_totpRequired_returns401WithPreAuthToken() throws Exception {
                when(loginAttemptService.isIpBlocked(anyString())).thenReturn(false);
                when(authService.login(any(LoginRequest.class)))
                                .thenThrow(new TotpRequiredException("pre-123"));

                String body = """
                                {"username":"alice","password":"Password1!"}
                                """;

                mockMvc.perform(post("/api/auth/login")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isUnauthorized())
                                .andExpect(jsonPath("$.error").value("totp_required"))
                                .andExpect(jsonPath("$.preAuthToken").value("pre-123"));
        }

        @Test
        void login_badCredentials_returns401() throws Exception {
                when(loginAttemptService.isIpBlocked(anyString())).thenReturn(false);
                when(authService.login(any(LoginRequest.class)))
                                .thenThrow(new RuntimeException("Invalid credentials"));

                String body = """
                                {"username":"alice","password":"wrong"}
                                """;

                mockMvc.perform(post("/api/auth/login")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isUnauthorized())
                                .andExpect(jsonPath("$.error").value("login_failed"));
        }

        @Test
        void login_ipBlocked_returns429() throws Exception {
                when(loginAttemptService.isIpBlocked(anyString())).thenReturn(true);

                String body = """
                                {"username":"alice","password":"Password1!"}
                                """;

                mockMvc.perform(post("/api/auth/login")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isTooManyRequests())
                                .andExpect(jsonPath("$.error").value("rate_limited"));
        }

        @Test
        void register_invalidPassword_returns400() throws Exception {
                String body = """
                                {"username":"alice","password":"short"}
                                """;

                mockMvc.perform(post("/api/auth/register")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isBadRequest());
        }

        @Test
        void register_duplicateUsername_returns400() throws Exception {
                when(loginAttemptService.isIpBlocked(anyString())).thenReturn(false);
                when(authService.registration(any()))
                                .thenThrow(new UsernameAlreadyExistsException("taken"));

                String body = """
                                {"username":"alice","password":"Password1!@#"}
                                """;

                mockMvc.perform(post("/api/auth/register")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isBadRequest());
        }

        @Test
        void register_ipBlocked_returns400() throws Exception {
                when(loginAttemptService.isIpBlocked(anyString())).thenReturn(true);

                String body = """
                                {"username":"alice","password":"Password1!@#"}
                                """;

                mockMvc.perform(post("/api/auth/register")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isBadRequest());
        }

        @Test
        void register_success_returnsAuthResponse() throws Exception {
                when(loginAttemptService.isIpBlocked(anyString())).thenReturn(false);
                AuthResponse resp = new AuthResponse();
                resp.setUsername("alice");
                when(authService.registration(any())).thenReturn(resp);

                String body = """
                                {"username":"alice","password":"Password1!@#"}
                                """;

                mockMvc.perform(post("/api/auth/register")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.username").value("alice"));
        }

        @Test
        void loginWithTotp_success_returns200() throws Exception {
                when(loginAttemptService.isIpBlocked(anyString())).thenReturn(false);

                AuthResponse resp = new AuthResponse();
                resp.setAccessToken("tok");
                when(authService.loginWithTotp(any(LoginWithTotpRequest.class))).thenReturn(resp);

                String body = """
                                {"preAuthToken":"pre-token","totpCode":"123456"}
                                """;

                mockMvc.perform(post("/api/auth/login/totp")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.accessToken").value("tok"));
        }

        @Test
        void loginWithTotp_failure_returns401() throws Exception {
                when(loginAttemptService.isIpBlocked(anyString())).thenReturn(false);
                when(authService.loginWithTotp(any()))
                                .thenThrow(new RuntimeException("Invalid"));

                String body = """
                                {"preAuthToken":"pre","totpCode":"000000"}
                                """;

                mockMvc.perform(post("/api/auth/login/totp")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isUnauthorized())
                                .andExpect(jsonPath("$.error").value("login_failed"));
        }

        @Test
        void setupTotp_returnsQr() throws Exception {
                TotpSetupResponse resp = new TotpSetupResponse("data:image/png;base64,QR");
                when(authService.setupTotp(userId)).thenReturn(resp);

                mockMvc.perform(post("/api/auth/totp/setup")
                                .with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.qrCodeUrl").value("data:image/png;base64,QR"));
        }

        @Test
        void verifyTotp_returnsBackupCodes() throws Exception {
                TotpVerifyResponse resp = new TotpVerifyResponse(
                                true, List.of("A", "B", "C"));
                when(authService.verifyAndEnableTotp(eq(userId), eq("123456"))).thenReturn(resp);

                String body = """
                                {"code":"123456"}
                                """;

                mockMvc.perform(post("/api/auth/totp/verify")
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.success").value(true))
                                .andExpect(jsonPath("$.backupCodes[0]").value("A"));
        }

        @Test
        void disableTotp_returns200() throws Exception {
                String body = """
                                {"code":"123456"}
                                """;

                mockMvc.perform(post("/api/auth/totp/disable")
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk());

                verify(authService).disableTotp(userId, "123456");
        }

        @Test
        void validate_missingBody_returnsOk() throws Exception {
                mockMvc.perform(post("/api/auth/validate")
                                .contentType(MediaType.APPLICATION_JSON).content("{}"))
                                .andExpect(status().isOk());
        }

        @Test
        void validate_withToken_returnsResponse() throws Exception {
                AuthResponse resp = new AuthResponse();
                resp.setUsername("alice");
                when(authService.validateToken("tok")).thenReturn(resp);

                String body = """
                                {"token":"tok"}
                                """;

                mockMvc.perform(post("/api/auth/validate")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.username").value("alice"));
        }

        @Test
        void logout_returns200() throws Exception {
                String body = """
                                {"token":"tok"}
                                """;

                mockMvc.perform(post("/api/auth/logout")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk());

                verify(authService).logout("tok");
        }

        @Test
        void recoverAccess_returnsAuthResponse() throws Exception {
                AuthResponse resp = new AuthResponse();
                resp.setAccessToken("recovered-token");
                when(authService.recoverAccess(any(RecoverRequest.class))).thenReturn(resp);

                String body = """
                                {"publicKey":"PK","challenge":"ch","signature":"sig"}
                                """;

                mockMvc.perform(post("/api/auth/recover")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.accessToken").value("recovered-token"));
        }

        @Test
        void recoverChallenge_returnsChallenge() throws Exception {
                RecoveryChallengeResponse resp = new RecoveryChallengeResponse("ch-123", 300);
                when(authService.createRecoveryChallenge(any(RecoveryChallengeRequest.class)))
                                .thenReturn(resp);

                String body = """
                                {"publicKey":"PK"}
                                """;

                mockMvc.perform(post("/api/auth/recover/challenge")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.challenge").value("ch-123"))
                                .andExpect(jsonPath("$.expiresInSeconds").value(300));
        }

        @Test
        void login_withTrustedXff_usesLastIpInChain() throws Exception {
                ReflectionTestUtils.setField(authController, "trustForwardedHeaders", true);

                when(loginAttemptService.isIpBlocked("9.9.9.9")).thenReturn(false);
                when(authService.login(any())).thenReturn(new AuthResponse());

                String body = """
                                {"username":"alice","password":"Password1!"}
                                """;

                mockMvc.perform(post("/api/auth/login")
                                .header("X-Forwarded-For", "1.1.1.1, 2.2.2.2, 9.9.9.9")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk());

                verify(loginAttemptService).isIpBlocked("9.9.9.9");
        }

        @Test
        void login_withTrustedXffButBlank_fallsBackToRemoteAddr() throws Exception {
                ReflectionTestUtils.setField(authController, "trustForwardedHeaders", true);

                when(loginAttemptService.isIpBlocked(anyString())).thenReturn(false);
                when(authService.login(any())).thenReturn(new AuthResponse());

                String body = """
                                {"username":"alice","password":"Password1!"}
                                """;

                mockMvc.perform(post("/api/auth/login")
                                .header("X-Forwarded-For", "   ")
                                .with(req -> {
                                        req.setRemoteAddr("10.0.0.1");
                                        return req;
                                })
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk());

                verify(loginAttemptService).isIpBlocked("10.0.0.1");
        }

        @Test
        void login_withTrustedXffMissingHeader_fallsBackToRemoteAddr() throws Exception {
                ReflectionTestUtils.setField(authController, "trustForwardedHeaders", true);

                when(loginAttemptService.isIpBlocked(anyString())).thenReturn(false);
                when(authService.login(any())).thenReturn(new AuthResponse());

                String body = """
                                {"username":"alice","password":"Password1!"}
                                """;

                mockMvc.perform(post("/api/auth/login")
                                .with(req -> {
                                        req.setRemoteAddr("10.0.0.2");
                                        return req;
                                })
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk());

                verify(loginAttemptService).isIpBlocked("10.0.0.2");
        }

        @Test
        void login_xffWithEmptyLastElement_fallsBackToRemoteAddr() throws Exception {
                ReflectionTestUtils.setField(authController, "trustForwardedHeaders", true);

                when(loginAttemptService.isIpBlocked(anyString())).thenReturn(false);
                when(authService.login(any())).thenReturn(new AuthResponse());

                String body = """
                                {"username":"alice","password":"Password1!"}
                                """;

                mockMvc.perform(post("/api/auth/login")
                                .header("X-Forwarded-For", "1.1.1.1,   ")
                                .with(req -> {
                                        req.setRemoteAddr("10.0.0.3");
                                        return req;
                                })
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk());

                verify(loginAttemptService).isIpBlocked("10.0.0.3");
        }
}
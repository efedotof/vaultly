package com.efedotov.vaultly.controller;

import com.efedotov.vaultly.dto.user.RecoveryDataResponse;
import com.efedotov.vaultly.dto.user.UserProfileDto;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.UserService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.hamcrest.Matchers.nullValue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = UserController.class)
class UserControllerTest extends BaseControllerTest {

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    UserService userService;

    private UUID userId;
    private UsernamePasswordAuthenticationToken auth;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        User user = User.builder().id(userId).username("alice").isActive(true).build();
        CustomUserDetails principal = new CustomUserDetails(user);
        auth = new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private UserProfileDto profile(String username) {
        UserProfileDto dto = new UserProfileDto();
        dto.setId(userId);
        dto.setUsername(username);
        return dto;
    }

    

    @Test
    void getMe_returnsProfile() throws Exception {
        when(userService.getUserProfile(userId)).thenReturn(profile("alice"));

        mockMvc.perform(get("/api/users/me").with(authentication(auth)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("alice"))
                .andExpect(jsonPath("$.id").value(userId.toString()));
    }

    

    @Test
    void updateMe_valid_returnsProfile() throws Exception {
        when(userService.updateUser(eq(userId), any())).thenReturn(profile("alice2"));

        String body = """
                {"username":"alice2"}
                """;

        mockMvc.perform(put("/api/users/me")
                .with(authentication(auth))
                .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("alice2"));
    }

    @Test
    void updateMe_invalidUsername_returns400() throws Exception {
        String body = """
                {"username":"a b"}
                """;

        mockMvc.perform(put("/api/users/me")
                .with(authentication(auth))
                .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest());
    }

    

    @Test
    void getPublicProfileById_stripsSensitiveFields() throws Exception {
        UUID otherId = UUID.randomUUID();
        UserProfileDto dto = new UserProfileDto();
        dto.setId(otherId);
        dto.setUsername("bob");
        dto.setEmail("bob@example.com");
        dto.setPublicKey("pub");
        when(userService.getUserProfile(otherId)).thenReturn(dto);

        mockMvc.perform(get("/api/users/{id}", otherId).with(authentication(auth)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(otherId.toString()))
                .andExpect(jsonPath("$.username").value("bob"))
                .andExpect(jsonPath("$.publicKey").value("pub"))
                .andExpect(jsonPath("$.email").value(nullValue()));
    }

    

    @Test
    void getEncryptedPrivateKey_validJson_returnsNormalizedJson() throws Exception {
        when(userService.getEncryptedPrivateKey(userId))
                .thenReturn("{\"k\":\"v\"}");

        mockMvc.perform(get("/api/users/me/private-key-encrypted")
                .with(authentication(auth)))
                .andExpect(status().isOk())
                .andExpect(content().json("{\"k\":\"v\"}"));
    }

    @Test
    void getEncryptedPrivateKey_nonJson_returnsRawString() throws Exception {
        when(userService.getEncryptedPrivateKey(userId))
                .thenReturn("not-a-json-payload");

        mockMvc.perform(get("/api/users/me/private-key-encrypted")
                .with(authentication(auth)))
                .andExpect(status().isOk())
                .andExpect(content().string("not-a-json-payload"));
    }

    

    @Test
    void getSalt_returnsSaltString() throws Exception {
        when(userService.getSalt(userId)).thenReturn("SALT_VALUE");

        mockMvc.perform(get("/api/users/me/salt").with(authentication(auth)))
                .andExpect(status().isOk())
                .andExpect(content().string("SALT_VALUE"));
    }

    

    @Test
    void getRecoveryData_returnsResponse() throws Exception {
        RecoveryDataResponse resp = new RecoveryDataResponse("rsa-blob", "salt-val");
        when(userService.getRecoveryData(userId)).thenReturn(resp);

        mockMvc.perform(get("/api/users/me/recovery-data").with(authentication(auth)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.recoveryEncryptedRsaKey").value("rsa-blob"))
                .andExpect(jsonPath("$.salt").value("salt-val"));
    }

    

    @Test
    void updateKeys_valid_returns200() throws Exception {
        String body = """
                {"publicKey":"pub","privateKeyEncrypted":"priv","currentPassword":"pass"}
                """;

        mockMvc.perform(post("/api/users/keys/update")
                .with(authentication(auth))
                .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk());

        verify(userService).updateKeys(eq(userId), any());
    }

    @Test
    void updateKeys_invalidBody_returns400() throws Exception {
        String body = """
                {"publicKey":"","privateKeyEncrypted":"","currentPassword":""}
                """;

        mockMvc.perform(post("/api/users/keys/update")
                .with(authentication(auth))
                .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest());
    }

    

    @Test
    void updateRecoveryKeys_valid_returns200() throws Exception {
        String body = """
                {"recoveryPublicKey":"rpub","recoveryPrivateKeyEncrypted":"rpriv",
                 "recoveryEncryptedRsaKey":"rsa","currentPassword":"pass"}
                """;

        mockMvc.perform(post("/api/users/keys/recovery/update")
                .with(authentication(auth))
                .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk());

        verify(userService).updateRecoveryKeys(eq(userId), any());
    }

    @Test
    void updateRecoveryKeys_invalidBody_returns400() throws Exception {
        String body = """
                {"recoveryPublicKey":"","recoveryPrivateKeyEncrypted":"",
                 "recoveryEncryptedRsaKey":"","currentPassword":""}
                """;

        mockMvc.perform(post("/api/users/keys/recovery/update")
                .with(authentication(auth))
                .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest());
    }
}
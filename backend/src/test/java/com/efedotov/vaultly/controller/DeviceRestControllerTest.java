package com.efedotov.vaultly.controller;

import com.efedotov.vaultly.dto.device.DeviceResponse;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.DeviceService;
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

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = DeviceRestController.class)
class DeviceRestControllerTest extends BaseControllerTest {

    @Autowired MockMvc mockMvc;

    @MockitoBean DeviceService deviceService;

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

    

    @Test
    void register_valid_returnsDto() throws Exception {
        DeviceResponse resp = DeviceResponse.builder()
                .id(UUID.randomUUID()).deviceName("laptop").uniqueId("uid-1").isActive(true).build();
        when(deviceService.registerDevice(any(), eq(userId))).thenReturn(resp);

        String body = """
                {"deviceName":"laptop","uniqueId":"uid-1","deviceType":"DESKTOP"}
                """;

        mockMvc.perform(post("/api/device/register")
                        .with(authentication(auth))
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.deviceName").value("laptop"))
                .andExpect(jsonPath("$.uniqueId").value("uid-1"))
                .andExpect(jsonPath("$.isActive").value(true));
    }

    @Test
    void register_missingDeviceName_returns400() throws Exception {
        String body = """
                {"uniqueId":"uid-1"}
                """;

        mockMvc.perform(post("/api/device/register")
                        .with(authentication(auth))
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void register_missingUniqueId_returns400() throws Exception {
        String body = """
                {"deviceName":"laptop"}
                """;

        mockMvc.perform(post("/api/device/register")
                        .with(authentication(auth))
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void register_serviceThrows_propagates() throws Exception {
        when(deviceService.registerDevice(any(), eq(userId)))
                .thenThrow(new SecurityException("device takeover"));

        String body = """
                {"deviceName":"laptop","uniqueId":"uid-1"}
                """;

        mockMvc.perform(post("/api/device/register")
                        .with(authentication(auth))
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isForbidden());
    }

    

    @Test
    void getUserDevices_returnsList() throws Exception {
        DeviceResponse d1 = DeviceResponse.builder()
                .id(UUID.randomUUID()).deviceName("laptop").uniqueId("u1").isActive(true).build();
        DeviceResponse d2 = DeviceResponse.builder()
                .id(UUID.randomUUID()).deviceName("phone").uniqueId("u2").isActive(false).build();
        when(deviceService.getUserDevices(userId)).thenReturn(List.of(d1, d2));

        mockMvc.perform(get("/api/device/me-device").with(authentication(auth)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].uniqueId").value("u1"))
                .andExpect(jsonPath("$[1].uniqueId").value("u2"));
    }

    @Test
    void getUserDevices_emptyList_returns200() throws Exception {
        when(deviceService.getUserDevices(userId)).thenReturn(List.of());

        mockMvc.perform(get("/api/device/me-device").with(authentication(auth)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    

    @Test
    void getEncryptedPrivateKey_returnsKey() throws Exception {
        UUID deviceId = UUID.randomUUID();
        when(deviceService.getEncryptedPrivateKey(deviceId, userId))
                .thenReturn("ENCRYPTED_KEY_DATA");

        mockMvc.perform(get("/api/device/{id}/key", deviceId).with(authentication(auth)))
                .andExpect(status().isOk())
                .andExpect(content().string("ENCRYPTED_KEY_DATA"));

        verify(deviceService).getEncryptedPrivateKey(deviceId, userId);
    }

    @Test
    void getEncryptedPrivateKey_notFound_returns400() throws Exception {
        UUID deviceId = UUID.randomUUID();
        when(deviceService.getEncryptedPrivateKey(deviceId, userId))
                .thenThrow(new IllegalArgumentException("Устройство не найдено"));

        mockMvc.perform(get("/api/device/{id}/key", deviceId).with(authentication(auth)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void getEncryptedPrivateKey_inactive_returns403() throws Exception {
        UUID deviceId = UUID.randomUUID();
        when(deviceService.getEncryptedPrivateKey(deviceId, userId))
                .thenThrow(new SecurityException("Устройство отключено"));

        mockMvc.perform(get("/api/device/{id}/key", deviceId).with(authentication(auth)))
                .andExpect(status().isForbidden());
    }

    

    @Test
    void updateDevice_returnsUpdatedDto() throws Exception {
        UUID deviceId = UUID.randomUUID();
        DeviceResponse resp = DeviceResponse.builder()
                .id(deviceId).deviceName("renamed").uniqueId("u1").isActive(true).build();
        when(deviceService.updateDevice(eq(deviceId), any(), eq(userId))).thenReturn(resp);

        String body = """
                {"deviceName":"renamed","isActive":true}
                """;

        mockMvc.perform(put("/api/device/{id}", deviceId)
                        .with(authentication(auth))
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.deviceName").value("renamed"))
                .andExpect(jsonPath("$.id").value(deviceId.toString()));
    }

    @Test
    void updateDevice_notFound_returns400() throws Exception {
        UUID deviceId = UUID.randomUUID();
        when(deviceService.updateDevice(eq(deviceId), any(), eq(userId)))
                .thenThrow(new IllegalArgumentException("Устройство не найдено"));

        String body = """
                {"deviceName":"x"}
                """;

        mockMvc.perform(put("/api/device/{id}", deviceId)
                        .with(authentication(auth))
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest());
    }

    @Test
    void updateDevice_emptyBody_ok() throws Exception {
        UUID deviceId = UUID.randomUUID();
        DeviceResponse resp = DeviceResponse.builder()
                .id(deviceId).deviceName("old").isActive(true).build();
        when(deviceService.updateDevice(eq(deviceId), any(), eq(userId))).thenReturn(resp);

        mockMvc.perform(put("/api/device/{id}", deviceId)
                        .with(authentication(auth))
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isOk());
    }

    

    @Test
    void deactivateDevice_returns200() throws Exception {
        UUID deviceId = UUID.randomUUID();

        mockMvc.perform(post("/api/device/{id}/deactivate", deviceId)
                        .with(authentication(auth)))
                .andExpect(status().isOk());

        verify(deviceService).deactivateDevice(deviceId, userId);
    }

    @Test
    void deactivateDevice_notFound_returns400() throws Exception {
        UUID deviceId = UUID.randomUUID();
        org.mockito.Mockito.doThrow(new IllegalArgumentException("Устройство не найдено"))
                .when(deviceService).deactivateDevice(deviceId, userId);

        mockMvc.perform(post("/api/device/{id}/deactivate", deviceId)
                        .with(authentication(auth)))
                .andExpect(status().isBadRequest());
    }

    

    @Test
    void deleteDevice_returns200() throws Exception {
        UUID deviceId = UUID.randomUUID();

        mockMvc.perform(delete("/api/device/{id}", deviceId)
                        .with(authentication(auth)))
                .andExpect(status().isOk());

        verify(deviceService).deleteDevice(deviceId, userId);
    }

    @Test
    void deleteDevice_notFound_returns400() throws Exception {
        UUID deviceId = UUID.randomUUID();
        org.mockito.Mockito.doThrow(new IllegalArgumentException("Устройство не найдено"))
                .when(deviceService).deleteDevice(deviceId, userId);

        mockMvc.perform(delete("/api/device/{id}", deviceId)
                        .with(authentication(auth)))
                .andExpect(status().isBadRequest());
    }
}
package com.efedotov.vaultly.controller;

import com.efedotov.vaultly.service.ServerKeyService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = ServerKeyController.class)
class ServerKeyControllerTest extends BaseControllerTest {

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    ServerKeyService serverKeyService;

    @Test
    void getServerPublicKey_returnsPem() throws Exception {
        when(serverKeyService.getPublicKeyPem())
                .thenReturn("-----BEGIN PUBLIC KEY-----\nABC\n-----END PUBLIC KEY-----");

        mockMvc.perform(get("/api/server-key/public"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("BEGIN PUBLIC KEY")));
    }

    @Test
    void getServerPublicKey_failure_returns500() throws Exception {
        when(serverKeyService.getPublicKeyPem())
                .thenThrow(new IllegalStateException("nope"));

        mockMvc.perform(get("/api/server-key/public"))
                .andExpect(status().isInternalServerError());
    }
}
package com.efedotov.vaultly.security;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.BadCredentialsException;

import static org.assertj.core.api.Assertions.assertThat;

class AdminAuthenticationEntryPointTest {

    private final AdminAuthenticationEntryPoint entryPoint = new AdminAuthenticationEntryPoint();

    @Test
    void commence_returns401WithJsonBody() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/admin/secret");
        MockHttpServletResponse response = new MockHttpServletResponse();

        entryPoint.commence(request, response, new BadCredentialsException("nope"));

        assertThat(response.getStatus()).isEqualTo(401);
        assertThat(response.getContentType()).isEqualTo("application/json");
        assertThat(response.getContentAsString()).contains("\"error\":\"UNAUTHORIZED\"");
        assertThat(response.getContentAsString()).contains("/api/admin/secret");
    }
}
package com.efedotov.vaultly.security;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.access.AccessDeniedException;

import static org.assertj.core.api.Assertions.assertThat;

class AdminAccessDeniedHandlerTest {

    private final AdminAccessDeniedHandler handler = new AdminAccessDeniedHandler();

    @Test
    void handle_returns403WithJsonBody() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/admin/secret");
        MockHttpServletResponse response = new MockHttpServletResponse();

        handler.handle(request, response, new AccessDeniedException("denied"));

        assertThat(response.getStatus()).isEqualTo(403);
        assertThat(response.getContentType()).isEqualTo("application/json");
        assertThat(response.getContentAsString()).contains("\"error\":\"FORBIDDEN\"");
        assertThat(response.getContentAsString()).contains("/api/admin/secret");
    }
}
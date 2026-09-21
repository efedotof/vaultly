package com.efedotov.vaultly.security;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class AdminAuthenticationEntryPoint implements AuthenticationEntryPoint {

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
            AuthenticationException authException) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");

        Map<String, String> errorDetails = new HashMap<>();
        errorDetails.put("message", "Требуется аутентификация");
        errorDetails.put("error", "UNAUTHORIZED");
        errorDetails.put("path", request.getRequestURI());

        new ObjectMapper().writeValue(response.getWriter(), errorDetails);
    }
}

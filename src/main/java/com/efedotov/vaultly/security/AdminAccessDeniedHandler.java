package com.efedotov.vaultly.security;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class AdminAccessDeniedHandler implements AccessDeniedHandler {

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response,
            AccessDeniedException accessDeniedException) throws IOException {
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType("application/json");

        Map<String, String> errorDetails = new HashMap<>();
        errorDetails.put("message", "Недостаточно прав для доступа к ресурсу");
        errorDetails.put("error", "FORBIDDEN");
        errorDetails.put("path", request.getRequestURI());

        new ObjectMapper().writeValue(response.getWriter(), errorDetails);
    }
}
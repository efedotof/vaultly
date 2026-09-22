package com.efedotov.vaultly.controller;

import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import com.efedotov.vaultly.service.SessionService;
import com.efedotov.vaultly.service.UserDetailsServiceImpl;

@AutoConfigureMockMvc(addFilters = false)
@Import(TestWebMvcConfig.class)
@TestPropertySource(properties = {
        "app.security.trust-forwarded-headers=false",
        "app.cors.allowed-origins=",
        "app.base-url=http://localhost:8085"
})
public abstract class BaseControllerTest {

    @MockitoBean
    protected SessionService sessionService;

    @MockitoBean
    protected UserDetailsServiceImpl userDetailsService;
}
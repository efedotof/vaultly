package com.efedotov.vaultly.security;

import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.model.UserSession;
import com.efedotov.vaultly.service.SessionService;
import com.efedotov.vaultly.service.UserDetailsServiceImpl;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SessionAuthFilterTest {

    @Mock
    SessionService sessionService;
    @Mock
    UserDetailsServiceImpl userDetailsService;

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private SessionAuthFilter filter() {
        return new SessionAuthFilter(sessionService, userDetailsService);
    }

    private UserSession session(UUID userId) {
        return UserSession.builder()
                .tokenHash("hash")
                .userId(userId)
                .createdAt(Instant.now())
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();
    }

    @Test
    void optionsRequest_skipsAuthentication() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("OPTIONS", "/api/files");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter().doFilter(request, response, chain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        assertThat(chain.getRequest()).isNotNull();
    }

    @Test
    void noAuthorizationHeader_passesThrough() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/files");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter().doFilter(request, response, chain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        assertThat(chain.getRequest()).isNotNull();
    }

    @Test
    void nonBearerAuthHeader_passesThrough() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/files");
        request.addHeader("Authorization", "Basic dXNlcjpwYXNz");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter().doFilter(request, response, chain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }

    @Test
    void invalidSession_passesThroughWithoutAuth() throws Exception {
        when(sessionService.findValidSession("tok")).thenReturn(Optional.empty());

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/files");
        request.addHeader("Authorization", "Bearer tok");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter().doFilter(request, response, chain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        assertThat(chain.getRequest()).isNotNull();
    }

    @Test
    void validSession_authenticated() throws Exception {
        UUID userId = UUID.randomUUID();
        UserSession s = session(userId);
        User user = User.builder().id(userId).username("alice").isActive(true).build();
        CustomUserDetails details = new CustomUserDetails(user);

        when(sessionService.findValidSession("tok")).thenReturn(Optional.of(s));
        when(userDetailsService.loadUserById(userId)).thenReturn(details);

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/files");
        request.addHeader("Authorization", "Bearer tok");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter().doFilter(request, response, chain);

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        assertThat(auth).isNotNull();
        assertThat(auth.getPrincipal()).isInstanceOf(CustomUserDetails.class);
        assertThat(((CustomUserDetails) auth.getPrincipal()).getUserId()).isEqualTo(userId);
        assertThat(auth.getAuthorities()).isEmpty();
    }

    @Test
    void validSessionButInactiveUser_notAuthenticated() throws Exception {
        UUID userId = UUID.randomUUID();
        UserSession s = session(userId);
        User user = User.builder().id(userId).username("alice").isActive(false).build();
        CustomUserDetails details = new CustomUserDetails(user);

        when(sessionService.findValidSession("tok")).thenReturn(Optional.of(s));
        when(userDetailsService.loadUserById(userId)).thenReturn(details);

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/files");
        request.addHeader("Authorization", "Bearer tok");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter().doFilter(request, response, chain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        assertThat(chain.getRequest()).isNotNull();
    }

    @Test
    void validSessionButUserMissing_deletesSession() throws Exception {
        UUID userId = UUID.randomUUID();
        UserSession s = session(userId);

        when(sessionService.findValidSession("tok")).thenReturn(Optional.of(s));
        when(userDetailsService.loadUserById(userId))
                .thenThrow(new UsernameNotFoundException("gone"));

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/files");
        request.addHeader("Authorization", "Bearer tok");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter().doFilter(request, response, chain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verify(sessionService).deleteSession("tok");
        assertThat(chain.getRequest()).isNotNull();
    }

    @Test
    void bearerWithEmptyToken_isTreatedAsToken() throws Exception {
        
        
        when(sessionService.findValidSession("")).thenReturn(Optional.empty());

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/files");
        request.addHeader("Authorization", "Bearer ");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter().doFilter(request, response, chain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verify(sessionService).findValidSession("");
    }

    @Test
    void optionsRequest_doesNotTouchSessionService() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("OPTIONS", "/api/files");
        request.addHeader("Authorization", "Bearer tok");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter().doFilter(request, response, chain);

        verify(sessionService, never()).findValidSession(anyString());
    }
}
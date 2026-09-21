package com.efedotov.vaultly.security;

import java.io.IOException;
import java.util.Optional;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import com.efedotov.vaultly.model.UserSession;
import com.efedotov.vaultly.service.SessionService;
import com.efedotov.vaultly.service.UserDetailsServiceImpl;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
@RequiredArgsConstructor
public class SessionAuthFilter extends OncePerRequestFilter {

    private final SessionService sessionService;
    private final UserDetailsServiceImpl userDetailsService;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        String method = request.getMethod();
        String uri = request.getRequestURI();

        log.debug("Processing request: {} {}", method, uri);

        if ("OPTIONS".equalsIgnoreCase(method)) {
            log.debug("Skipping authentication for OPTIONS request: {}", uri);
            filterChain.doFilter(request, response);
            return;
        }

        String authHeader = request.getHeader("Authorization");
        if (StringUtils.hasText(authHeader) && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            log.debug("Found Bearer token, length: {}", token.length());

            Optional<UserSession> sessionOpt = sessionService.findValidSession(token);

            if (sessionOpt.isPresent()) {
                UserSession session = sessionOpt.get();
                try {
                    var userDetails = userDetailsService.loadUserById(session.getUserId());

                    if (!userDetails.isEnabled()) {
                        log.warn("Inactive user {} tried to authenticate with valid session",
                                session.getUserId());
                        filterChain.doFilter(request, response);
                        return;
                    }

                    log.debug("Authenticated user: {} for request: {} {}",
                            userDetails.getUsername(), method, uri);

                    var auth = new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities());
                    auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(auth);

                } catch (UsernameNotFoundException e) {
                    log.warn("Session references missing user {}: {}",
                            session.getUserId(), e.getMessage());
                    sessionService.deleteSession(token);

                }
            } else {
                log.warn("Invalid session token for request: {} {}", method, uri);
            }
        } else {
            log.debug("No Bearer token found in Authorization header for request: {} {}", method, uri);
        }

        filterChain.doFilter(request, response);
    }
}
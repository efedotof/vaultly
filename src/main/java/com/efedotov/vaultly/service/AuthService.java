package com.efedotov.vaultly.service;

import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.efedotov.vaultly.dto.auth.AuthResponse;
import com.efedotov.vaultly.dto.auth.LoginRequest;
import com.efedotov.vaultly.dto.auth.RegisterRequest;
import com.efedotov.vaultly.model.Role;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.model.UserSession;
import com.efedotov.vaultly.repository.RoleRepository;
import com.efedotov.vaultly.repository.UserRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepository userRepository;
    private final SessionService sessionService;
    private final PasswordEncoder passwordEncoder;
    private final RoleRepository roleRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Transactional
    public AuthResponse login(LoginRequest request) {
        log.info("Login attempt for username: {}", request.getUsername());

        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new RuntimeException("Invalid password");
        }

        if (!user.getIsActive()) {
            throw new RuntimeException("User account is disabled");
        }

        UserSession session = sessionService.createSession(user.getId());

        return createAuthResponse(user, session.getToken());
    }

    @Transactional
    public AuthResponse registration(RegisterRequest request) {
        log.info("Registration attempt for username: {}", request.getUsername());

        if (userRepository.findByUsername(request.getUsername()).isPresent()) {
            throw new RuntimeException("Username already exists");
        }

        Role userRole = roleRepository.findByRoleName("USER")
                .orElseGet(() -> {
                    Role newRole = new Role();
                    newRole.setRoleName("USER");
                    return roleRepository.save(newRole);
                });

        String normalizedPrivateKey = normalizePrivateKeyEncrypted(request.getPrivateKeyEncrypted());
        String normalizedSalt = normalizeBase64String(request.getSalt());

        User user = User.builder()
                .username(request.getUsername())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .publicKey(request.getPublicKey())
                .privateKeyEncrypted(normalizedPrivateKey)
                .salt(normalizedSalt)
                .roles(new HashSet<>(Set.of(userRole)))
                .build();

        user = userRepository.save(user);
        log.info("User created with ID: {}", user.getId());

        UserSession session = sessionService.createSession(user.getId());

        return createAuthResponse(user, session.getToken());
    }

    private String normalizePrivateKeyEncrypted(String raw) {
        if (raw == null)
            return null;
        String cleaned = raw.trim();
        cleaned = cleaned.replaceFirst("^\uFEFF", "");
        while ((cleaned.startsWith("\"") && cleaned.endsWith("\"")) ||
                (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
            cleaned = cleaned.substring(1, cleaned.length() - 1).trim();
        }
        cleaned = cleaned.replace("\\\"", "\"");
        cleaned = cleaned.replaceAll("[\\x00-\\x1F\\x7F]", "");
        try {
            Object json = objectMapper.readValue(cleaned, Object.class);
            return objectMapper.writeValueAsString(json);
        } catch (JacksonException e) {
            log.warn("Failed to parse privateKeyEncrypted as JSON, storing as is: {}", e.getMessage());
            return cleaned;
        }
    }

    private String normalizeBase64String(String raw) {
        if (raw == null)
            return null;
        return raw.trim().replaceAll("[^A-Za-z0-9+/=]", "");
    }

    @Transactional(readOnly = true)
    public AuthResponse validateToken(String token) {
        log.debug("Validating token");

        Optional<UserSession> sessionOpt = sessionService.findValidSession(token);

        if (sessionOpt.isEmpty()) {
            throw new RuntimeException("Invalid or expired token");
        }

        UserSession session = sessionOpt.get();
        User user = userRepository.findById(session.getUserId())
                .orElseThrow(() -> new RuntimeException("User not found"));

        return createAuthResponse(user, token);
    }

    @Transactional
    public void logout(String token) {
        log.info("Logout for token");
        sessionService.deleteSession(token);
    }

    private AuthResponse createAuthResponse(User user, String accessToken) {
        AuthResponse response = new AuthResponse();
        response.setAccessToken(accessToken);
        response.setRefreshToken(null);
        response.setUserId(user.getId());
        response.setEmail(user.getEmail());
        response.setUsername(user.getUsername());
        response.setStorageUsed(user.getStorageUsed());
        response.setStorageLimit(user.getStorageLimit());

        Set<String> roles = user.getRoles().stream()
                .map(Role::getRoleName)
                .collect(Collectors.toSet());
        response.setRoles(roles);

        return response;
    }

}
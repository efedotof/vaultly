package com.efedotov.vaultly.service;

import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.efedotov.vaultly.dto.user.RecoveryDataResponse;
import com.efedotov.vaultly.dto.user.UpdateKeysRequest;
import com.efedotov.vaultly.dto.user.UpdateRecoveryKeysRequest;
import com.efedotov.vaultly.dto.user.UpdateUserRequest;
import com.efedotov.vaultly.dto.user.UserProfileDto;
import com.efedotov.vaultly.exception.ResourceNotFoundException;
import com.efedotov.vaultly.exception.UsernameAlreadyExistsException;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.UserRepository;
import com.fasterxml.jackson.core.JacksonException;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserService {
    private final PasswordEncoder passwordEncoder;
    private final UserRepository userRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public User getUserById(UUID id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));
    }

    @Transactional
    public UserProfileDto updateUser(UUID userId, UpdateUserRequest request) {
        User user = getUserById(userId);

        if (request.getUsername() != null && !request.getUsername().equals(user.getUsername())) {
            if (userRepository.existsByUsername(request.getUsername())) {
                throw new UsernameAlreadyExistsException("Username '" + request.getUsername() + "' is already taken");
            }
            user.setUsername(request.getUsername());
        }

        if (request.getFirstName() != null) {
            user.setFirstName(request.getFirstName());
        }
        if (request.getLastName() != null) {
            user.setLastName(request.getLastName());
        }

        User updatedUser = userRepository.save(user);
        return mapToUserProfileDto(updatedUser);
    }

    public UserProfileDto getUserProfile(UUID userId) {
        User user = getUserById(userId);
        return mapToUserProfileDto(user);
    }

    public String getEncryptedPrivateKey(UUID userId) {
        User user = getUserById(userId);
        return user.getPrivateKeyEncrypted();
    }

    public String getSalt(UUID userId) {
        User user = getUserById(userId);
        return user.getSalt();
    }

    @Transactional
    public void updateRecoveryKeys(UUID userId, UpdateRecoveryKeysRequest request) {
        User user = getUserById(userId);

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new RuntimeException("Invalid password");
        }

        user.setRecoveryPublicKey(request.getRecoveryPublicKey());
        user.setRecoveryPrivateKeyEncrypted(normalizePrivateKeyEncrypted(request.getRecoveryPrivateKeyEncrypted()));
        user.setRecoveryEncryptedRsaKey(request.getRecoveryEncryptedRsaKey());
        userRepository.save(user);
        log.info("User {} updated recovery keys", user.getUsername());
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

    public RecoveryDataResponse getRecoveryData(UUID userId) {
        User user = getUserById(userId);
        return new RecoveryDataResponse(user.getRecoveryEncryptedRsaKey(), user.getSalt());
    }

    @Transactional
    public void updateKeys(UUID userId, UpdateKeysRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new RuntimeException("Invalid password");
        }
        user.setPublicKey(request.getPublicKey());
        user.setPrivateKeyEncrypted(normalizePrivateKeyEncrypted(request.getPrivateKeyEncrypted()));
        userRepository.save(user);

        log.info("User {} updated keys", user.getUsername());
    }

    private UserProfileDto mapToUserProfileDto(User user) {
        UserProfileDto dto = new UserProfileDto();
        dto.setId(user.getId());
        dto.setEmail(user.getEmail());
        dto.setUsername(user.getUsername());
        dto.setFirstName(user.getFirstName());
        dto.setLastName(user.getLastName());
        dto.setAvatarUrl(user.getAvatarUrl());
        dto.setStorageUsed(user.getStorageUsed());
        dto.setStorageLimit(user.getStorageLimit());
        dto.setPublicKey(user.getPublicKey());
        dto.setTotpEnabled(user.getTotpEnabled());
        return dto;
    }
}
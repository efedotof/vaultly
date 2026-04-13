package com.efedotov.vaultly.service;

import java.util.UUID;

import org.springframework.stereotype.Service;

import com.efedotov.vaultly.dto.user.UpdateUserRequest;
import com.efedotov.vaultly.dto.user.UserProfileDto;
import com.efedotov.vaultly.exception.ResourceNotFoundException;
import com.efedotov.vaultly.exception.UsernameAlreadyExistsException;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.UserRepository;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

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
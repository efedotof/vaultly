package com.efedotov.vaultly.controller;

import java.util.Map;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.efedotov.vaultly.dto.user.RecoveryDataResponse;
import com.efedotov.vaultly.dto.user.UpdateKeysRequest;
import com.efedotov.vaultly.dto.user.UpdateRecoveryKeysRequest;
import com.efedotov.vaultly.dto.user.UpdateUserRequest;
import com.efedotov.vaultly.dto.user.UserProfileDto;
import com.efedotov.vaultly.exception.BadRequestException;
import com.efedotov.vaultly.exception.UsernameAlreadyExistsException;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.UserService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    public ResponseEntity<UserProfileDto> getCurrentUserProfile(
            @AuthenticationPrincipal CustomUserDetails currentUser) {
        UserProfileDto profile = userService.getUserProfile(currentUser.getUserId());
        return ResponseEntity.ok(profile);
    }

    @PutMapping("/me")
    public ResponseEntity<?> updateCurrentUser(
            @Valid @RequestBody UpdateUserRequest request,
            @AuthenticationPrincipal CustomUserDetails currentUser) {
        try {
            UserProfileDto updatedProfile = userService.updateUser(currentUser.getUserId(), request);
            return ResponseEntity.ok(updatedProfile);
        } catch (UsernameAlreadyExistsException e) {
            log.warn("Username conflict on update by user {}: {}",
                    currentUser.getUserId(), e.getMessage());
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of(
                            "error", "username_exists",
                            "message", e.getMessage() != null ? e.getMessage() : "Username already exists"));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserProfileDto> getUserProfileById(@PathVariable UUID id) {
        UserProfileDto profile = userService.getUserProfile(id);
        UserProfileDto publicView = new UserProfileDto();
        publicView.setId(profile.getId());
        publicView.setUsername(profile.getUsername());
        publicView.setFirstName(profile.getFirstName());
        publicView.setLastName(profile.getLastName());
        publicView.setAvatarUrl(profile.getAvatarUrl());
        publicView.setPublicKey(profile.getPublicKey());
        return ResponseEntity.ok(publicView);
    }

    @PostMapping("/keys/recovery/update")
    public ResponseEntity<?> updateRecoveryKeys(
            @AuthenticationPrincipal CustomUserDetails user,
            @Valid @RequestBody UpdateRecoveryKeysRequest request) {
        try {
            userService.updateRecoveryKeys(user.getUserId(), request);
            return ResponseEntity.ok().build();
        } catch (BadRequestException e) {
            log.warn("Invalid recovery public key for user {}: {}",
                    user.getUserId(), e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "error", "invalid_public_key",
                            "message", e.getMessage() != null ? e.getMessage() : "Invalid public key"));
        } catch (RuntimeException e) {
            if ("Invalid password".equals(e.getMessage())) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "invalid_password"));
            }
            throw e;
        }
    }

    @GetMapping("/me/recovery-data")
    public ResponseEntity<RecoveryDataResponse> getRecoveryData(
            @AuthenticationPrincipal CustomUserDetails user) {
        RecoveryDataResponse response = userService.getRecoveryData(user.getUserId());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/keys/update")
    public ResponseEntity<?> updateKeys(
            @AuthenticationPrincipal CustomUserDetails user,
            @Valid @RequestBody UpdateKeysRequest request) {
        try {
            userService.updateKeys(user.getUserId(), request);
            return ResponseEntity.ok().build();
        } catch (BadRequestException e) {
            log.warn("Invalid public key for user {}: {}", user.getUserId(), e.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "error", "invalid_public_key",
                            "message", e.getMessage() != null ? e.getMessage() : "Invalid public key"));
        } catch (RuntimeException e) {
            if ("Invalid password".equals(e.getMessage())) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "invalid_password"));
            }
            throw e;
        }
    }
}
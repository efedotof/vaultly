package com.efedotov.vaultly.controller;

import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.efedotov.vaultly.dto.user.UpdateUserRequest;
import com.efedotov.vaultly.dto.user.UserProfileDto;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.UserService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @GetMapping("/me")
    public ResponseEntity<UserProfileDto> getCurrentUserProfile(@AuthenticationPrincipal UserDetails currentUser) {
        UUID userId = extractUserIdFromPrincipal(currentUser);
        UserProfileDto profile = userService.getUserProfile(userId);
        return ResponseEntity.ok(profile);
    }

    @GetMapping("/me/private-key-encrypted")
    public ResponseEntity<String> getEncryptedPrivateKey(@AuthenticationPrincipal CustomUserDetails user) {
        String raw = userService.getEncryptedPrivateKey(user.getUserId());
        try {
            JsonNode node = objectMapper.readTree(raw);
            String cleanJson = objectMapper.writeValueAsString(node);
            return ResponseEntity.ok(cleanJson);
        } catch (JacksonException e) {
            return ResponseEntity.ok(raw);
        }
    }

    @PutMapping("/me")
    public ResponseEntity<UserProfileDto> updateCurrentUser(
            @Valid @RequestBody UpdateUserRequest request,
            @AuthenticationPrincipal UserDetails currentUser) {
        UUID userId = extractUserIdFromPrincipal(currentUser);
        UserProfileDto updatedProfile = userService.updateUser(userId, request);
        return ResponseEntity.ok(updatedProfile);
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserProfileDto> getUserProfileById(@PathVariable UUID id,
            @AuthenticationPrincipal UserDetails currentUser) {
        UserProfileDto profile = userService.getUserProfile(id);
        return ResponseEntity.ok(profile);
    }

    private UUID extractUserIdFromPrincipal(UserDetails principal) {
        return ((CustomUserDetails) principal).getUserId();
    }

    @GetMapping("/me/salt")
    public ResponseEntity<String> getSalt(@AuthenticationPrincipal CustomUserDetails user) {
        String salt = userService.getSalt(user.getUserId());
        return ResponseEntity.ok(salt);
    }

}
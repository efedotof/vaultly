package com.efedotov.vaultly.service;

import java.util.Optional;
import java.util.UUID;

import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.UserRepository;
import com.efedotov.vaultly.security.CustomUserDetails;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));
        return new CustomUserDetails(user);
    }

    public UserDetails loadUserById(UUID userId) {
        log.info("Loading user by ID: {}", userId);
        Optional<User> userOpt = userRepository.findById(userId);

        if (!userOpt.isPresent()) {
            log.error("User not found by ID: {}", userId);
            throw new UsernameNotFoundException("User not found by id");
        }

        User user = userOpt.get();
        log.info("User found: {} ({})", user.getUsername(), user.getId());

        return new CustomUserDetails(user);
    }
}
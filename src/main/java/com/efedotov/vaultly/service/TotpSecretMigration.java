package com.efedotov.vaultly.service;

import java.util.List;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.UserRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class TotpSecretMigration implements ApplicationRunner {

    private final UserRepository userRepository;
    private final EncryptionService encryptionService;

    @Override
    public void run(ApplicationArguments args) {
        List<User> users = userRepository.findAllByTotpSecretIsNotNull();
        for (User user : users) {
            String secret = user.getTotpSecret();
            if (secret != null && !secret.contains(":")) {
                log.info("Encrypting TOTP secret for user {}", user.getId());
                user.setTotpSecret(encryptionService.encrypt(secret));
                userRepository.save(user);
            }
        }
    }
}
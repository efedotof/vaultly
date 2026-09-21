package com.efedotov.vaultly.service;

import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TotpSecretMigrationTest {

    @Mock
    UserRepository userRepository;
    @Mock
    EncryptionService encryptionService;

    @InjectMocks
    TotpSecretMigration migration;

    @Test
    void run_plainSecret_encrypts() {
        User user = User.builder().id(UUID.randomUUID()).totpSecret("PLAIN").build();
        when(userRepository.findAllByTotpSecretIsNotNull()).thenReturn(List.of(user));
        when(encryptionService.encrypt("PLAIN")).thenReturn("ivB64:ctB64");

        migration.run(null);

        verify(encryptionService).encrypt("PLAIN");
        verify(userRepository).save(user);
    }

    @Test
    void run_alreadyEncrypted_skips() {
        User user = User.builder().id(UUID.randomUUID()).totpSecret("ivB64:ctB64").build();
        when(userRepository.findAllByTotpSecretIsNotNull()).thenReturn(List.of(user));

        migration.run(null);

        verify(encryptionService, never()).encrypt(org.mockito.ArgumentMatchers.anyString());
        verify(userRepository, never()).save(org.mockito.ArgumentMatchers.any());
    }

    @Test
    void run_nullSecret_skips() {
        User user = User.builder().id(UUID.randomUUID()).totpSecret(null).build();
        when(userRepository.findAllByTotpSecretIsNotNull()).thenReturn(List.of(user));

        migration.run(null);

        verify(encryptionService, never()).encrypt(org.mockito.ArgumentMatchers.anyString());
        verify(userRepository, never()).save(org.mockito.ArgumentMatchers.any());
    }

    @Test
    void run_mixed_migratesOnlyPlain() {
        User plain = User.builder().id(UUID.randomUUID()).totpSecret("PLAIN").build();
        User encrypted = User.builder().id(UUID.randomUUID()).totpSecret("a:b").build();
        when(userRepository.findAllByTotpSecretIsNotNull()).thenReturn(List.of(plain, encrypted));
        when(encryptionService.encrypt("PLAIN")).thenReturn("x:y");

        migration.run(null);

        verify(encryptionService, times(1)).encrypt("PLAIN");
        verify(userRepository, times(1)).save(plain);
    }
}
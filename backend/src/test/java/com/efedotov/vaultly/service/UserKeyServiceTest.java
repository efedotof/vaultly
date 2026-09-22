package com.efedotov.vaultly.service;

import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PublicKey;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserKeyServiceTest {

    @Mock
    UserRepository userRepository;
    @InjectMocks
    UserKeyService service;

    private String validPem;
    private PublicKey expectedKey;

    @BeforeEach
    void setUp() throws Exception {
        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(2048);
        KeyPair kp = kpg.generateKeyPair();
        expectedKey = kp.getPublic();
        validPem = "-----BEGIN PUBLIC KEY-----\n"
                + Base64.getMimeEncoder().encodeToString(expectedKey.getEncoded())
                + "\n-----END PUBLIC KEY-----";
    }

    @Test
    void init_loadsValidKeysIntoCache() {
        UUID id = UUID.randomUUID();
        User user = User.builder().id(id).username("alice").publicKey(validPem).build();
        when(userRepository.findAll()).thenReturn(List.of(user));

        service.init();

        assertThat(service.getPublicKey(id)).isEqualTo(expectedKey);
    }

    @Test
    void init_skipsBlankKeys() {
        UUID blankId = UUID.randomUUID();
        UUID nullId = UUID.randomUUID();
        User blank = User.builder().id(blankId).publicKey("").build();
        User nullKey = User.builder().id(nullId).publicKey(null).build();

        when(userRepository.findAll()).thenReturn(List.of(blank, nullKey));

        service.init();

        when(userRepository.findById(blankId)).thenReturn(Optional.of(blank));
        assertThatThrownBy(() -> service.getPublicKey(blankId))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Public key not found");
    }

    @Test
    void init_skipsInvalidKeys() {
        UUID id = UUID.randomUUID();
        User bad = User.builder().id(id).publicKey("not-a-valid-pem").build();
        when(userRepository.findAll()).thenReturn(List.of(bad));

        service.init();

        when(userRepository.findById(id)).thenReturn(Optional.of(bad));
        assertThatThrownBy(() -> service.getPublicKey(id))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Invalid public key format");
    }

    @Test
    void getPublicKey_returnsCachedInstance() {
        UUID id = UUID.randomUUID();
        User user = User.builder().id(id).publicKey(validPem).build();
        when(userRepository.findAll()).thenReturn(List.of(user));
        service.init();

        PublicKey first = service.getPublicKey(id);
        PublicKey second = service.getPublicKey(id);

        assertThat(first).isSameAs(second);
    }

    @Test
    void getPublicKey_loadsFromRepositoryOnCacheMiss() {
        UUID id = UUID.randomUUID();
        User user = User.builder().id(id).publicKey(validPem).build();
        when(userRepository.findById(id)).thenReturn(Optional.of(user));

        PublicKey key = service.getPublicKey(id);

        assertThat(key).isEqualTo(expectedKey);
    }

    @Test
    void getPublicKey_userNotFound_throws() {
        UUID id = UUID.randomUUID();
        when(userRepository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getPublicKey(id))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("User not found");
    }

    @Test
    void getPublicKey_blankKeyInDb_throws() {
        UUID id = UUID.randomUUID();
        User user = User.builder().id(id).publicKey("").build();
        when(userRepository.findById(id)).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> service.getPublicKey(id))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Public key not found");
    }

    @Test
    void getPublicKey_invalidPem_throws() {
        UUID id = UUID.randomUUID();
        User user = User.builder().id(id).publicKey("garbage").build();
        when(userRepository.findById(id)).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> service.getPublicKey(id))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Invalid public key format");
    }

    @Test
    void invalidate_removesEntryFromCache() {
        UUID id = UUID.randomUUID();
        User user = User.builder().id(id).publicKey(validPem).build();
        when(userRepository.findAll()).thenReturn(List.of(user));
        service.init();

        service.invalidate(id);

        when(userRepository.findById(id)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.getPublicKey(id))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void invalidate_null_isNoop() {
        service.invalidate(null);
    }
}
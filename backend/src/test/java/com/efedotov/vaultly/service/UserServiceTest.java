package com.efedotov.vaultly.service;

import com.efedotov.vaultly.dto.user.RecoveryDataResponse;
import com.efedotov.vaultly.dto.user.UpdateKeysRequest;
import com.efedotov.vaultly.dto.user.UpdateRecoveryKeysRequest;
import com.efedotov.vaultly.dto.user.UpdateUserRequest;
import com.efedotov.vaultly.dto.user.UserProfileDto;
import com.efedotov.vaultly.exception.BadRequestException;
import com.efedotov.vaultly.exception.NotFoundException;
import com.efedotov.vaultly.exception.UsernameAlreadyExistsException;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.util.Base64;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    PasswordEncoder passwordEncoder;
    @Mock
    UserRepository userRepository;
    @Mock
    UserKeyService userKeyService;

    @InjectMocks
    UserService service;

    private String validPem;

    @BeforeEach
    void setUp() throws Exception {
        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(2048);
        KeyPair kp = kpg.generateKeyPair();
        validPem = "-----BEGIN PUBLIC KEY-----\n"
                + Base64.getMimeEncoder().encodeToString(kp.getPublic().getEncoded())
                + "\n-----END PUBLIC KEY-----";
    }

    @Test
    void getUserById_notFound_throws() {
        UUID id = UUID.randomUUID();
        when(userRepository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getUserById(id))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void getUserById_found_returns() {
        UUID id = UUID.randomUUID();
        User u = User.builder().id(id).username("alice").build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));

        assertThat(service.getUserById(id)).isSameAs(u);
    }

    @Test
    void getUserProfile_returnsFullDto() {
        UUID id = UUID.randomUUID();
        User u = User.builder()
                .id(id).username("alice")
                .firstName("Alice").lastName("Liddell")
                .email("alice@example.com").avatarUrl("https://a")
                .storageUsed(5L).storageLimit(100L)
                .publicKey(validPem).totpEnabled(true)
                .build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));

        UserProfileDto dto = service.getUserProfile(id);

        assertThat(dto.getId()).isEqualTo(id);
        assertThat(dto.getUsername()).isEqualTo("alice");
        assertThat(dto.getFirstName()).isEqualTo("Alice");
        assertThat(dto.getLastName()).isEqualTo("Liddell");
        assertThat(dto.getEmail()).isEqualTo("alice@example.com");
        assertThat(dto.getAvatarUrl()).isEqualTo("https://a");
        assertThat(dto.getStorageUsed()).isEqualTo(5L);
        assertThat(dto.getStorageLimit()).isEqualTo(100L);
        assertThat(dto.getPublicKey()).isEqualTo(validPem);
        assertThat(dto.getTotpEnabled()).isTrue();
    }

    @Test
    void getEncryptedPrivateKey_returnsValue() {
        UUID id = UUID.randomUUID();
        User u = User.builder().id(id).privateKeyEncrypted("enc").build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));

        assertThat(service.getEncryptedPrivateKey(id)).isEqualTo("enc");
    }

    @Test
    void getSalt_returnsValue() {
        UUID id = UUID.randomUUID();
        User u = User.builder().id(id).salt("somesalt").build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));

        assertThat(service.getSalt(id)).isEqualTo("somesalt");
    }

    @Test
    void getRecoveryData_returnsBothFields() {
        UUID id = UUID.randomUUID();
        User u = User.builder()
                .id(id)
                .recoveryEncryptedRsaKey("rsa-blob")
                .salt("salt-val")
                .build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));

        RecoveryDataResponse resp = service.getRecoveryData(id);

        assertThat(resp.getRecoveryEncryptedRsaKey()).isEqualTo("rsa-blob");
        assertThat(resp.getSalt()).isEqualTo("salt-val");
    }

    @Test
    void updateUser_usernameTaken_throws() {
        UUID id = UUID.randomUUID();
        User u = User.builder().id(id).username("alice").build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));
        when(userRepository.existsByUsername("bob")).thenReturn(true);

        UpdateUserRequest req = new UpdateUserRequest();
        req.setUsername("bob");

        assertThatThrownBy(() -> service.updateUser(id, req))
                .isInstanceOf(UsernameAlreadyExistsException.class);
    }

    @Test
    void updateUser_success_changesAllFields() {
        UUID id = UUID.randomUUID();
        User u = User.builder().id(id).username("alice")
                .storageUsed(0L).storageLimit(100L).build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));
        when(userRepository.existsByUsername("bob")).thenReturn(false);
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        UpdateUserRequest req = new UpdateUserRequest();
        req.setUsername("bob");
        req.setFirstName("Bob");
        req.setLastName("Marley");

        UserProfileDto dto = service.updateUser(id, req);

        assertThat(dto.getUsername()).isEqualTo("bob");
        assertThat(dto.getFirstName()).isEqualTo("Bob");
        assertThat(dto.getLastName()).isEqualTo("Marley");
    }

    @Test
    void updateUser_sameUsername_skipsAvailabilityCheck() {
        UUID id = UUID.randomUUID();
        User u = User.builder().id(id).username("alice")
                .storageUsed(0L).storageLimit(100L).build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        UpdateUserRequest req = new UpdateUserRequest();
        req.setUsername("alice");

        service.updateUser(id, req);

        verify(userRepository, never()).existsByUsername(any());
    }

    @Test
    void updateUser_onlyLastName_leavesUsernameUntouched() {
        UUID id = UUID.randomUUID();
        User u = User.builder().id(id).username("alice")
                .storageUsed(0L).storageLimit(100L).build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        UpdateUserRequest req = new UpdateUserRequest();
        req.setLastName("Smith");

        UserProfileDto dto = service.updateUser(id, req);

        assertThat(dto.getUsername()).isEqualTo("alice");
        assertThat(dto.getLastName()).isEqualTo("Smith");
    }

    @Test
    void updateKeys_userNotFound_throws() {
        UUID id = UUID.randomUUID();
        when(userRepository.findById(id)).thenReturn(Optional.empty());

        UpdateKeysRequest req = new UpdateKeysRequest();
        req.setCurrentPassword("pw");
        req.setPublicKey(validPem);
        req.setPrivateKeyEncrypted("enc");

        assertThatThrownBy(() -> service.updateKeys(id, req))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void updateKeys_wrongPassword_throws() {
        UUID id = UUID.randomUUID();
        User u = User.builder().id(id).passwordHash("hash").build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("bad", "hash")).thenReturn(false);

        UpdateKeysRequest req = new UpdateKeysRequest();
        req.setCurrentPassword("bad");
        req.setPublicKey(validPem);
        req.setPrivateKeyEncrypted("enc");

        assertThatThrownBy(() -> service.updateKeys(id, req))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Invalid password");
    }

    @Test
    void updateKeys_invalidPublicKey_throws() {
        UUID id = UUID.randomUUID();
        User u = User.builder().id(id).passwordHash("hash").build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("pw", "hash")).thenReturn(true);

        UpdateKeysRequest req = new UpdateKeysRequest();
        req.setCurrentPassword("pw");
        req.setPublicKey("not-a-valid-key");
        req.setPrivateKeyEncrypted("enc");

        assertThatThrownBy(() -> service.updateKeys(id, req))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void updateKeys_success_savesAndInvalidatesCache() {
        UUID id = UUID.randomUUID();
        User u = User.builder().id(id).username("alice").passwordHash("hash").build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("pw", "hash")).thenReturn(true);
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        UpdateKeysRequest req = new UpdateKeysRequest();
        req.setCurrentPassword("pw");
        req.setPublicKey(validPem);
        req.setPrivateKeyEncrypted("some-private-key-blob");

        service.updateKeys(id, req);

        assertThat(u.getPublicKey()).isEqualTo(validPem);
        assertThat(u.getPrivateKeyEncrypted()).isEqualTo("some-private-key-blob");
        verify(userKeyService).invalidate(id);
    }

    @Test
    void updateKeys_nullPrivateKey_storesNull() {
        UUID id = UUID.randomUUID();
        User u = User.builder().id(id).passwordHash("hash").build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("pw", "hash")).thenReturn(true);
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        UpdateKeysRequest req = new UpdateKeysRequest();
        req.setCurrentPassword("pw");
        req.setPublicKey(validPem);
        req.setPrivateKeyEncrypted(null);

        service.updateKeys(id, req);

        assertThat(u.getPrivateKeyEncrypted()).isNull();
    }

    @Test
    void updateKeys_jsonPrivateKey_isNormalized() {
        UUID id = UUID.randomUUID();
        User u = User.builder().id(id).passwordHash("hash").build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("pw", "hash")).thenReturn(true);
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        UpdateKeysRequest req = new UpdateKeysRequest();
        req.setCurrentPassword("pw");
        req.setPublicKey(validPem);
        req.setPrivateKeyEncrypted("  \"{\\\"k\\\":\\\"v\\\"}\"  ");

        service.updateKeys(id, req);

        assertThat(u.getPrivateKeyEncrypted()).contains("k").contains("v");
    }

    @Test
    void updateRecoveryKeys_wrongPassword_throws() {
        UUID id = UUID.randomUUID();
        User u = User.builder().id(id).passwordHash("hash").build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("bad", "hash")).thenReturn(false);

        UpdateRecoveryKeysRequest req = new UpdateRecoveryKeysRequest();
        req.setCurrentPassword("bad");
        req.setRecoveryPublicKey(validPem);
        req.setRecoveryPrivateKeyEncrypted("priv");
        req.setRecoveryEncryptedRsaKey("rsa");

        assertThatThrownBy(() -> service.updateRecoveryKeys(id, req))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Invalid password");
    }

    @Test
    void updateRecoveryKeys_success() {
        UUID id = UUID.randomUUID();
        User u = User.builder().id(id).username("alice").passwordHash("hash").build();
        when(userRepository.findById(id)).thenReturn(Optional.of(u));
        when(passwordEncoder.matches("pw", "hash")).thenReturn(true);
        when(userRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        UpdateRecoveryKeysRequest req = new UpdateRecoveryKeysRequest();
        req.setCurrentPassword("pw");
        req.setRecoveryPublicKey(validPem);
        req.setRecoveryPrivateKeyEncrypted("recovery-priv");
        req.setRecoveryEncryptedRsaKey("rsa-blob");

        service.updateRecoveryKeys(id, req);

        assertThat(u.getRecoveryPublicKey()).isNotBlank();
        assertThat(u.getRecoveryEncryptedRsaKey()).isEqualTo("rsa-blob");
        assertThat(u.getRecoveryPrivateKeyEncrypted()).isNotBlank();
    }

    @Test
    void validatePublicKeyFormat_null_throws() {
        assertThatThrownBy(() -> UserService.validatePublicKeyFormat(null))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void validatePublicKeyFormat_blank_throws() {
        assertThatThrownBy(() -> UserService.validatePublicKeyFormat("   "))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void validatePublicKeyFormat_tooLong_throws() {
        String tooLong = "A".repeat(10_001);
        assertThatThrownBy(() -> UserService.validatePublicKeyFormat(tooLong))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("too long");
    }

    @Test
    void validatePublicKeyFormat_validRsa_passes() {
        UserService.validatePublicKeyFormat(validPem);
    }

    @Test
    void validatePublicKeyFormat_garbage_throws() {
        assertThatThrownBy(() -> UserService.validatePublicKeyFormat("not-a-key"))
                .isInstanceOf(BadRequestException.class);
    }
}
package com.efedotov.vaultly.service;

import com.efedotov.vaultly.dto.device.DeviceRegisterRequest;
import com.efedotov.vaultly.dto.device.DeviceResponse;
import com.efedotov.vaultly.dto.device.DeviceUpdateRequest;
import com.efedotov.vaultly.model.Device;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.DeviceRepository;
import com.efedotov.vaultly.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DeviceServiceTest {

    @Mock
    DeviceRepository deviceRepository;
    @Mock
    UserRepository userRepository;
    @InjectMocks
    DeviceService service;

    @Test
    void registerDevice_new_saves() {
        UUID userId = UUID.randomUUID();
        when(deviceRepository.findByUniqueId("uid")).thenReturn(Optional.empty());
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        DeviceRegisterRequest req = new DeviceRegisterRequest();
        req.setDeviceName("laptop");
        req.setUniqueId("uid");
        req.setDeviceType("DESKTOP");

        DeviceResponse resp = service.registerDevice(req, userId);

        assertThat(resp.getDeviceName()).isEqualTo("laptop");
        assertThat(resp.getUniqueId()).isEqualTo("uid");
        assertThat(resp.getDeviceType()).isEqualTo("DESKTOP");
        verify(deviceRepository).save(any(Device.class));
    }

    @Test
    void registerDevice_existingOtherUser_throws() {
        Device existing = Device.builder().uniqueId("uid").userId(UUID.randomUUID()).build();
        when(deviceRepository.findByUniqueId("uid")).thenReturn(Optional.of(existing));

        DeviceRegisterRequest req = new DeviceRegisterRequest();
        req.setDeviceName("laptop");
        req.setUniqueId("uid");

        assertThatThrownBy(() -> service.registerDevice(req, UUID.randomUUID()))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("другим пользователем");
    }

    @Test
    void registerDevice_existingSameUser_updates() {
        UUID userId = UUID.randomUUID();
        Device existing = Device.builder()
                .id(UUID.randomUUID()).uniqueId("uid").userId(userId).build();
        when(deviceRepository.findByUniqueId("uid")).thenReturn(Optional.of(existing));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        DeviceRegisterRequest req = new DeviceRegisterRequest();
        req.setDeviceName("new name");
        req.setUniqueId("uid");
        req.setDeviceType("LAPTOP");

        DeviceResponse resp = service.registerDevice(req, userId);

        assertThat(resp.getDeviceName()).isEqualTo("new name");
        assertThat(resp.getDeviceType()).isEqualTo("LAPTOP");
    }

    @Test
    void getUserDevices_returnsList() {
        UUID userId = UUID.randomUUID();
        Device d1 = Device.builder().id(UUID.randomUUID()).userId(userId)
                .uniqueId("u1").deviceName("d1").isActive(true).build();
        Device d2 = Device.builder().id(UUID.randomUUID()).userId(userId)
                .uniqueId("u2").deviceName("d2").isActive(false).build();
        when(deviceRepository.findByUserId(userId)).thenReturn(List.of(d1, d2));

        List<DeviceResponse> result = service.getUserDevices(userId);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).getUniqueId()).isEqualTo("u1");
        assertThat(result.get(1).getUniqueId()).isEqualTo("u2");
        assertThat(result.get(1).getIsActive()).isFalse();
    }

    @Test
    void getUserDevices_emptyList() {
        UUID userId = UUID.randomUUID();
        when(deviceRepository.findByUserId(userId)).thenReturn(List.of());

        assertThat(service.getUserDevices(userId)).isEmpty();
    }

    @Test
    void getEncryptedPrivateKey_notFound_throws() {
        when(deviceRepository.findByIdAndUserId(any(), any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getEncryptedPrivateKey(UUID.randomUUID(), UUID.randomUUID()))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void getEncryptedPrivateKey_inactive_throws() {
        UUID userId = UUID.randomUUID();
        Device d = Device.builder().id(UUID.randomUUID()).userId(userId).isActive(false).build();
        when(deviceRepository.findByIdAndUserId(d.getId(), userId)).thenReturn(Optional.of(d));

        assertThatThrownBy(() -> service.getEncryptedPrivateKey(d.getId(), userId))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("отключено");
    }

    @Test
    void getEncryptedPrivateKey_active_returnsKeyAndUpdatesLastUsed() {
        UUID userId = UUID.randomUUID();
        Device d = Device.builder()
                .id(UUID.randomUUID()).userId(userId).isActive(true)
                .encryptedPrivateKey("KEY")
                .build();
        when(deviceRepository.findByIdAndUserId(d.getId(), userId)).thenReturn(Optional.of(d));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        String key = service.getEncryptedPrivateKey(d.getId(), userId);

        assertThat(key).isEqualTo("KEY");
        assertThat(d.getLastUsedAt()).isNotNull();
        verify(deviceRepository).save(d);
    }

    @Test
    void updateDevice_notFound_throws() {
        when(deviceRepository.findByIdAndUserId(any(), any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.updateDevice(
                UUID.randomUUID(), new DeviceUpdateRequest(), UUID.randomUUID()))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void updateDevice_changesNameAndActive() {
        UUID userId = UUID.randomUUID();
        Device d = Device.builder()
                .id(UUID.randomUUID()).userId(userId)
                .deviceName("old").isActive(true).build();
        when(deviceRepository.findByIdAndUserId(d.getId(), userId)).thenReturn(Optional.of(d));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        DeviceUpdateRequest req = new DeviceUpdateRequest();
        req.setDeviceName("new");
        req.setIsActive(false);

        DeviceResponse resp = service.updateDevice(d.getId(), req, userId);

        assertThat(resp.getDeviceName()).isEqualTo("new");
        assertThat(resp.getIsActive()).isFalse();
    }

    @Test
    void updateDevice_nullFields_leavesUnchanged() {
        UUID userId = UUID.randomUUID();
        Device d = Device.builder()
                .id(UUID.randomUUID()).userId(userId)
                .deviceName("old").isActive(true).build();
        when(deviceRepository.findByIdAndUserId(d.getId(), userId)).thenReturn(Optional.of(d));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        DeviceResponse resp = service.updateDevice(d.getId(), new DeviceUpdateRequest(), userId);

        assertThat(resp.getDeviceName()).isEqualTo("old");
        assertThat(resp.getIsActive()).isTrue();
    }

    @Test
    void deactivateDevice_success() {
        UUID userId = UUID.randomUUID();
        Device d = Device.builder().id(UUID.randomUUID()).userId(userId).isActive(true).build();
        when(deviceRepository.findByIdAndUserId(d.getId(), userId)).thenReturn(Optional.of(d));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        service.deactivateDevice(d.getId(), userId);

        assertThat(d.getIsActive()).isFalse();
        verify(deviceRepository).save(d);
    }

    @Test
    void deactivateDevice_notFound_throws() {
        when(deviceRepository.findByIdAndUserId(any(), any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.deactivateDevice(UUID.randomUUID(), UUID.randomUUID()))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void deleteDevice_success() {
        UUID userId = UUID.randomUUID();
        Device d = Device.builder().id(UUID.randomUUID()).userId(userId).build();
        when(deviceRepository.findByIdAndUserId(d.getId(), userId)).thenReturn(Optional.of(d));

        service.deleteDevice(d.getId(), userId);

        verify(deviceRepository).delete(d);
    }

    @Test
    void deleteDevice_notFound_throws() {
        when(deviceRepository.findByIdAndUserId(any(), any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.deleteDevice(UUID.randomUUID(), UUID.randomUUID()))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void ensureTempDownloadDeviceExists_alreadyExists_noop() {
        UUID userId = UUID.randomUUID();
        when(deviceRepository.existsByUserIdAndDeviceType(userId, "TEMP_DOWNLOAD"))
                .thenReturn(true);

        service.ensureTempDownloadDeviceExists(userId);

        verify(userRepository, never()).findById(any());
        verify(deviceRepository, never()).save(any());
    }

    @Test
    void ensureTempDownloadDeviceExists_notExists_creates() {
        UUID userId = UUID.randomUUID();
        User user = User.builder().id(userId).username("alice")
                .publicKey("pub").privateKeyEncrypted("priv").build();
        when(deviceRepository.existsByUserIdAndDeviceType(userId, "TEMP_DOWNLOAD"))
                .thenReturn(false);
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(deviceRepository.findByUniqueId(anyString())).thenReturn(Optional.empty());
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        service.ensureTempDownloadDeviceExists(userId);

        verify(deviceRepository).save(any(Device.class));
    }
}
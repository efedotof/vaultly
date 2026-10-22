package com.efedotov.vaultly.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.efedotov.vaultly.dto.device.DeviceRegisterRequest;
import com.efedotov.vaultly.dto.device.DeviceResponse;
import com.efedotov.vaultly.dto.device.DeviceUpdateRequest;
import com.efedotov.vaultly.model.Device;
import com.efedotov.vaultly.repository.DeviceRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class DeviceService {

    private final DeviceRepository deviceRepository;

    @Transactional
    public DeviceResponse registerDevice(DeviceRegisterRequest request, UUID userId) {
        Device device = deviceRepository.findByUniqueId(request.getUniqueId()).orElse(null);

        if (device == null) {
            device = Device.builder()
                    .userId(userId)
                    .deviceName(request.getDeviceName())
                    .deviceType(request.getDeviceType())
                    .uniqueId(request.getUniqueId())
                    .publicKey(request.getPublicKey())
                    .isActive(true)
                    .createdAt(LocalDateTime.now())
                    .build();
            log.info("Создано новое устройство {} для пользователя {}",
                    device.getDeviceName(), userId);
        } else {
            if (!device.getUserId().equals(userId)) {
                log.warn("Попытка перехвата устройства {} пользователем {} (владелец {})",
                        request.getUniqueId(), userId, device.getUserId());
                throw new SecurityException(
                        "Устройство с таким идентификатором уже зарегистрировано другим пользователем");
            }
            device.setDeviceName(request.getDeviceName());
            device.setDeviceType(request.getDeviceType());
            device.setPublicKey(request.getPublicKey());
            device.setIsActive(true);
            device.setLastUsedAt(LocalDateTime.now());
            log.info("Обновлено существующее устройство {} для пользователя {}",
                    device.getUniqueId(), userId);
        }

        device = deviceRepository.save(device);
        return mapToResponse(device);
    }

    @Transactional(readOnly = true)
    public List<DeviceResponse> getUserDevices(UUID userId) {
        return deviceRepository.findByUserId(userId).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }


    @Transactional
    public DeviceResponse updateDevice(UUID deviceId, DeviceUpdateRequest request, UUID userId) {
        Device device = deviceRepository.findByIdAndUserId(deviceId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Устройство не найдено"));

        if (request.getDeviceName() != null) {
            device.setDeviceName(request.getDeviceName());
        }
        if (request.getIsActive() != null) {
            device.setIsActive(request.getIsActive());
        }

        device = deviceRepository.save(device);
        log.info("Обновлено устройство {} для пользователя {}", device.getId(), userId);
        return mapToResponse(device);
    }

    @Transactional
    public void deactivateDevice(UUID deviceId, UUID userId) {
        Device device = deviceRepository.findByIdAndUserId(deviceId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Устройство не найдено"));
        device.setIsActive(false);
        deviceRepository.save(device);
        log.info("Устройство {} деактивировано пользователем {}", deviceId, userId);
    }

    @Transactional
    public void deleteDevice(UUID deviceId, UUID userId) {
        Device device = deviceRepository.findByIdAndUserId(deviceId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Устройство не найдено"));
        deviceRepository.delete(device);
        log.info("Устройство {} удалено пользователем {}", deviceId, userId);
    }


    private DeviceResponse mapToResponse(Device device) {
        return DeviceResponse.builder()
                .id(device.getId())
                .deviceName(device.getDeviceName())
                .deviceType(device.getDeviceType())
                .uniqueId(device.getUniqueId())
                .isActive(device.getIsActive())
                .createdAt(device.getCreatedAt())
                .lastUsedAt(device.getLastUsedAt())
                .build();
    }
}
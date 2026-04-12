package com.efedotov.vaultly.controller;

import java.util.List;
import java.util.UUID;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.efedotov.vaultly.dto.device.DeviceRegisterRequest;
import com.efedotov.vaultly.dto.device.DeviceResponse;
import com.efedotov.vaultly.dto.device.DeviceUpdateRequest;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.DeviceService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/device")
@RequiredArgsConstructor
@Slf4j
public class DeviceRestController {

    private final DeviceService deviceService;

    @PostMapping("/register")
    public DeviceResponse registerDevice(@RequestBody DeviceRegisterRequest request,
            @AuthenticationPrincipal CustomUserDetails user) {
        try {
            DeviceResponse device = deviceService.registerDevice(request, user.getUserId());
            log.info("Устройство {} зарегистрировано пользователем {}", device.getDeviceName(), user.getUsername());
            return device;
        } catch (Exception e) {
            log.error("Ошибка регистрации устройства: {}", e.getMessage());
            throw e;
        }
    }

    @GetMapping("/me-device")
    public List<DeviceResponse> getUserDevices(@AuthenticationPrincipal CustomUserDetails user) {
        try {
            return deviceService.getUserDevices(user.getUserId());
        } catch (Exception e) {
            log.error("Ошибка получения списка устройств: {}", e.getMessage());
            throw e;
        }
    }

    @GetMapping("/{deviceId}/key")
    public String getEncryptedPrivateKey(@PathVariable UUID deviceId,
            @AuthenticationPrincipal CustomUserDetails user) {
        try {
            String key = deviceService.getEncryptedPrivateKey(deviceId, user.getUserId());
            log.info("Устройство {} запросило приватный ключ", deviceId);
            return key;
        } catch (Exception e) {
            log.error("Ошибка получения ключа для устройства {}: {}", deviceId, e.getMessage());
            throw e;
        }
    }

    @PutMapping("/{deviceId}")
    public DeviceResponse updateDevice(@PathVariable UUID deviceId,
            @RequestBody DeviceUpdateRequest request,
            @AuthenticationPrincipal CustomUserDetails user) {
        try {
            DeviceResponse device = deviceService.updateDevice(deviceId, request, user.getUserId());
            log.info("Устройство {} обновлено пользователем {}", device.getId(), user.getUsername());
            return device;
        } catch (Exception e) {
            log.error("Ошибка обновления устройства: {}", e.getMessage());
            throw e;
        }
    }

    @PostMapping("/{deviceId}/deactivate")
    public void deactivateDevice(@PathVariable UUID deviceId,
            @AuthenticationPrincipal CustomUserDetails user) {
        try {
            deviceService.deactivateDevice(deviceId, user.getUserId());
            log.info("Устройство {} деактивировано пользователем {}", deviceId, user.getUsername());
        } catch (Exception e) {
            log.error("Ошибка деактивации устройства: {}", e.getMessage());
            throw e;
        }
    }

    @DeleteMapping("/{deviceId}")
    public void deleteDevice(@PathVariable UUID deviceId,
            @AuthenticationPrincipal CustomUserDetails user) {
        try {
            deviceService.deleteDevice(deviceId, user.getUserId());
            log.info("Устройство {} удалено пользователем {}", deviceId, user.getUsername());
        } catch (Exception e) {
            log.error("Ошибка удаления устройства: {}", e.getMessage());
            throw e;
        }
    }
}
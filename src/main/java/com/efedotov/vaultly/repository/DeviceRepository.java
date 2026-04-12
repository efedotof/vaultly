package com.efedotov.vaultly.repository;

import com.efedotov.vaultly.model.Device;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DeviceRepository extends JpaRepository<Device, UUID> {

    List<Device> findByUserId(UUID userId);

    Optional<Device> findByIdAndUserId(UUID id, UUID userId);

    boolean existsByIdAndUserId(UUID id, UUID userId);

    List<Device> findByUserIdAndIsActiveTrue(UUID userId);

    boolean existsByUserIdAndDeviceType(UUID userId, String deviceType);

    Optional<Device> findByUserIdAndUniqueId(UUID userId, String uniqueId);

    Optional<Device> findByUniqueId(String uniqueId);
}
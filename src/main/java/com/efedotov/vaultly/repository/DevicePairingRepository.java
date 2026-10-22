package com.efedotov.vaultly.repository;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.efedotov.vaultly.model.DevicePairing;

@Repository
public interface DevicePairingRepository extends JpaRepository<DevicePairing, UUID> {

    Optional<DevicePairing> findByIdAndUserId(UUID id, UUID userId);

    @Query("SELECT COUNT(dp) FROM DevicePairing dp " +
           "WHERE dp.userId = :userId AND dp.expiresAt > :now AND dp.consumedAt IS NULL")
    long countActiveByUserId(@Param("userId") UUID userId, @Param("now") LocalDateTime now);

    @Modifying
    @Query("DELETE FROM DevicePairing dp WHERE dp.expiresAt < :now")
    void deleteExpired(@Param("now") LocalDateTime now);
}
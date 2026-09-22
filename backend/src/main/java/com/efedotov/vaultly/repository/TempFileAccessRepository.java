package com.efedotov.vaultly.repository;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import com.efedotov.vaultly.model.TempFileAccess;

public interface TempFileAccessRepository extends JpaRepository<TempFileAccess, UUID> {
    Optional<TempFileAccess> findByToken(String token);

    @Modifying
    @Transactional
    @Query("UPDATE TempFileAccess t SET t.downloadsCount = t.downloadsCount + 1 " +
            "WHERE t.token = :token AND t.isActive = true AND t.expiresAt > :now " +
            "AND (t.maxDownloads IS NULL OR t.downloadsCount < t.maxDownloads)")
    int incrementDownloadsAndCheck(@Param("token") String token, @Param("now") LocalDateTime now);
}
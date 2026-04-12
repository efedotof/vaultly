package com.efedotov.vaultly.repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.efedotov.vaultly.model.UserSession;

@Repository
public interface UserSessionRepository extends JpaRepository<UserSession, String> {

    Optional<UserSession> findByToken(String token);

    @Query("SELECT s FROM UserSession s WHERE s.token = ?1 AND s.expiresAt > ?2")
    Optional<UserSession> findValidSession(String token, Instant now);

    @Modifying
    @Query("DELETE FROM UserSession s WHERE s.expiresAt < ?1")
    void deleteExpiredSessions(Instant now);

    @Query("SELECT s FROM UserSession s WHERE s.expiresAt > ?1")
    List<UserSession> findAllActiveSessions(Instant now);

    List<UserSession> findByUserId(UUID userId);

    @Query("SELECT COUNT(s) FROM UserSession s WHERE s.expiresAt > ?1")
    long countActiveSessions(Instant now);

    @Modifying
    @Query("DELETE FROM UserSession s WHERE s.userId = ?1")
    void deleteByUserId(UUID userId);

    @Query("SELECT COUNT(s) FROM UserSession s WHERE s.createdAt >= ?1")
    long countSessionsCreatedAfter(Instant startTime);

    @Query("SELECT s FROM UserSession s WHERE s.createdAt >= ?1")
    List<UserSession> findSessionsCreatedAfter(Instant startTime);

    @Query(value = "SELECT COUNT(*) FROM user_sessions WHERE DATE(created_at) = CURRENT_DATE", nativeQuery = true)
    long getAverageSessionsPerDay();

    @Query(value = "SELECT MAX(daily_count) FROM (" +
            "SELECT DATE(created_at) as date, COUNT(*) as daily_count " +
            "FROM user_sessions " +
            "GROUP BY DATE(created_at)" +
            ") as daily_counts", nativeQuery = true)
    Long getMaxConcurrentSessions();
}
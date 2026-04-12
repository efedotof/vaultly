package com.efedotov.vaultly.model;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Entity
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "user_sessions")
public class UserSession {
    @Id
    private String token;

    @Column(nullable = false)
    private UUID userId;

    @Column(nullable = false, columnDefinition = "TIMESTAMP")
    private Instant createdAt;

    @Column(nullable = false, columnDefinition = "TIMESTAMP")
    private Instant expiresAt;
}

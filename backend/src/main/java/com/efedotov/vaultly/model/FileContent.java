package com.efedotov.vaultly.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "file_contents", uniqueConstraints = @UniqueConstraint(columnNames = { "hash", "is_public" }))
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FileContent {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = true, length = 64)
    private String hash;

    @Column(name = "s3_key", nullable = false, unique = true)
    private String s3Key;

    @Column(name = "s3_url")
    private String s3Url;

    @Column(nullable = false)
    private Long size;

    @Column(name = "mime_type")
    private String mimeType;

    @Column(name = "is_public", nullable = false)
    private Boolean isPublic;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false, nullable = false)
    private LocalDateTime createdAt;
}
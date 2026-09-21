package com.efedotov.vaultly.model;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {
    @Id
    @GeneratedValue
    private UUID id;

    @Column(unique = true)
    private String email;

    @Column(nullable = false)
    private String passwordHash;

    @Column(unique = true, nullable = false)
    private String username;

    private String firstName;
    private String lastName;

    @Column(columnDefinition = "TEXT")
    private String publicKey;

    @Column(columnDefinition = "TEXT")
    private String privateKeyEncrypted;

    @Column(name = "avatar_s3_key")
    private String avatarS3Key;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @Column(name = "storage_used")
    @Builder.Default
    private Long storageUsed = 0L;

    @Column(name = "storage_limit")
    @Builder.Default
    private Long storageLimit = 1073741824L;

    @Builder.Default
    private Boolean isActive = true;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<Folder> folders;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<File> files;

    @Column(name = "salt")
    private String salt;

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(name = "user_roles", joinColumns = @JoinColumn(name = "user_id"), inverseJoinColumns = @JoinColumn(name = "role_id"))
    private Set<Role> roles;

    @Column(name = "totp_secret", length = 64)
    private String totpSecret;

    @Column(name = "totp_enabled")
    @Builder.Default
    private Boolean totpEnabled = false;

    @Column(name = "totp_verified_at")
    private LocalDateTime totpVerifiedAt;

    @Column(name = "backup_codes_hash", columnDefinition = "TEXT")
    private String backupCodesHash;

    @Column(name = "recovery_public_key", columnDefinition = "TEXT")
    private String recoveryPublicKey;

    @Column(name = "recovery_private_key_encrypted", columnDefinition = "TEXT")
    private String recoveryPrivateKeyEncrypted;

    @Column(name = "recovery_salt")
    private String recoverySalt;

    @Column(name = "recovery_encrypted_rsa_key", columnDefinition = "TEXT")
    private String recoveryEncryptedRsaKey;
}
package com.efedotov.vaultly.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "folder_accesses")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FolderAccess {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "folder_id", nullable = false)
    private Folder folder;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AccessLevel accessLevel;

    @Column(name = "can_edit")
    @Builder.Default
    private Boolean canEdit = false;

    @Column(name = "can_delete")
    @Builder.Default
    private Boolean canDelete = false;

    @Column(name = "can_share")
    @Builder.Default
    private Boolean canShare = false;

    @Column(name = "is_active")
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "granted_by")
    private UUID grantedBy;

    @Column(name = "granted_at")
    private LocalDateTime grantedAt;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Column(name = "access_key_hash")
    private String accessKeyHash;

    public enum AccessLevel {
        READ,
        WRITE,
        ADMIN,
        OWNER
    }
}
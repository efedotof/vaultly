package com.efedotov.vaultly.repository;

import com.efedotov.vaultly.model.Folder;
import com.efedotov.vaultly.model.FolderAccess;
import com.efedotov.vaultly.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FolderAccessRepository extends JpaRepository<FolderAccess, UUID> {

    Optional<FolderAccess> findByFolderAndUser(Folder folder, User user);

    List<FolderAccess> findByFolder(Folder folder);

    List<FolderAccess> findByUser(User user);

    boolean existsByFolderAndUser(Folder folder, User user);

    @Modifying
    @Query("DELETE FROM FolderAccess fa WHERE fa.folder = :folder")
    void deleteByFolder(@Param("folder") Folder folder);

    @Modifying
    @Query("DELETE FROM FolderAccess fa WHERE fa.user = :user AND fa.folder = :folder")
    void deleteByUserAndFolder(@Param("user") User user, @Param("folder") Folder folder);

    @Query("SELECT fa FROM FolderAccess fa WHERE fa.folder = :folder AND fa.isActive = true")
    List<FolderAccess> findActiveByFolder(@Param("folder") Folder folder);

    @Modifying
    @Query("UPDATE FolderAccess fa SET fa.isActive = false WHERE fa.expiresAt < :now")
    void deactivateExpiredAccesses(@Param("now") LocalDateTime now);
}
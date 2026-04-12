package com.efedotov.vaultly.repository;

import com.efedotov.vaultly.model.Folder;
import com.efedotov.vaultly.model.FolderPassword;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface FolderPasswordRepository extends JpaRepository<FolderPassword, UUID> {

    Optional<FolderPassword> findByFolderAndIsActive(Folder folder, Boolean isActive);

    @Modifying
    @Query("DELETE FROM FolderPassword fp WHERE fp.folder = :folder")
    void deleteByFolder(@Param("folder") Folder folder);

    @Modifying
    @Query("UPDATE FolderPassword fp SET fp.isActive = false WHERE fp.folder = :folder")
    void deactivateByFolder(@Param("folder") Folder folder);
}
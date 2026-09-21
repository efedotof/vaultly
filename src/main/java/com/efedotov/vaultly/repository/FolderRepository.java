package com.efedotov.vaultly.repository;

import com.efedotov.vaultly.model.Folder;
import com.efedotov.vaultly.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FolderRepository extends JpaRepository<Folder, UUID> {

    List<Folder> findByUser(User user);

    List<Folder> findByUserAndParentFolderIsNull(User user);

    List<Folder> findByParentFolder(Folder parentFolder);

    Optional<Folder> findByUserAndId(User user, UUID id);

    boolean existsByUserAndNameAndParentFolder(User user, String name, Folder parentFolder);

    boolean existsByUserAndNameAndParentFolderIsNull(User user, String name);

    @Query("SELECT f FROM Folder f WHERE f.user = :user AND f.isHidden = false")
    List<Folder> findVisibleByUser(@Param("user") User user);

    @Query("SELECT f FROM Folder f WHERE f.user = :user AND f.parentFolder = :parent")
    List<Folder> findByUserAndParentFolder(@Param("user") User user, @Param("parent") Folder parent);
}
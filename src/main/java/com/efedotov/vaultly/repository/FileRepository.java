package com.efedotov.vaultly.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.model.FileContent;

@Repository
public interface FileRepository extends JpaRepository<File, UUID> {

    @Query("SELECT f FROM File f WHERE f.user.id = :userId AND f.isDeleted = false")
    List<File> findByUserId(@Param("userId") UUID userId);

    @Query("SELECT f FROM File f WHERE f.id = :id AND f.user.id = :userId AND f.isDeleted = false")
    Optional<File> findByIdAndUserId(@Param("id") UUID id, @Param("userId") UUID userId);

    @Query("SELECT f FROM File f WHERE f.folder.id = :folderId AND f.isDeleted = false")
    List<File> findByFolderId(@Param("folderId") UUID folderId);

    @Query("SELECT f FROM File f WHERE f.folder IS NULL AND f.user.id = :userId AND f.isDeleted = false")
    List<File> findFilesWithoutFolder(@Param("userId") UUID userId);

    Page<File> findByUserIdAndIsDeletedFalse(UUID userId, Pageable pageable);

    @Query("SELECT f FROM File f WHERE f.user.id = :userId AND f.isDeleted = false ORDER BY f.createdAt DESC")
    Page<File> findLatestByUserId(@Param("userId") UUID userId, Pageable pageable);

    @Query("SELECT f FROM File f WHERE f.user.id = :userId AND f.isDeleted = false AND f.isNote = true")
    Page<File> findNotesByUserId(@Param("userId") UUID userId, Pageable pageable);

    @Query("SELECT COUNT(f) FROM File f WHERE f.fileContent = :content AND f.isDeleted = false")
    long countActiveLinksByFileContent(@Param("content") FileContent content);
}
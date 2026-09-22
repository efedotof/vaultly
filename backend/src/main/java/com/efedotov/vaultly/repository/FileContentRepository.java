package com.efedotov.vaultly.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.efedotov.vaultly.model.FileContent;

@Repository
public interface FileContentRepository extends JpaRepository<FileContent, UUID> {

    Optional<FileContent> findByHashAndIsPublic(String hash, Boolean isPublic);

    @Query("SELECT fc FROM FileContent fc " +
            "WHERE fc.createdAt < :threshold " +
            "AND NOT EXISTS (" +
            "  SELECT 1 FROM File f WHERE f.fileContent = fc AND f.isDeleted = false" +
            ") " +
            "ORDER BY fc.createdAt ASC")
    List<FileContent> findOrphanedContentOlderThan(@Param("threshold") LocalDateTime threshold,
            Pageable pageable);
}
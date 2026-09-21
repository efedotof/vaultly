package com.efedotov.vaultly.repository;

import com.efedotov.vaultly.model.FileContent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface FileContentRepository extends JpaRepository<FileContent, UUID> {

    Optional<FileContent> findByHashAndIsPublic(String hash, Boolean isPublic);
}
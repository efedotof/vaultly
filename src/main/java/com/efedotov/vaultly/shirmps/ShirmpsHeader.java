package com.efedotov.vaultly.shirmps;

import java.time.LocalDateTime;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class ShirmpsHeader {
    private String version = "1.0";
    private String algorithm = "AES-256-GCM";
    private String keyEncryption = "RSA-OAEP";
    private LocalDateTime creationDate;
    private String originalFileName;
    private Long originalFileSize;
    private String encryptedKey;
    private String iv;
    private String signature;
    private Map<String, String> metadata;
    private String keyOwner;
    private String userId;

    public ShirmpsHeader() {
        this.creationDate = LocalDateTime.now();
    }

    public byte[] toJsonBytes() throws JsonProcessingException {
        ObjectMapper mapper = createObjectMapper();
        return mapper.writeValueAsBytes(this);
    }

    public static ShirmpsHeader fromJsonBytes(byte[] jsonBytes) throws Exception {
        ObjectMapper mapper = createObjectMapper();
        return mapper.readValue(jsonBytes, ShirmpsHeader.class);
    }

    public static ObjectMapper createObjectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        return mapper;
    }

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getAlgorithm() {
        return algorithm;
    }

    public void setAlgorithm(String algorithm) {
        this.algorithm = algorithm;
    }

    public String getKeyEncryption() {
        return keyEncryption;
    }

    public void setKeyEncryption(String keyEncryption) {
        this.keyEncryption = keyEncryption;
    }

    public LocalDateTime getCreationDate() {
        return creationDate;
    }

    public void setCreationDate(LocalDateTime creationDate) {
        this.creationDate = creationDate;
    }

    public String getOriginalFileName() {
        return originalFileName;
    }

    public void setOriginalFileName(String originalFileName) {
        this.originalFileName = originalFileName;
    }

    public Long getOriginalFileSize() {
        return originalFileSize;
    }

    public void setOriginalFileSize(Long originalFileSize) {
        this.originalFileSize = originalFileSize;
    }

    public String getEncryptedKey() {
        return encryptedKey;
    }

    public void setEncryptedKey(String encryptedKey) {
        this.encryptedKey = encryptedKey;
    }

    public String getIv() {
        return iv;
    }

    public void setIv(String iv) {
        this.iv = iv;
    }

    public String getSignature() {
        return signature;
    }

    public void setSignature(String signature) {
        this.signature = signature;
    }

    public Map<String, String> getMetadata() {
        return metadata;
    }

    public void setMetadata(Map<String, String> metadata) {
        this.metadata = metadata;
    }

    public String getKeyOwner() {
        return keyOwner;
    }

    public void setKeyOwner(String keyOwner) {
        this.keyOwner = keyOwner;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }
}
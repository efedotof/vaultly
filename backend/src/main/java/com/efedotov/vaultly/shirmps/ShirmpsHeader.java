package com.efedotov.vaultly.shirmps;

import java.time.LocalDateTime;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonInclude;

import tools.jackson.core.JacksonException;
import tools.jackson.databind.DeserializationFeature;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.SerializationFeature;
import tools.jackson.databind.json.JsonMapper;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class ShirmpsHeader {

    private static final ObjectMapper OBJECT_MAPPER = buildMapper();

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

    public byte[] toJsonBytes() throws JacksonException {
        return OBJECT_MAPPER.writeValueAsBytes(this);
    }

    public static ShirmpsHeader fromJsonBytes(byte[] jsonBytes) throws Exception {
        return OBJECT_MAPPER.readValue(jsonBytes, ShirmpsHeader.class);
    }

    public static ObjectMapper createObjectMapper() {
        return OBJECT_MAPPER;
    }

    private static ObjectMapper buildMapper() {
        return JsonMapper.builder()
                .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
                .disable(SerializationFeature.FAIL_ON_EMPTY_BEANS)
                .build();
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
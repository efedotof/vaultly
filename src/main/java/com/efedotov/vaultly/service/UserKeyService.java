package com.efedotov.vaultly.service;

import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.efedotov.vaultly.repository.UserRepository;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserKeyService {

    private final UserRepository userRepository;
    private final Map<UUID, PublicKey> userPublicKeys = new ConcurrentHashMap<>();
    private final Map<UUID, PrivateKey> userPrivateKeys = new ConcurrentHashMap<>();

    @PostConstruct
    @Transactional(readOnly = true)
    public void init() {
        log.info("Loading user public keys from database...");
        userRepository.findAll().forEach(user -> {
            if (user.getPublicKey() != null && !user.getPublicKey().isBlank()) {
                try {
                    PublicKey publicKey = loadPublicKeyFromPem(user.getPublicKey());
                    userPublicKeys.put(user.getId(), publicKey);
                    log.debug("Loaded public key for user: {}", user.getId());
                } catch (Exception e) {
                    log.error("Failed to load public key for user {}: {}", user.getId(), e.getMessage());
                }
            }
        });
        log.info("Loaded {} user public keys", userPublicKeys.size());
    }

    private PublicKey loadPublicKeyFromPem(String pem) throws Exception {
        String base64Key = pem
                .replace("-----BEGIN PUBLIC KEY-----", "")
                .replace("-----END PUBLIC KEY-----", "")
                .replaceAll("\\s", "");
        byte[] keyBytes = Base64.getDecoder().decode(base64Key);
        X509EncodedKeySpec spec = new X509EncodedKeySpec(keyBytes);
        KeyFactory kf = KeyFactory.getInstance("RSA");
        return kf.generatePublic(spec);
    }

    public PublicKey getPublicKey(UUID userId) {
        PublicKey key = userPublicKeys.get(userId);
        if (key == null) {
            return userRepository.findById(userId)
                    .map(user -> {
                        if (user.getPublicKey() == null || user.getPublicKey().isBlank()) {
                            throw new IllegalArgumentException("Public key not found for user: " + userId);
                        }
                        try {
                            PublicKey loadedKey = loadPublicKeyFromPem(user.getPublicKey());
                            userPublicKeys.put(userId, loadedKey);
                            log.info("Loaded public key for user {} on demand", userId);
                            return loadedKey;
                        } catch (Exception e) {
                            log.error("Failed to load public key for user {}: {}", userId, e.getMessage());
                            throw new IllegalArgumentException("Invalid public key format for user: " + userId, e);
                        }
                    })
                    .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));
        }
        return key;
    }

    public PrivateKey getPrivateKey(UUID userId) {
        return userPrivateKeys.get(userId);
    }

    public void addUserPublicKey(UUID userId, PublicKey publicKey) {
        userPublicKeys.put(userId, publicKey);
        log.info("Added public key for user: {}", userId);
    }

    public void addUserPrivateKey(UUID userId, PrivateKey privateKey) {
        userPrivateKeys.put(userId, privateKey);
        log.warn("Added private key for user: {}. WARNING: This should not be used in production!", userId);
    }

    public boolean hasPublicKey(UUID userId) {
        return userPublicKeys.containsKey(userId);
    }
}
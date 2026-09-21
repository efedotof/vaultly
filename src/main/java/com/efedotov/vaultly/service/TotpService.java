package com.efedotov.vaultly.service;

import dev.samstevens.totp.code.*;
import dev.samstevens.totp.exceptions.QrGenerationException;
import dev.samstevens.totp.qr.QrData;
import dev.samstevens.totp.qr.QrGenerator;
import dev.samstevens.totp.qr.ZxingPngQrGenerator;
import dev.samstevens.totp.secret.DefaultSecretGenerator;
import dev.samstevens.totp.secret.SecretGenerator;
import dev.samstevens.totp.time.SystemTimeProvider;
import dev.samstevens.totp.time.TimeProvider;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

@Service
@Slf4j
public class TotpService {

    private static final String ISSUER = "Vaultly";
    private static final int CODE_LENGTH = 6;
    private static final int TIME_PERIOD_SECONDS = 30;
    private static final int BACKUP_CODE_COUNT = 8;
    private static final int BACKUP_CODE_LENGTH = 10;

    private final SecretGenerator secretGenerator = new DefaultSecretGenerator();
    private final TimeProvider timeProvider = new SystemTimeProvider();
    private final CodeGenerator codeGenerator = new DefaultCodeGenerator(HashingAlgorithm.SHA1, CODE_LENGTH);
    private final CodeVerifier codeVerifier = new DefaultCodeVerifier(codeGenerator, timeProvider);
    private final PasswordEncoder backupCodeEncoder = new BCryptPasswordEncoder();

    public String generateSecret() {
        return secretGenerator.generate();
    }

    public String generateQrCodeUrl(String secret, String username) throws QrGenerationException {
        QrData data = new QrData.Builder()
                .label(username)
                .secret(secret)
                .issuer(ISSUER)
                .algorithm(HashingAlgorithm.SHA1)
                .digits(CODE_LENGTH)
                .period(TIME_PERIOD_SECONDS)
                .build();

        QrGenerator generator = new ZxingPngQrGenerator();
        byte[] imageData = generator.generate(data);
        String mimeType = generator.getImageMimeType();
        return "data:" + mimeType + ";base64," + Base64.getEncoder().encodeToString(imageData);
    }

    public boolean verifyCode(String secret, String code) {
        try {
            return codeVerifier.isValidCode(secret, code);
        } catch (Exception e) {
            log.error("TOTP verification error", e);
            return false;
        }
    }

    public BackupCodes generateBackupCodes() {
        List<String> plainCodes = new ArrayList<>();
        List<String> hashedCodes = new ArrayList<>();
        SecureRandom random = new SecureRandom();

        for (int i = 0; i < BACKUP_CODE_COUNT; i++) {
            String code = generateRandomCode(BACKUP_CODE_LENGTH, random);
            plainCodes.add(code);
            hashedCodes.add(backupCodeEncoder.encode(code));
        }

        String hashesJson = hashedCodes.stream()
                .map(h -> "\"" + h + "\"")
                .collect(Collectors.joining(",", "[", "]"));

        return new BackupCodes(plainCodes, hashesJson);
    }

    public boolean verifyBackupCode(String plainCode, String storedHashesJson) {
        if (storedHashesJson == null || storedHashesJson.isBlank()) {
            return false;
        }
        List<String> hashes = parseJsonStringArray(storedHashesJson);
        for (String hash : hashes) {
            if (backupCodeEncoder.matches(plainCode, hash)) {
                return true;
            }
        }
        return false;
    }

    public String removeUsedBackupCode(String plainCode, String storedHashesJson) {
        if (storedHashesJson == null || storedHashesJson.isBlank()) {
            return storedHashesJson;
        }
        List<String> hashes = parseJsonStringArray(storedHashesJson);
        List<String> updatedHashes = hashes.stream()
                .filter(hash -> !backupCodeEncoder.matches(plainCode, hash))
                .collect(Collectors.toList());

        return updatedHashes.stream()
                .map(h -> "\"" + h + "\"")
                .collect(Collectors.joining(",", "[", "]"));
    }

    private String generateRandomCode(int length, SecureRandom random) {
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        return IntStream.range(0, length)
                .mapToObj(i -> String.valueOf(chars.charAt(random.nextInt(chars.length()))))
                .collect(Collectors.joining());
    }

    private List<String> parseJsonStringArray(String json) {
        String trimmed = json.trim();
        if (trimmed.startsWith("[") && trimmed.endsWith("]")) {
            trimmed = trimmed.substring(1, trimmed.length() - 1).trim();
        }
        if (trimmed.isEmpty()) {
            return List.of();
        }
        return List.of(trimmed.replaceAll("\"", "").split("\\s*,\\s*"));
    }

    public record BackupCodes(List<String> plainCodes, String hashesJson) {
    }
}
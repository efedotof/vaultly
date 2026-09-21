package com.efedotov.vaultly.service;

import dev.samstevens.totp.code.CodeGenerator;
import dev.samstevens.totp.code.DefaultCodeGenerator;
import dev.samstevens.totp.code.HashingAlgorithm;
import dev.samstevens.totp.time.SystemTimeProvider;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class TotpServiceTest {

    private final TotpService service = new TotpService();

    @Test
    void generateSecret_nonBlank() {
        assertThat(service.generateSecret()).isNotBlank();
    }

    @Test
    void generateSecret_unique() {
        assertThat(service.generateSecret()).isNotEqualTo(service.generateSecret());
    }

    @Test
    void generateQrCodeUrl_returnsDataUri() throws Exception {
        String secret = service.generateSecret();
        String url = service.generateQrCodeUrl(secret, "alice");

        assertThat(url).startsWith("data:image/png;base64,");
        assertThat(url).hasSizeGreaterThan(100);
    }

    @Test
    void verifyCode_withValidCode_returnsTrue() throws Exception {
        String secret = service.generateSecret();
        CodeGenerator gen = new DefaultCodeGenerator(HashingAlgorithm.SHA1, 6);
        long counter = new SystemTimeProvider().getTime() / 30;
        String code = gen.generate(secret, counter);
        assertThat(service.verifyCode(secret, code)).isTrue();
    }

    @Test
    void verifyCode_withGarbage_returnsFalse() {
        String secret = service.generateSecret();
        assertThat(service.verifyCode(secret, "invalid")).isFalse();
    }

    @Test
    void verifyCode_withNullCode_returnsFalse() {
        String secret = service.generateSecret();
        assertThat(service.verifyCode(secret, null)).isFalse();
    }

    @Test
    void backupCodes_generate_verify_remove() {
        TotpService.BackupCodes bc = service.generateBackupCodes();
        assertThat(bc.plainCodes()).hasSize(8);
        assertThat(bc.hashesJson()).isNotBlank();

        String code = bc.plainCodes().get(0);
        assertThat(service.verifyBackupCode(code, bc.hashesJson())).isTrue();

        String updated = service.removeUsedBackupCode(code, bc.hashesJson());
        assertThat(service.verifyBackupCode(code, updated)).isFalse();
    }

    @Test
    void backupCodes_allAreUnique() {
        TotpService.BackupCodes bc = service.generateBackupCodes();
        assertThat(bc.plainCodes()).doesNotHaveDuplicates();
    }

    @Test
    void verifyBackupCode_nullOrBlank_returnsFalse() {
        assertThat(service.verifyBackupCode("x", null)).isFalse();
        assertThat(service.verifyBackupCode("x", "")).isFalse();
        assertThat(service.verifyBackupCode("x", "   ")).isFalse();
    }

    @Test
    void verifyBackupCode_corruptedJson_returnsFalse() {
        assertThat(service.verifyBackupCode("x", "not-json-at-all")).isFalse();
    }

    @Test
    void verifyBackupCode_wrongCode_returnsFalse() {
        TotpService.BackupCodes bc = service.generateBackupCodes();
        assertThat(service.verifyBackupCode("WRONGCODE1", bc.hashesJson())).isFalse();
    }

    @Test
    void removeUsedBackupCode_nullOrBlank_returnsInput() {
        assertThat(service.removeUsedBackupCode("x", null)).isNull();
        assertThat(service.removeUsedBackupCode("x", "")).isEqualTo("");
    }

    @Test
    void removeUsedBackupCode_corruptedJson_returnsEmptyArray() {

        assertThat(service.removeUsedBackupCode("x", "not-json")).isEqualTo("[]");
    }

    @Test
    void removeUsedBackupCode_unrelatedCode_keepsAll() {
        TotpService.BackupCodes bc = service.generateBackupCodes();
        String updated = service.removeUsedBackupCode("NOTAPRESENT", bc.hashesJson());

        for (String code : bc.plainCodes()) {
            assertThat(service.verifyBackupCode(code, updated)).isTrue();
        }
    }

    @Test
    void removeUsedBackupCode_mixedHashes_keepsUnrelated() {
        TotpService.BackupCodes bc = service.generateBackupCodes();
        String code = bc.plainCodes().get(0);

        String updated = service.removeUsedBackupCode(code, bc.hashesJson());

        for (int i = 1; i < bc.plainCodes().size(); i++) {
            assertThat(service.verifyBackupCode(bc.plainCodes().get(i), updated)).isTrue();
        }
    }
}
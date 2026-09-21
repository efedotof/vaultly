package com.efedotov.vaultly.model;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class FolderAccessLevelTest {

    @Test
    void isAtLeast_ordering() {
        assertThat(FolderAccess.AccessLevel.OWNER.isAtLeast(FolderAccess.AccessLevel.OWNER)).isTrue();
        assertThat(FolderAccess.AccessLevel.OWNER.isAtLeast(FolderAccess.AccessLevel.READ)).isTrue();
        assertThat(FolderAccess.AccessLevel.ADMIN.isAtLeast(FolderAccess.AccessLevel.WRITE)).isTrue();
        assertThat(FolderAccess.AccessLevel.WRITE.isAtLeast(FolderAccess.AccessLevel.WRITE)).isTrue();
        assertThat(FolderAccess.AccessLevel.READ.isAtLeast(FolderAccess.AccessLevel.WRITE)).isFalse();
        assertThat(FolderAccess.AccessLevel.WRITE.isAtLeast(FolderAccess.AccessLevel.ADMIN)).isFalse();
    }
}
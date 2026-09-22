package com.efedotov.vaultly.service;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class LogSanitizerTest {

    @Test
    void null_returnsNull() {
        assertThat(LogSanitizer.clean(null)).isNull();
    }

    @Test
    void replacesNewlines() {
        assertThat(LogSanitizer.clean("a\nb\rc")).isEqualTo("a_b_c");
    }

    @Test
    void leavesNormalTextUntouched() {
        assertThat(LogSanitizer.clean("hello")).isEqualTo("hello");
    }
}
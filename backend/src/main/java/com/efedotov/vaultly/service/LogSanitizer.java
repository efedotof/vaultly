package com.efedotov.vaultly.service;

public final class LogSanitizer {

    private LogSanitizer() {
    }

    public static String clean(String input) {
        if (input == null) {
            return null;
        }
        return input.replaceAll("[\\r\\n]", "_");
    }
}
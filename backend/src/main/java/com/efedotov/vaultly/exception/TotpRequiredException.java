package com.efedotov.vaultly.exception;

public class TotpRequiredException extends RuntimeException {
    private final String preAuthToken;

    public TotpRequiredException(String preAuthToken) {
        super("TOTP required");
        this.preAuthToken = preAuthToken;
    }

    public String getPreAuthToken() {
        return preAuthToken;
    }
}
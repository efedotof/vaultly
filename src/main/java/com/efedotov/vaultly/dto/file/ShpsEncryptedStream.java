package com.efedotov.vaultly.dto.file;

import java.io.InputStream;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public class ShpsEncryptedStream {
    private final InputStream inputStream;
    private final long contentLength;
}

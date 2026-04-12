package com.efedotov.vaultly.shirmps;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.InvalidKeyException;
import java.security.Key;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.SecureRandom;
import java.security.Signature;
import java.security.SignatureException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.zip.GZIPInputStream;
import java.util.zip.GZIPOutputStream;

import javax.crypto.Cipher;
import javax.crypto.CipherInputStream;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;

public class ShirmpsProtocol {

    private static final int GCM_TAG_LENGTH = 128; // Длина тега аутентификации в GCM-режиме
    private static final int AES_KEY_SIZE = 256; // Размер ключа AES в битах
    private static final int IV_LENGTH = 12; // Длина вектора инициализации для GCM
    private static final int BUFFER_SIZE = 8192; // Размер буфера для чтения/записи файлов
    private static final int COMPRESSION_LEVEL = 9; // Максимальный уровень сжатия GZIP
    private static final long MAX_MEMORY_FILE_SIZE = 100 * 1024 * 1024; // Максимальный размер файла для обработки в
                                                                        // памяти

    /**
     * Шифрование файла с поддержкой подписи и сжатия и гибридной схемой
     * Добавлено: гибридная схема шифрования (RSA + AES-GCM) для эффективной работы
     * с большими файлами
     * 
     * @param encryptForServer true - файл шифруется для сервера (публичный),
     *                         false - файл шифруется для пользователя (приватный)
     */
    public static void encryptFile(Path inputFile, Path outputFile,
            PublicKey userPublicKey, PublicKey serverPublicKey,
            PrivateKey userPrivateKey, boolean sign, boolean compress,
            boolean encryptForServer, String userId) throws Exception {

        long fileSize = inputFile.toFile().length();
        boolean useCompression = compress && fileSize > 1024;
        boolean useInMemory = fileSize <= MAX_MEMORY_FILE_SIZE;

        KeyGenerator keyGen = KeyGenerator.getInstance("AES");
        keyGen.init(AES_KEY_SIZE);
        SecretKey aesKey = keyGen.generateKey();

        byte[] iv = new byte[IV_LENGTH];
        SecureRandom secureRandom = new SecureRandom();
        secureRandom.nextBytes(iv);

        Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        byte[] encryptedAesKey;

        if (encryptForServer) {
            rsaCipher.init(Cipher.ENCRYPT_MODE, serverPublicKey);
        } else {
            rsaCipher.init(Cipher.ENCRYPT_MODE, userPublicKey);
        }
        encryptedAesKey = rsaCipher.doFinal(aesKey.getEncoded());

        byte[] signatureBytes = null;
        if (sign && userPrivateKey != null) {
            byte[] fileData = Files.readAllBytes(inputFile);
            Signature signature = Signature.getInstance("SHA256withRSA");
            signature.initSign(userPrivateKey);
            signature.update(fileData);
            signatureBytes = signature.sign();
        }

        ShirmpsHeader header = new ShirmpsHeader();
        header.setOriginalFileName(inputFile.getFileName().toString());
        header.setOriginalFileSize(fileSize);
        header.setEncryptedKey(Base64.getEncoder().encodeToString(encryptedAesKey));
        header.setIv(Base64.getEncoder().encodeToString(iv));
        header.setKeyOwner(encryptForServer ? "server" : "user");
        header.setUserId(userId);

        if (signatureBytes != null) {
            header.setSignature(Base64.getEncoder().encodeToString(signatureBytes));
        }

        Map<String, String> metadata = new HashMap<>();
        metadata.put("compressed", String.valueOf(useCompression));
        metadata.put("compression_ratio", "0");
        header.setMetadata(metadata);

        byte[] headerJson = header.toJsonBytes();
        int headerLength = headerJson.length;

        try (DataOutputStream dos = new DataOutputStream(
                new BufferedOutputStream(new FileOutputStream(outputFile.toFile())));
                FileInputStream fis = new FileInputStream(inputFile.toFile())) {

            dos.writeInt(headerLength);
            dos.write(headerJson);

            Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
            GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
            aesCipher.init(Cipher.ENCRYPT_MODE, aesKey, gcmSpec);

            if (useCompression) {
                if (useInMemory) {
                    byte[] fileData = Files.readAllBytes(inputFile);
                    ByteArrayOutputStream compressedData = new ByteArrayOutputStream();
                    try (GZIPOutputStream gzip = new GZIPOutputStream(compressedData) {
                        {
                            def.setLevel(COMPRESSION_LEVEL);
                        }
                    }) {
                        gzip.write(fileData);
                    }

                    double ratio = 1.0 - ((double) compressedData.size() / fileData.length);
                    metadata.put("compression_ratio", String.format("%.2f", ratio * 100));
                    header.setMetadata(metadata);

                    byte[] encrypted = aesCipher.doFinal(compressedData.toByteArray());
                    dos.write(encrypted);
                } else {
                    ByteArrayOutputStream bufferStream = new ByteArrayOutputStream(BUFFER_SIZE * 2);
                    try (GZIPOutputStream gzip = new GZIPOutputStream(bufferStream) {
                        {
                            def.setLevel(COMPRESSION_LEVEL);
                        }
                    }) {
                        byte[] buffer = new byte[BUFFER_SIZE];
                        int bytesRead;

                        while ((bytesRead = fis.read(buffer)) != -1) {
                            gzip.write(buffer, 0, bytesRead);

                            if (bufferStream.size() >= BUFFER_SIZE) {
                                byte[] compressedChunk = bufferStream.toByteArray();
                                byte[] encrypted = aesCipher.update(compressedChunk);
                                if (encrypted != null) {
                                    dos.write(encrypted);
                                }
                                bufferStream.reset();
                            }
                        }

                        gzip.finish();
                        byte[] finalCompressed = bufferStream.toByteArray();
                        byte[] encrypted = aesCipher.doFinal(finalCompressed);
                        if (encrypted != null) {
                            dos.write(encrypted);
                        }
                    }
                }
            } else {
                byte[] buffer = new byte[BUFFER_SIZE];
                int bytesRead;
                while ((bytesRead = fis.read(buffer)) != -1) {
                    byte[] encrypted = aesCipher.update(buffer, 0, bytesRead);
                    if (encrypted != null) {
                        dos.write(encrypted);
                    }
                }

                byte[] finalEncrypted = aesCipher.doFinal();
                if (finalEncrypted != null) {
                    dos.write(finalEncrypted);
                }
            }
        }
    }

    public static void decryptFile(Path inputFile, Path outputFile,
            PrivateKey userPrivateKey, PrivateKey serverPrivateKey,
            PublicKey userPublicKey) throws Exception {

        try (DataInputStream dis = new DataInputStream(
                new BufferedInputStream(new FileInputStream(inputFile.toFile())));
                FileOutputStream fos = new FileOutputStream(outputFile.toFile())) {

            // Чтение заголовка
            int headerLength = dis.readInt();
            byte[] headerBytes = new byte[headerLength];
            dis.readFully(headerBytes);
            ShirmpsHeader header = ShirmpsHeader.fromJsonBytes(headerBytes);

            PrivateKey decryptionKey;
            if ("server".equals(header.getKeyOwner())) {
                if (serverPrivateKey == null) {
                    throw new IllegalArgumentException(
                            "Для дешифрования серверного файла нужен приватный ключ сервера");
                }
                decryptionKey = serverPrivateKey;
            } else {
                decryptionKey = userPrivateKey;
            }

            byte[] encryptedAesKey = Base64.getDecoder().decode(header.getEncryptedKey());
            Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
            rsaCipher.init(Cipher.DECRYPT_MODE, decryptionKey);
            byte[] aesKeyBytes = rsaCipher.doFinal(encryptedAesKey);
            SecretKey aesKey = new SecretKeySpec(aesKeyBytes, "AES");

            byte[] iv = Base64.getDecoder().decode(header.getIv());
            Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
            GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
            aesCipher.init(Cipher.DECRYPT_MODE, aesKey, gcmSpec);

            boolean compressed = false;
            if (header.getMetadata() != null) {
                compressed = Boolean.parseBoolean(header.getMetadata().get("compressed"));
            }

            if (compressed) {
                ByteArrayOutputStream decryptedBuffer = new ByteArrayOutputStream();
                byte[] buffer = new byte[BUFFER_SIZE];
                int bytesRead;

                while ((bytesRead = dis.read(buffer)) != -1) {
                    byte[] decrypted = aesCipher.update(buffer, 0, bytesRead);
                    if (decrypted != null) {
                        decryptedBuffer.write(decrypted);
                    }
                }

                byte[] finalDecrypted = aesCipher.doFinal();
                if (finalDecrypted != null) {
                    decryptedBuffer.write(finalDecrypted);
                }

                try (GZIPInputStream gzip = new GZIPInputStream(
                        new ByteArrayInputStream(decryptedBuffer.toByteArray()))) {
                    byte[] decompressBuffer = new byte[BUFFER_SIZE];
                    int decompressedBytes;
                    while ((decompressedBytes = gzip.read(decompressBuffer)) != -1) {
                        fos.write(decompressBuffer, 0, decompressedBytes);
                    }
                }
            } else {
                byte[] buffer = new byte[BUFFER_SIZE];
                int bytesRead;
                while ((bytesRead = dis.read(buffer)) != -1) {
                    byte[] decrypted = aesCipher.update(buffer, 0, bytesRead);
                    if (decrypted != null) {
                        fos.write(decrypted);
                    }
                }

                byte[] finalDecrypted = aesCipher.doFinal();
                if (finalDecrypted != null) {
                    fos.write(finalDecrypted);
                }
            }

            if (header.getSignature() != null && userPublicKey != null) {
                byte[] decryptedData = Files.readAllBytes(outputFile);
                Signature signature = Signature.getInstance("SHA256withRSA");
                signature.initVerify(userPublicKey);
                signature.update(decryptedData);
                byte[] signatureBytes = Base64.getDecoder().decode(header.getSignature());

                if (!signature.verify(signatureBytes)) {
                    throw new SecurityException("Проверка подписи не удалась!");
                }
            }
        }
    }

    public static DecryptedInputStream createDecryptedInputStream(Path inputFile,
            PrivateKey privateKey, PublicKey publicKey) throws Exception {

        return new DecryptedInputStream(inputFile, privateKey, publicKey);
    }

    public static class DecryptedInputStream extends InputStream {
        private final DataInputStream dis;
        private final InputStream decryptedStream;
        private final ShirmpsHeader header;
        private final PublicKey publicKey;
        private boolean signatureVerified = false;
        private long bytesReadCount = 0;
        private ByteArrayOutputStream dataForSignature;
        private final boolean compressed;

        public DecryptedInputStream(Path inputFile, PrivateKey privateKey, PublicKey publicKey)
                throws Exception {

            this.publicKey = publicKey;
            this.dis = new DataInputStream(
                    new BufferedInputStream(new FileInputStream(inputFile.toFile())));

            int headerLength = dis.readInt();
            byte[] headerBytes = new byte[headerLength];
            dis.readFully(headerBytes);
            this.header = ShirmpsHeader.fromJsonBytes(headerBytes);
            boolean isCompressed = false;
            if (header.getMetadata() != null) {
                isCompressed = Boolean.parseBoolean(header.getMetadata().get("compressed"));
            }
            this.compressed = isCompressed;
            byte[] encryptedAesKey = Base64.getDecoder().decode(header.getEncryptedKey());
            Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
            rsaCipher.init(Cipher.DECRYPT_MODE, privateKey);
            byte[] aesKeyBytes = rsaCipher.doFinal(encryptedAesKey);
            SecretKey aesKey = new SecretKeySpec(aesKeyBytes, "AES");

            byte[] iv = Base64.getDecoder().decode(header.getIv());
            Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
            GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
            aesCipher.init(Cipher.DECRYPT_MODE, aesKey, gcmSpec);

            if (compressed) {
                ByteArrayOutputStream decryptedData = new ByteArrayOutputStream();
                byte[] buffer = new byte[BUFFER_SIZE];
                int bytesRead;

                while ((bytesRead = dis.read(buffer)) != -1) {
                    byte[] decrypted = aesCipher.update(buffer, 0, bytesRead);
                    if (decrypted != null) {
                        decryptedData.write(decrypted);
                    }
                }

                byte[] finalDecrypted = aesCipher.doFinal();
                if (finalDecrypted != null) {
                    decryptedData.write(finalDecrypted);
                }

                this.decryptedStream = new GZIPInputStream(
                        new java.io.ByteArrayInputStream(decryptedData.toByteArray()));
            } else {
                this.decryptedStream = new CipherInputStream(dis, aesCipher);
            }

            if (header.getSignature() != null && publicKey != null) {
                dataForSignature = new ByteArrayOutputStream();
            }
        }

        @Override
        public int read() throws IOException {
            int data = decryptedStream.read();
            if (data != -1) {
                bytesReadCount++;
                if (dataForSignature != null) {
                    dataForSignature.write(data);
                }
            } else if (bytesReadCount > 0 && !signatureVerified && dataForSignature != null) {
                verifySignature();
            }
            return data;
        }

        @Override
        public int read(byte[] b, int off, int len) throws IOException {
            int bytes = decryptedStream.read(b, off, len);
            if (bytes > 0) {
                bytesReadCount += bytes;
                if (dataForSignature != null) {
                    dataForSignature.write(b, off, bytes);
                }
            } else if (bytesReadCount > 0 && !signatureVerified && dataForSignature != null) {
                verifySignature();
            }
            return bytes;
        }

        private void verifySignature() throws IOException {
            try {
                Signature signature = Signature.getInstance("SHA256withRSA");
                signature.initVerify(publicKey);
                signature.update(dataForSignature.toByteArray());
                byte[] signatureBytes = Base64.getDecoder().decode(header.getSignature());

                signatureVerified = signature.verify(signatureBytes);
                if (!signatureVerified) {
                    throw new SecurityException("Проверка подписи не удалась!");
                }
            } catch (SecurityException | InvalidKeyException | NoSuchAlgorithmException | SignatureException e) {
                throw new IOException("Ошибка проверки подписи: " + e.getMessage(), e);
            }
        }

        public ShirmpsHeader getHeader() {
            return header;
        }

        public boolean isSignatureVerified() {
            return signatureVerified;
        }

        public boolean isCompressed() {
            return compressed;
        }

        @Override
        public void close() throws IOException {
            decryptedStream.close();
            dis.close();
            if (dataForSignature != null) {
                dataForSignature.close();
            }
        }
    }

    public static byte[] readPartialFile(Path inputFile, PrivateKey privateKey,
            PublicKey publicKey, int maxBytes) throws Exception {

        try (DecryptedInputStream dis = createDecryptedInputStream(inputFile, privateKey, publicKey)) {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            byte[] buffer = new byte[BUFFER_SIZE];
            int totalRead = 0;
            int readBytes;

            while (totalRead < maxBytes && (readBytes = dis.read(buffer, 0,
                    Math.min(buffer.length, maxBytes - totalRead))) != -1) {
                baos.write(buffer, 0, readBytes);
                totalRead += readBytes;
            }

            return baos.toByteArray();
        }
    }

    public static ShirmpsHeader readHeader(Path inputFile) throws Exception {
        try (DataInputStream dis = new DataInputStream(
                new BufferedInputStream(new FileInputStream(inputFile.toFile())))) {

            int headerLength = dis.readInt();
            byte[] headerBytes = new byte[headerLength];
            dis.readFully(headerBytes);

            return ShirmpsHeader.fromJsonBytes(headerBytes);
        }
    }

    public static String detectContentType(String fileName) {
        if (fileName == null)
            return "unknown";

        String lowerName = fileName.toLowerCase();

        // Обширный список расширений файлов и соответствующих MIME-типов
        // Источник:
        // https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types
        if (lowerName.endsWith(".txt") || lowerName.endsWith(".log") ||
                lowerName.endsWith(".ini") || lowerName.endsWith(".cfg") ||
                lowerName.endsWith(".csv") || lowerName.endsWith(".md") ||
                lowerName.endsWith(".properties")) {
            return "text/plain";
        }

        if (lowerName.endsWith(".json"))
            return "application/json";
        if (lowerName.endsWith(".xml"))
            return "application/xml";
        if (lowerName.endsWith(".yaml") || lowerName.endsWith(".yml"))
            return "application/x-yaml";
        if (lowerName.endsWith(".html") || lowerName.endsWith(".htm"))
            return "text/html";
        if (lowerName.endsWith(".css"))
            return "text/css";
        if (lowerName.endsWith(".js"))
            return "application/javascript";
        if (lowerName.endsWith(".png"))
            return "image/png";
        if (lowerName.endsWith(".jpg") || lowerName.endsWith(".jpeg") || lowerName.endsWith(".jpe"))
            return "image/jpeg";
        if (lowerName.endsWith(".gif"))
            return "image/gif";
        if (lowerName.endsWith(".bmp"))
            return "image/bmp";
        if (lowerName.endsWith(".svg"))
            return "image/svg+xml";
        if (lowerName.endsWith(".webp"))
            return "image/webp";
        if (lowerName.endsWith(".ico"))
            return "image/x-icon";
        if (lowerName.endsWith(".tiff") || lowerName.endsWith(".tif"))
            return "image/tiff";
        if (lowerName.endsWith(".pdf"))
            return "application/pdf";
        if (lowerName.endsWith(".doc"))
            return "application/msword";
        if (lowerName.endsWith(".docx"))
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
        if (lowerName.endsWith(".xls"))
            return "application/vnd.ms-excel";
        if (lowerName.endsWith(".xlsx"))
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
        if (lowerName.endsWith(".ppt"))
            return "application/vnd.ms-powerpoint";
        if (lowerName.endsWith(".pptx"))
            return "application/vnd.openxmlformats-officedocument.presentationml.presentation";
        if (lowerName.endsWith(".odt"))
            return "application/vnd.oasis.opendocument.text";
        if (lowerName.endsWith(".ods"))
            return "application/vnd.oasis.opendocument.spreadsheet";
        if (lowerName.endsWith(".odp"))
            return "application/vnd.oasis.opendocument.presentation";
        if (lowerName.endsWith(".zip"))
            return "application/zip";
        if (lowerName.endsWith(".rar"))
            return "application/x-rar-compressed";
        if (lowerName.endsWith(".7z"))
            return "application/x-7z-compressed";
        if (lowerName.endsWith(".tar"))
            return "application/x-tar";
        if (lowerName.endsWith(".gz"))
            return "application/gzip";
        if (lowerName.endsWith(".bz2"))
            return "application/x-bzip2";
        if (lowerName.endsWith(".xz"))
            return "application/x-xz";
        if (lowerName.endsWith(".mp3"))
            return "audio/mpeg";
        if (lowerName.endsWith(".wav"))
            return "audio/wav";
        if (lowerName.endsWith(".ogg"))
            return "audio/ogg";
        if (lowerName.endsWith(".flac"))
            return "audio/flac";
        if (lowerName.endsWith(".aac"))
            return "audio/aac";
        if (lowerName.endsWith(".mp4"))
            return "video/mp4";
        if (lowerName.endsWith(".avi"))
            return "video/x-msvideo";
        if (lowerName.endsWith(".mov"))
            return "video/quicktime";
        if (lowerName.endsWith(".wmv"))
            return "video/x-ms-wmv";
        if (lowerName.endsWith(".mkv"))
            return "video/x-matroska";
        if (lowerName.endsWith(".webm"))
            return "video/webm";
        if (lowerName.endsWith(".flv"))
            return "video/x-flv";
        if (lowerName.endsWith(".mpeg") || lowerName.endsWith(".mpg"))
            return "video/mpeg";
        if (lowerName.endsWith(".exe"))
            return "application/x-msdownload";
        if (lowerName.endsWith(".msi"))
            return "application/x-msdownload";
        if (lowerName.endsWith(".deb"))
            return "application/x-debian-package";
        if (lowerName.endsWith(".rpm"))
            return "application/x-rpm";
        if (lowerName.endsWith(".apk"))
            return "application/vnd.android.package-archive";
        if (lowerName.endsWith(".jar"))
            return "application/java-archive";
        if (lowerName.endsWith(".war"))
            return "application/java-archive";
        if (lowerName.endsWith(".ear"))
            return "application/java-archive";
        if (lowerName.endsWith(".class"))
            return "application/java-vm";
        if (lowerName.endsWith(".py"))
            return "text/x-python";
        if (lowerName.endsWith(".java"))
            return "text/x-java-source";
        if (lowerName.endsWith(".c"))
            return "text/x-c";
        if (lowerName.endsWith(".cpp") || lowerName.endsWith(".cc") || lowerName.endsWith(".cxx"))
            return "text/x-c++src";
        if (lowerName.endsWith(".h") || lowerName.endsWith(".hpp"))
            return "text/x-c++hdr";
        if (lowerName.endsWith(".cs"))
            return "text/x-csharp";
        if (lowerName.endsWith(".php"))
            return "application/x-php";
        if (lowerName.endsWith(".pl") || lowerName.endsWith(".pm"))
            return "application/x-perl";
        if (lowerName.endsWith(".rb"))
            return "application/x-ruby";
        if (lowerName.endsWith(".go"))
            return "text/x-go";
        if (lowerName.endsWith(".rs"))
            return "text/x-rust";
        if (lowerName.endsWith(".swift"))
            return "text/x-swift";
        if (lowerName.endsWith(".kt") || lowerName.endsWith(".kts"))
            return "text/x-kotlin";
        if (lowerName.endsWith(".sql"))
            return "application/sql";
        if (lowerName.endsWith(".sh"))
            return "application/x-sh";
        if (lowerName.endsWith(".bat"))
            return "application/x-msdos-program";
        if (lowerName.endsWith(".cmd"))
            return "application/cmd";
        if (lowerName.endsWith(".ps1"))
            return "application/x-powershell";
        if (lowerName.endsWith(".vbs"))
            return "application/x-vbscript";
        if (lowerName.endsWith(".reg"))
            return "application/x-windows-registry";
        if (lowerName.endsWith(".dll"))
            return "application/x-msdownload";
        if (lowerName.endsWith(".so"))
            return "application/x-sharedlib";
        if (lowerName.endsWith(".dylib"))
            return "application/x-mach-binary";
        if (lowerName.endsWith(".ttf"))
            return "font/ttf";
        if (lowerName.endsWith(".otf"))
            return "font/otf";
        if (lowerName.endsWith(".woff"))
            return "font/woff";
        if (lowerName.endsWith(".woff2"))
            return "font/woff2";
        if (lowerName.endsWith(".eot"))
            return "application/vnd.ms-fontobject";
        if (lowerName.endsWith(".rtf"))
            return "application/rtf";
        if (lowerName.endsWith(".csv"))
            return "text/csv";
        if (lowerName.endsWith(".tsv"))
            return "text/tab-separated-values";
        if (lowerName.endsWith(".ics"))
            return "text/calendar";
        if (lowerName.endsWith(".vcf"))
            return "text/vcard";
        if (lowerName.endsWith(".eml") || lowerName.endsWith(".msg"))
            return "message/rfc822";
        if (lowerName.endsWith(".mdb"))
            return "application/x-msaccess";
        if (lowerName.endsWith(".accdb"))
            return "application/x-msaccess";
        if (lowerName.endsWith(".torrent"))
            return "application/x-bittorrent";
        if (lowerName.endsWith(".epub"))
            return "application/epub+zip";
        if (lowerName.endsWith(".mobi"))
            return "application/x-mobipocket-ebook";
        if (lowerName.endsWith(".azw") || lowerName.endsWith(".azw3"))
            return "application/vnd.amazon.ebook";
        if (lowerName.endsWith(".fb2"))
            return "application/x-fictionbook+xml";
        if (lowerName.endsWith(".djvu") || lowerName.endsWith(".djv"))
            return "image/vnd.djvu";
        if (lowerName.endsWith(".psd"))
            return "image/vnd.adobe.photoshop";
        if (lowerName.endsWith(".ai"))
            return "application/postscript";
        if (lowerName.endsWith(".eps"))
            return "application/postscript";
        if (lowerName.endsWith(".ps"))
            return "application/postscript";
        if (lowerName.endsWith(".skp"))
            return "application/vnd.sketchup.skp";
        if (lowerName.endsWith(".stl"))
            return "application/vnd.ms-pki.stl";
        if (lowerName.endsWith(".obj"))
            return "application/x-tgif";
        if (lowerName.endsWith(".fbx"))
            return "application/octet-stream";
        if (lowerName.endsWith(".blend"))
            return "application/x-blender";
        if (lowerName.endsWith(".unitypackage"))
            return "application/unitypackage";
        if (lowerName.endsWith(".cr2") || lowerName.endsWith(".cr3"))
            return "image/x-canon-cr2";
        if (lowerName.endsWith(".nef"))
            return "image/x-nikon-nef";
        if (lowerName.endsWith(".arw"))
            return "image/x-sony-arw";
        if (lowerName.endsWith(".iso"))
            return "application/x-iso9660-image";
        if (lowerName.endsWith(".img"))
            return "application/x-raw-disk-image";
        if (lowerName.endsWith(".vhd") || lowerName.endsWith(".vhdx"))
            return "application/x-vhd";
        if (lowerName.endsWith(".ova") || lowerName.endsWith(".ovf"))
            return "application/x-virtualbox-ova";
        if (lowerName.endsWith(".vmx"))
            return "application/x-vmware-vmx";
        if (lowerName.endsWith(".vmdk"))
            return "application/x-vmdk";
        if (lowerName.endsWith(".dockerfile"))
            return "text/plain";
        if (lowerName.endsWith(".yaml") || lowerName.endsWith(".yml"))
            return "text/plain";
        if (lowerName.endsWith(".toml"))
            return "application/toml";
        if (lowerName.endsWith(".env"))
            return "text/plain";
        if (lowerName.endsWith(".gitignore"))
            return "text/plain";
        if (lowerName.endsWith(".license"))
            return "text/plain";
        if (lowerName.endsWith(".readme"))
            return "text/plain";
        if (lowerName.endsWith(".shps"))
            return "application/x-shirmps";

        return "application/octet-stream";
    }

    public static KeyPair generateKeyPair() throws NoSuchAlgorithmException {
        KeyPairGenerator keyGen = KeyPairGenerator.getInstance("RSA");
        keyGen.initialize(2048);
        return keyGen.generateKeyPair();
    }

    public static void saveKeyToFile(Key key, Path filePath) throws IOException {
        byte[] keyBytes = key.getEncoded();
        Files.write(filePath, keyBytes);
    }

    public static PublicKey loadPublicKey(Path filePath) throws Exception {
        byte[] keyBytes = Files.readAllBytes(filePath);
        X509EncodedKeySpec spec = new X509EncodedKeySpec(keyBytes);
        KeyFactory kf = KeyFactory.getInstance("RSA");
        return kf.generatePublic(spec);
    }

    public static PrivateKey loadPrivateKey(Path filePath) throws Exception {
        byte[] keyBytes = Files.readAllBytes(filePath);
        PKCS8EncodedKeySpec spec = new PKCS8EncodedKeySpec(keyBytes);
        KeyFactory kf = KeyFactory.getInstance("RSA");
        return kf.generatePrivate(spec);
    }

    public static boolean verifySignature(Path inputFile, PrivateKey privateKey, PublicKey publicKey) throws Exception {
        try (DecryptedInputStream dis = createDecryptedInputStream(inputFile, privateKey, publicKey)) {
            byte[] buffer = new byte[BUFFER_SIZE];
            while (dis.read(buffer) != -1) {

            }

            return dis.isSignatureVerified();
        } catch (SecurityException e) {
            return false;
        }
    }

    public static boolean testKeyAccess(Path inputFile, PrivateKey privateKey) throws Exception {
        try {
            ShirmpsHeader header = readHeader(inputFile);
            byte[] encryptedAesKey = Base64.getDecoder().decode(header.getEncryptedKey());

            Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
            rsaCipher.init(Cipher.DECRYPT_MODE, privateKey);

            byte[] aesKeyBytes = rsaCipher.doFinal(encryptedAesKey);
            return aesKeyBytes.length > 0;
        } catch (Exception e) {
            return false;
        }
    }

    public static class HybridDecryptedInputStream extends InputStream {
        private final DataInputStream dis;
        private final InputStream decryptedStream;
        private final ShirmpsHeader header;
        private final PublicKey userPublicKey;
        private boolean signatureVerified = false;
        private long bytesReadCount = 0;
        private ByteArrayOutputStream dataForSignature;
        private final boolean compressed;

        public HybridDecryptedInputStream(Path inputFile,
                PrivateKey userPrivateKey, PrivateKey serverPrivateKey,
                PublicKey userPublicKey) throws Exception {

            this.userPublicKey = userPublicKey;
            this.dis = new DataInputStream(
                    new BufferedInputStream(new FileInputStream(inputFile.toFile())));

            int headerLength = dis.readInt();
            byte[] headerBytes = new byte[headerLength];
            dis.readFully(headerBytes);
            this.header = ShirmpsHeader.fromJsonBytes(headerBytes);

            PrivateKey decryptionKey;
            if ("server".equals(header.getKeyOwner())) {
                if (serverPrivateKey == null) {
                    throw new IllegalArgumentException(
                            "Для дешифрования серверного файла нужен приватный ключ сервера");
                }
                decryptionKey = serverPrivateKey;
            } else {
                decryptionKey = userPrivateKey;
            }

            boolean isCompressed = false;
            if (header.getMetadata() != null) {
                isCompressed = Boolean.parseBoolean(header.getMetadata().get("compressed"));
            }
            this.compressed = isCompressed;

            byte[] encryptedAesKey = Base64.getDecoder().decode(header.getEncryptedKey());
            Cipher rsaCipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
            rsaCipher.init(Cipher.DECRYPT_MODE, decryptionKey);
            byte[] aesKeyBytes = rsaCipher.doFinal(encryptedAesKey);
            SecretKey aesKey = new SecretKeySpec(aesKeyBytes, "AES");

            byte[] iv = Base64.getDecoder().decode(header.getIv());
            Cipher aesCipher = Cipher.getInstance("AES/GCM/NoPadding");
            GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
            aesCipher.init(Cipher.DECRYPT_MODE, aesKey, gcmSpec);

            if (compressed) {
                ByteArrayOutputStream decryptedData = new ByteArrayOutputStream();
                byte[] buffer = new byte[BUFFER_SIZE];
                int bytesRead;

                while ((bytesRead = dis.read(buffer)) != -1) {
                    byte[] decrypted = aesCipher.update(buffer, 0, bytesRead);
                    if (decrypted != null) {
                        decryptedData.write(decrypted);
                    }
                }

                byte[] finalDecrypted = aesCipher.doFinal();
                if (finalDecrypted != null) {
                    decryptedData.write(finalDecrypted);
                }

                this.decryptedStream = new GZIPInputStream(
                        new ByteArrayInputStream(decryptedData.toByteArray()));
            } else {
                this.decryptedStream = new CipherInputStream(dis, aesCipher);
            }

            if (header.getSignature() != null && userPublicKey != null) {
                dataForSignature = new ByteArrayOutputStream();
            }
        }

        @Override
        public int read() throws IOException {
            int data = decryptedStream.read();
            if (data != -1) {
                bytesReadCount++;
                if (dataForSignature != null) {
                    dataForSignature.write(data);
                }
            } else if (bytesReadCount > 0 && !signatureVerified && dataForSignature != null) {
                verifySignature();
            }
            return data;
        }

        @Override
        public int read(byte[] b, int off, int len) throws IOException {
            int bytes = decryptedStream.read(b, off, len);
            if (bytes > 0) {
                bytesReadCount += bytes;
                if (dataForSignature != null) {
                    dataForSignature.write(b, off, bytes);
                }
            } else if (bytesReadCount > 0 && !signatureVerified && dataForSignature != null) {
                verifySignature();
            }
            return bytes;
        }

        private void verifySignature() throws IOException {
            try {
                Signature signature = Signature.getInstance("SHA256withRSA");
                signature.initVerify(userPublicKey);
                signature.update(dataForSignature.toByteArray());
                byte[] signatureBytes = Base64.getDecoder().decode(header.getSignature());

                signatureVerified = signature.verify(signatureBytes);
                if (!signatureVerified) {
                    throw new SecurityException("Проверка подписи не удалась!");
                }
            } catch (SecurityException | InvalidKeyException | NoSuchAlgorithmException | SignatureException e) {
                throw new IOException("Ошибка проверки подписи: " + e.getMessage(), e);
            }
        }

        public ShirmpsHeader getHeader() {
            return header;
        }

        public boolean isSignatureVerified() {
            return signatureVerified;
        }

        public boolean isCompressed() {
            return compressed;
        }

        public String getKeyOwner() {
            return header.getKeyOwner();
        }

        public String getUserId() {
            return header.getUserId();
        }

        @Override
        public void close() throws IOException {
            decryptedStream.close();
            dis.close();
            if (dataForSignature != null) {
                dataForSignature.close();
            }
        }
    }

    public static boolean isPublicFile(Path inputFile) throws Exception {
        ShirmpsHeader header = readHeader(inputFile);
        return "server".equals(header.getKeyOwner());
    }

    public static boolean isPrivateFile(Path inputFile) throws Exception {
        ShirmpsHeader header = readHeader(inputFile);
        return "user".equals(header.getKeyOwner());
    }

    public static String getFileOwnerId(Path inputFile) throws Exception {
        ShirmpsHeader header = readHeader(inputFile);
        return header.getUserId();
    }
}
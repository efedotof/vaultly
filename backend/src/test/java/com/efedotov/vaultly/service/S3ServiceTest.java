package com.efedotov.vaultly.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.test.util.ReflectionTestUtils;
import software.amazon.awssdk.core.ResponseInputStream;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.core.sync.ResponseTransformer;
import software.amazon.awssdk.http.AbortableInputStream;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectResponse;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;
import java.util.UUID;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class S3ServiceTest {

    @Mock
    S3Client s3Client;
    @Mock
    S3Presigner s3Presigner;

    private S3Service service;

    @BeforeEach
    void setUp() {
        service = new S3Service(s3Client, s3Presigner);
        ReflectionTestUtils.setField(service, "bucketName", "test-bucket");
        ReflectionTestUtils.setField(service, "s3PublicUrl", "https://cdn.example.com");
        ReflectionTestUtils.setField(service, "s3Endpoint", "https://s3.example.com");
    }

    @Test
    void getPublicUrl_null_returnsNull() {
        assertThat(service.getPublicUrl(null)).isNull();
    }

    @Test
    void getPublicUrl_withPublicUrlBase_returnsCdnUrl() {
        assertThat(service.getPublicUrl("file.shps"))
                .isEqualTo("https://cdn.example.com/file.shps");
    }

    @Test
    void getPublicUrl_noPublicUrl_fallsBackToEndpoint() {
        ReflectionTestUtils.setField(service, "s3PublicUrl", "");
        assertThat(service.getPublicUrl("file.shps"))
                .isEqualTo("https://s3.example.com/test-bucket/file.shps");
    }

    @Test
    void getObjectKeyFromUrl_nullOrBlank_returnsNull() {
        assertThat(service.getObjectKeyFromUrl(null)).isNull();
        assertThat(service.getObjectKeyFromUrl("")).isNull();
        assertThat(service.getObjectKeyFromUrl("   ")).isNull();
    }

    @Test
    void getObjectKeyFromUrl_plainKey_returnsAsIs() {
        assertThat(service.getObjectKeyFromUrl("abc.shps")).isEqualTo("abc.shps");
    }

    @Test
    void getObjectKeyFromUrl_cdnUrl_stripsPrefix() {
        assertThat(service.getObjectKeyFromUrl("https://cdn.example.com/my-file.shps"))
                .isEqualTo("my-file.shps");
    }

    @Test
    void getObjectKeyFromUrl_cdnUrlWithoutSlash_stripsPrefix() {
        assertThat(service.getObjectKeyFromUrl("https://cdn.example.comab.shps"))
                .isEqualTo("ab.shps");
    }

    @Test
    void getObjectKeyFromUrl_s3Url_takesLastSegment() {
        assertThat(service.getObjectKeyFromUrl("https://s3.example.com/bucket/sub/file.shps"))
                .isEqualTo("file.shps");
    }

    @Test
    void getObjectKeyFromUrl_invalidUri_returnsNull() {
        assertThat(service.getObjectKeyFromUrl("https://bad uri with spaces/x")).isNull();
    }

    @Test
    void uploadFileWithMultipart_validShps_uploadsAndReturnsKey() throws Exception {
        Path file = Files.createTempFile("test", ".shps");
        Files.writeString(file, "payload");
        try {
            when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                    .thenReturn(PutObjectResponse.builder().build());

            String key = service.uploadFileWithMultipart(file, "original.shps", "application/x-shirmps");

            assertThat(key).endsWith(".shps");
            verify(s3Client).putObject(any(PutObjectRequest.class), any(RequestBody.class));
        } finally {
            Files.deleteIfExists(file);
        }
    }

    @Test
    void uploadFileWithMultipart_nonShpsExtension_throws() throws Exception {
        Path file = Files.createTempFile("test", ".txt");
        try {
            assertThatThrownBy(() -> service.uploadFileWithMultipart(file, "bad.txt", "text/plain"))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining(".shps");
            verify(s3Client, never()).putObject(any(PutObjectRequest.class), any(RequestBody.class));
        } finally {
            Files.deleteIfExists(file);
        }
    }

    @Test
    void uploadFileWithMultipart_uppercaseExtension_accepted() throws Exception {
        Path file = Files.createTempFile("test", ".SHPS");
        Files.writeString(file, "x");
        try {
            when(s3Client.putObject(any(PutObjectRequest.class), any(RequestBody.class)))
                    .thenReturn(PutObjectResponse.builder().build());

            String key = service.uploadFileWithMultipart(file, "FILE.SHPS", "application/x-shirmps");
            assertThat(key).endsWith(".shps");
        } finally {
            Files.deleteIfExists(file);
        }
    }

    @Test
    void generatePresignedUrl_returnsUrl() throws Exception {
        PresignedGetObjectRequest presigned = org.mockito.Mockito.mock(PresignedGetObjectRequest.class);
        when(presigned.url()).thenReturn(URI.create("https://presigned.example.com/x").toURL());
        when(s3Presigner.presignGetObject(any(GetObjectPresignRequest.class)))
                .thenReturn(presigned);

        String url = service.generatePresignedUrl("key.shps", Duration.ofMinutes(5));

        assertThat(url).isEqualTo("https://presigned.example.com/x");
    }

    @Test
    void downloadFile_returnsBytes() throws Exception {
        byte[] payload = "downloaded".getBytes(StandardCharsets.UTF_8);
        ResponseInputStream<GetObjectResponse> response = mockGetObjectResponse(payload);
        when(s3Client.getObject(any(GetObjectRequest.class))).thenReturn(response);

        byte[] result = service.downloadFile("key.shps");

        assertThat(result).isEqualTo(payload);
    }

    @Test
    @SuppressWarnings("unchecked")
    void getObjectStream_returnsStream() {
        byte[] payload = "streamed".getBytes(StandardCharsets.UTF_8);
        InputStream stream = new ByteArrayInputStream(payload);
        when(s3Client.getObject(any(GetObjectRequest.class), any(ResponseTransformer.class)))
                .thenReturn(stream);

        InputStream result = service.getObjectStream("key.shps");

        assertThat(result).isSameAs(stream);
    }

    @Test
    void streamFileTo_writesToOutput() throws Exception {
        byte[] payload = "to-stream".getBytes(StandardCharsets.UTF_8);
        ResponseInputStream<GetObjectResponse> response = mockGetObjectResponse(payload);
        when(s3Client.getObject(any(GetObjectRequest.class))).thenReturn(response);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        service.streamFileTo("key.shps", out);

        assertThat(out.toByteArray()).isEqualTo(payload);
    }

    @Test
    void deleteFile_nullUrl_doesNothing() {
        service.deleteFile(null);
        verify(s3Client, never()).deleteObject(any(DeleteObjectRequest.class));
    }

    @Test
    void deleteFile_blankUrl_doesNothing() {
        service.deleteFile("   ");
        verify(s3Client, never()).deleteObject(any(DeleteObjectRequest.class));
    }

    @Test
    void deleteFile_validUrl_deletesKey() {
        service.deleteFile("https://cdn.example.com/abc.shps");
        verify(s3Client).deleteObject(any(DeleteObjectRequest.class));
    }

    @Test
    void deleteFile_plainKey_deletes() {
        service.deleteFile("plain-key.shps");
        verify(s3Client).deleteObject(any(DeleteObjectRequest.class));
    }

    @Test
    void deleteFile_cannotParseKey_doesNotCallS3() {
        service.deleteFile("https://bad uri with spaces/x");
        verify(s3Client, never()).deleteObject(any(DeleteObjectRequest.class));
    }

    private ResponseInputStream<GetObjectResponse> mockGetObjectResponse(byte[] payload) {
        AbortableInputStream stream = AbortableInputStream.create(
                new ByteArrayInputStream(payload));
        return new ResponseInputStream<>(
                GetObjectResponse.builder().build(),
                stream);
    }

    @Test
    void uploadFileWithMultipart_ioException_throwsRuntime() throws Exception {

        Path nonexistent = Path.of("/tmp/definitely-not-here-" + UUID.randomUUID() + ".shps");

        assertThatThrownBy(() -> service.uploadFileWithMultipart(nonexistent, "x.shps", "application/x-shirmps"))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Failed to upload file");
    }

    @Test
    void downloadFile_ioException_throwsRuntime() {

        ResponseInputStream<GetObjectResponse> bad = mockGetObjectResponseThrowingIO();
        when(s3Client.getObject(any(GetObjectRequest.class))).thenReturn(bad);

        assertThatThrownBy(() -> service.downloadFile("k"))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Failed to read file data");
    }

    @Test
    void streamFileTo_ioException_throwsRuntime() throws Exception {
        ResponseInputStream<GetObjectResponse> bad = mockGetObjectResponseThrowingIO();
        when(s3Client.getObject(any(GetObjectRequest.class))).thenReturn(bad);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        assertThatThrownBy(() -> service.streamFileTo("k", out))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void getObjectKeyFromUrl_urlExactlyMatchesPublicBase_returnsEmptyString() {

        assertThat(service.getObjectKeyFromUrl("https://cdn.example.com")).isEmpty();
    }

    @Test
    void getObjectKeyFromUrl_foreignUrlNoPath_returnsNull() {

        ReflectionTestUtils.setField(service, "s3PublicUrl", "");
        assertThat(service.getObjectKeyFromUrl("https://other.example.com")).isNull();
    }

    private ResponseInputStream<GetObjectResponse> mockGetObjectResponseThrowingIO() {
        InputStream broken = new InputStream() {
            @Override
            public int read() throws java.io.IOException {
                throw new java.io.IOException("boom");
            }
        };
        AbortableInputStream abortable = AbortableInputStream.create(broken);
        return new ResponseInputStream<>(GetObjectResponse.builder().build(), abortable);
    }
}
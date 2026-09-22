package com.efedotov.vaultly.service;

import com.efedotov.vaultly.dto.file.DecryptionMetadata;
import com.efedotov.vaultly.dto.file.FileDto;
import com.efedotov.vaultly.exception.BadRequestException;
import com.efedotov.vaultly.exception.ForbiddenException;
import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.model.FileContent;
import com.efedotov.vaultly.model.Folder;
import com.efedotov.vaultly.model.TempFileAccess;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.FileContentRepository;
import com.efedotov.vaultly.repository.FileRepository;
import com.efedotov.vaultly.repository.FolderRepository;
import com.efedotov.vaultly.repository.UserRepository;
import com.efedotov.vaultly.shirmps.ShirmpsHeader;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.mock.web.MockMultipartFile;
import static org.mockito.ArgumentMatchers.anyLong;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.OAEPParameterSpec;
import javax.crypto.spec.PSource;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.spec.MGF1ParameterSpec;
import java.util.Base64;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class FileServiceTest {

        @Mock
        FileRepository fileRepository;
        @Mock
        UserRepository userRepository;
        @Mock
        FolderRepository folderRepository;
        @Mock
        S3Service s3Service;
        @Mock
        ShpsSecurityService shpsSecurityService;
        @Mock
        ServerKeyService serverKeyService;
        @Mock
        UserKeyService userKeyService;
        @Mock
        FileContentRepository fileContentRepository;
        @Mock
        ShpsEncryptionService shpsEncryptionService;

        @InjectMocks
        FileService service;

        private UUID userId;
        private User currentUser;

        @BeforeEach
        void setUp() {
                userId = UUID.randomUUID();
                currentUser = User.builder().id(userId).username("alice").isActive(true).build();
                when(userRepository.findById(userId)).thenReturn(Optional.of(currentUser));
        }

        private ShirmpsHeader header(String keyOwner, String ownerId) {
                ShirmpsHeader h = new ShirmpsHeader();
                h.setVersion("1.0");
                h.setAlgorithm("AES-256-GCM");
                h.setKeyEncryption("RSA-OAEP");
                h.setKeyOwner(keyOwner);
                h.setUserId(ownerId);
                h.setOriginalFileSize(100L);
                h.setEncryptedKey("AAAA");
                h.setIv("BBBB");
                return h;
        }

        private byte[] shpsContainer(int headerLength) throws Exception {
                ByteArrayOutputStream baos = new ByteArrayOutputStream();
                try (DataOutputStream dos = new DataOutputStream(baos)) {
                        dos.writeInt(headerLength);
                        dos.write(new byte[headerLength + 16]);
                }
                return baos.toByteArray();
        }

        private MockMultipartFile multipart(String filename, byte[] content) {
                return new MockMultipartFile("file", filename, "application/x-shirmps", content);
        }

        private FileContent content(String s3Key, boolean isPublic) {
                return FileContent.builder()
                                .id(UUID.randomUUID())
                                .s3Key(s3Key)
                                .s3Url("https://cdn/" + s3Key)
                                .size(100L)
                                .mimeType("application/x-shirmps")
                                .isPublic(isPublic)
                                .build();
        }

        private File file(FileContent content, boolean isPublic) {
                return File.builder()
                                .id(UUID.randomUUID())
                                .name("doc")
                                .originalName("doc")
                                .user(currentUser)
                                .fileContent(content)
                                .size(content.getSize())
                                .mimeType(content.getMimeType())
                                .isEncrypted(true)
                                .isPublic(isPublic)
                                .isNote(false)
                                .build();
        }

        @Test
        void uploadShpsFile_nullFilename_throws() {
                MockMultipartFile file = new MockMultipartFile("file", null, null, new byte[0]);

                assertThatThrownBy(() -> service.uploadShpsFile(file, null, false, null, userId))
                                .isInstanceOf(BadRequestException.class)
                                .hasMessageContaining("Filename");
        }

        @Test
        void uploadShpsFile_blankFilename_throws() {
                MockMultipartFile file = multipart("   ", new byte[0]);

                assertThatThrownBy(() -> service.uploadShpsFile(file, null, false, null, userId))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void uploadShpsFile_invalidContentHashFormat_throws() throws Exception {
                MockMultipartFile file = multipart("doc.shps", shpsContainer(100));

                assertThatThrownBy(() -> service.uploadShpsFile(
                                file, null, false, "NOT-HEX-HASH", userId))
                                .isInstanceOf(BadRequestException.class)
                                .hasMessageContaining("64-char lowercase hex");
        }

        @Test
        void uploadShpsFile_badHeaderLength_throws() throws Exception {

                byte[] bad = new byte[] { 0, 0, 0, 0, 1, 2, 3 };
                MockMultipartFile file = multipart("doc.shps", bad);

                assertThatThrownBy(() -> service.uploadShpsFile(file, null, false, null, userId))
                                .isInstanceOf(SecurityException.class)
                                .hasMessageContaining("header length");
        }

        @Test
        void uploadShpsFile_dedupExistingOwned_createsLink() throws Exception {
                String hash = "a".repeat(64);
                FileContent existing = content("existing-key", false);

                when(fileContentRepository.findByHashAndIsPublic(hash, false))
                                .thenReturn(Optional.of(existing));
                when(fileRepository.existsByUserIdAndFileContentId(userId, existing.getId()))
                                .thenReturn(true);
                when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

                MockMultipartFile file = multipart("doc.shps", shpsContainer(100));
                FileDto dto = service.uploadShpsFile(file, null, false, hash, userId);

                assertThat(dto).isNotNull();

                verify(s3Service, never()).uploadFileWithMultipart(any(), anyString(), anyString());
        }

        @Test
        void uploadShpsFile_dedupExistingNotOwned_throws() throws Exception {
                String hash = "a".repeat(64);
                FileContent existing = content("existing-key", false);

                when(fileContentRepository.findByHashAndIsPublic(hash, false))
                                .thenReturn(Optional.of(existing));
                when(fileRepository.existsByUserIdAndFileContentId(userId, existing.getId()))
                                .thenReturn(false);

                MockMultipartFile file = multipart("doc.shps", shpsContainer(100));

                assertThatThrownBy(() -> service.uploadShpsFile(file, null, false, hash, userId))
                                .isInstanceOf(BadRequestException.class)
                                .hasMessageContaining("not yours");
        }

        @Test
        void uploadShpsFile_private_wrongKeyOwner_throws() throws Exception {
                MockMultipartFile file = multipart("doc.shps", shpsContainer(100));

                when(shpsSecurityService.validateHeaderOnly(any(java.nio.file.Path.class), eq("doc.shps")))
                                .thenReturn(header("server", userId.toString()));

                assertThatThrownBy(() -> service.uploadShpsFile(file, null, false, null, userId))
                                .isInstanceOf(SecurityException.class)
                                .hasMessageContaining("must be encrypted for user");
        }

        @Test
        void uploadShpsFile_private_wrongUserId_throws() throws Exception {
                MockMultipartFile file = multipart("doc.shps", shpsContainer(100));

                when(shpsSecurityService.validateHeaderOnly(any(java.nio.file.Path.class), eq("doc.shps")))
                                .thenReturn(header("user", UUID.randomUUID().toString()));

                assertThatThrownBy(() -> service.uploadShpsFile(file, null, false, null, userId))
                                .isInstanceOf(SecurityException.class)
                                .hasMessageContaining("different user");
        }

        @Test
        void uploadShpsFile_private_success() throws Exception {
                MockMultipartFile file = multipart("doc.shps", shpsContainer(100));

                when(shpsSecurityService.validateHeaderOnly(any(java.nio.file.Path.class), eq("doc.shps")))
                                .thenReturn(header("user", userId.toString()));
                when(s3Service.uploadFileWithMultipart(any(), anyString(), anyString()))
                                .thenReturn("new-s3-key");
                when(s3Service.getPublicUrl("new-s3-key")).thenReturn("https://cdn/new-s3-key");
                when(fileContentRepository.save(any(FileContent.class)))
                                .thenAnswer(inv -> inv.getArgument(0));
                when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

                FileDto dto = service.uploadShpsFile(file, null, false, null, userId);

                assertThat(dto.getName()).isEqualTo("doc.shps");
                assertThat(dto.getIsPublic()).isFalse();
                verify(s3Service).uploadFileWithMultipart(any(), eq("doc.shps"), anyString());
        }

        @Test
        void uploadShpsFile_public_wrongKeyOwner_throws() throws Exception {
                MockMultipartFile file = multipart("doc.shps", shpsContainer(100));

                when(shpsSecurityService.validateHeaderOnly(any(java.nio.file.Path.class), eq("doc.shps")))
                                .thenReturn(header("user", userId.toString()));

                assertThatThrownBy(() -> service.uploadShpsFile(file, null, true, null, userId))
                                .isInstanceOf(SecurityException.class)
                                .hasMessageContaining("must be encrypted for server");
        }

        @Test
        void uploadShpsFile_public_success() throws Exception {
                MockMultipartFile file = multipart("doc.shps", shpsContainer(100));

                when(shpsSecurityService.validateHeaderOnly(any(java.nio.file.Path.class), eq("doc.shps")))
                                .thenReturn(header("server", userId.toString()));
                when(shpsSecurityService.validateAndVerifyStreaming(
                                any(java.nio.file.Path.class), eq(userId), eq("doc.shps")))
                                .thenReturn(true);
                when(s3Service.uploadFileWithMultipart(any(), anyString(), anyString()))
                                .thenReturn("s3-key");
                when(s3Service.getPublicUrl("s3-key")).thenReturn("https://cdn/s3-key");
                when(fileContentRepository.save(any(FileContent.class)))
                                .thenAnswer(inv -> inv.getArgument(0));
                when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

                FileDto dto = service.uploadShpsFile(file, null, true, null, userId);

                assertThat(dto.getIsPublic()).isTrue();
        }

        @Test
        void uploadShpsFile_dbFailure_rollsBackS3() throws Exception {
                MockMultipartFile file = multipart("doc.shps", shpsContainer(100));

                when(shpsSecurityService.validateHeaderOnly(any(java.nio.file.Path.class), eq("doc.shps")))
                                .thenReturn(header("user", userId.toString()));
                when(s3Service.uploadFileWithMultipart(any(), anyString(), anyString()))
                                .thenReturn("s3-key");
                when(s3Service.getPublicUrl("s3-key")).thenReturn("https://cdn/s3-key");
                when(fileContentRepository.save(any(FileContent.class)))
                                .thenThrow(new RuntimeException("DB down"));

                assertThatThrownBy(() -> service.uploadShpsFile(file, null, false, null, userId))
                                .isInstanceOf(RuntimeException.class)
                                .hasMessageContaining("DB down");

                verify(s3Service).deleteFile("https://cdn/s3-key");
        }

        @Test
        void uploadShpsFile_filenameWithoutShpsExtension_appendsSuffix() throws Exception {
                MockMultipartFile file = multipart("doc.txt", shpsContainer(100));

                when(shpsSecurityService.validateHeaderOnly(any(java.nio.file.Path.class), eq("doc.txt")))
                                .thenReturn(header("user", userId.toString()));
                when(s3Service.uploadFileWithMultipart(any(), anyString(), anyString()))
                                .thenReturn("s3-key");
                when(s3Service.getPublicUrl("s3-key")).thenReturn("https://cdn/s3-key");
                when(fileContentRepository.save(any(FileContent.class)))
                                .thenAnswer(inv -> inv.getArgument(0));
                when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

                service.uploadShpsFile(file, null, false, null, userId);

                verify(s3Service).uploadFileWithMultipart(any(), eq("doc.txt.shps"), anyString());
        }

        @Test
        void uploadPublicFile_nullFilename_throws() {
                MockMultipartFile file = new MockMultipartFile("file", null, null, new byte[0]);

                assertThatThrownBy(() -> service.uploadPublicFile(file, null, null, userId))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void uploadPublicFile_invalidHash_throws() {
                MockMultipartFile file = multipart("plain.txt", "hello".getBytes(StandardCharsets.UTF_8));

                assertThatThrownBy(() -> service.uploadPublicFile(file, null, "BAD", userId))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void uploadPublicFile_success() throws Exception {
                MockMultipartFile file = multipart("plain.txt", "hello".getBytes(StandardCharsets.UTF_8));

                java.io.File tempShps = java.io.File.createTempFile("test-", ".shps");
                tempShps.deleteOnExit();
                when(shpsEncryptionService.encryptForServerToTempFile(
                                any(InputStream.class), anyLong(), eq("plain.txt"), eq(userId)))
                                .thenReturn(tempShps);
                when(s3Service.uploadFileWithMultipart(any(), anyString(), anyString()))
                                .thenReturn("s3-key");
                when(s3Service.getPublicUrl("s3-key")).thenReturn("https://cdn/s3-key");
                when(fileContentRepository.save(any(FileContent.class)))
                                .thenAnswer(inv -> inv.getArgument(0));
                when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

                FileDto dto = service.uploadPublicFile(file, null, null, userId);

                assertThat(dto.getIsPublic()).isTrue();
        }

        @Test
        void uploadPublicFile_dbFailure_rollsBackS3() throws Exception {
                MockMultipartFile file = multipart("plain.txt", "hello".getBytes(StandardCharsets.UTF_8));

                java.io.File tempShps = java.io.File.createTempFile("test-", ".shps");
                tempShps.deleteOnExit();
                when(shpsEncryptionService.encryptForServerToTempFile(
                                any(InputStream.class), anyLong(), anyString(), any(UUID.class)))
                                .thenReturn(tempShps);
                when(s3Service.uploadFileWithMultipart(any(), anyString(), anyString()))
                                .thenReturn("s3-key");
                when(s3Service.getPublicUrl("s3-key")).thenReturn("https://cdn/s3-key");
                when(fileContentRepository.save(any())).thenThrow(new RuntimeException("boom"));

                assertThatThrownBy(() -> service.uploadPublicFile(file, null, null, userId))
                                .isInstanceOf(RuntimeException.class);

                verify(s3Service).deleteFile("https://cdn/s3-key");
        }

        @Test
        void createFileLink_userNotFound_throws() {
                UUID otherUser = UUID.randomUUID();
                when(userRepository.findById(otherUser)).thenReturn(Optional.empty());

                FileContent content = content("k", false);

                assertThatThrownBy(() -> service.createFileLink(otherUser, content, "doc", null))
                                .isInstanceOf(IllegalArgumentException.class)
                                .hasMessageContaining("User not found");
        }

        @Test
        void createFileLink_folderNotFound_throws() {
                UUID folderId = UUID.randomUUID();
                when(folderRepository.findById(folderId)).thenReturn(Optional.empty());

                FileContent content = content("k", false);

                assertThatThrownBy(() -> service.createFileLink(userId, content, "doc", folderId))
                                .isInstanceOf(IllegalArgumentException.class)
                                .hasMessageContaining("Folder not found");
        }

        @Test
        void createFileLink_folderOwnedByAnother_throws() {
                UUID folderId = UUID.randomUUID();
                User other = User.builder().id(UUID.randomUUID()).build();
                Folder folder = Folder.builder().id(folderId).user(other).build();
                when(folderRepository.findById(folderId)).thenReturn(Optional.of(folder));

                FileContent content = content("k", false);

                assertThatThrownBy(() -> service.createFileLink(userId, content, "doc", folderId))
                                .isInstanceOf(SecurityException.class);
        }

        @Test
        void createFileLink_success_noFolder() {
                FileContent content = content("k", false);
                when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

                File result = service.createFileLink(userId, content, "doc", null);

                assertThat(result.getUser()).isSameAs(currentUser);
                assertThat(result.getFileContent()).isSameAs(content);
                assertThat(result.getFolder()).isNull();
        }

        @Test
        void createFileLink_success_withFolder() {
                UUID folderId = UUID.randomUUID();
                Folder folder = Folder.builder().id(folderId).user(currentUser).build();
                when(folderRepository.findById(folderId)).thenReturn(Optional.of(folder));
                when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

                FileContent content = content("k", false);

                File result = service.createFileLink(userId, content, "doc", folderId);

                assertThat(result.getFolder()).isSameAs(folder);
        }

        @Test
        void linkExistingFile_contentNotFound_throws() {
                UUID contentId = UUID.randomUUID();
                when(fileContentRepository.findById(contentId)).thenReturn(Optional.empty());

                assertThatThrownBy(() -> service.linkExistingFile(userId, contentId, "doc", null, false))
                                .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        void linkExistingFile_publicMismatch_throws() {
                UUID contentId = UUID.randomUUID();
                FileContent c = content("k", true);
                when(fileContentRepository.findById(contentId)).thenReturn(Optional.of(c));

                assertThatThrownBy(() -> service.linkExistingFile(userId, contentId, "doc", null, false))
                                .isInstanceOf(SecurityException.class);
        }

        @Test
        void linkExistingFile_notOwned_throws() {
                UUID contentId = UUID.randomUUID();
                FileContent c = content("k", false);
                when(fileContentRepository.findById(contentId)).thenReturn(Optional.of(c));
                when(fileRepository.existsByUserIdAndFileContentId(userId, contentId))
                                .thenReturn(false);

                assertThatThrownBy(() -> service.linkExistingFile(userId, contentId, "doc", null, false))
                                .isInstanceOf(ForbiddenException.class);
        }

        @Test
        void deleteFile_notFound_throws() {
                UUID fileId = UUID.randomUUID();
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.empty());

                assertThatThrownBy(() -> service.deleteFile(fileId, userId))
                                .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        void deleteFile_noActiveLinks_deletesS3() {
                UUID fileId = UUID.randomUUID();
                FileContent c = content("s3-key", false);
                File f = file(fileId, c);
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.of(f));
                when(fileRepository.countActiveLinksByFileContent(c)).thenReturn(0L);
                when(fileRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

                service.deleteFile(fileId, userId);

                assertThat(f.getIsDeleted()).isTrue();
                assertThat(f.getDeletedAt()).isNotNull();
                verify(s3Service).deleteFile(c.getS3Url());
        }

        @Test
        void deleteFile_hasActiveLinks_keepsS3() {
                UUID fileId = UUID.randomUUID();
                FileContent c = content("s3-key", false);
                File f = file(fileId, c);
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.of(f));
                when(fileRepository.countActiveLinksByFileContent(c)).thenReturn(2L);
                when(fileRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

                service.deleteFile(fileId, userId);

                verify(s3Service, never()).deleteFile(anyString());
        }

        @Test
        void deleteFile_s3Failure_doesNotPropagate() {
                UUID fileId = UUID.randomUUID();
                FileContent c = content("s3-key", false);
                File f = file(fileId, c);
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.of(f));
                when(fileRepository.countActiveLinksByFileContent(c)).thenReturn(0L);
                when(fileRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
                org.mockito.Mockito.doThrow(new RuntimeException("S3 error"))
                                .when(s3Service).deleteFile(c.getS3Url());

                service.deleteFile(fileId, userId);
        }

        private File file(UUID fileId, FileContent c) {
                File f = file(c, false);
                f.setId(fileId);
                return f;
        }

        @Test
        void updateFileFolder_fileNotFound_throws() {
                UUID fileId = UUID.randomUUID();
                when(fileRepository.findById(fileId)).thenReturn(Optional.empty());

                assertThatThrownBy(() -> service.updateFileFolder(fileId, null, userId))
                                .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        void updateFileFolder_notOwned_throws() {
                UUID fileId = UUID.randomUUID();
                User other = User.builder().id(UUID.randomUUID()).build();
                File f = File.builder().id(fileId).user(other).build();
                when(fileRepository.findById(fileId)).thenReturn(Optional.of(f));

                assertThatThrownBy(() -> service.updateFileFolder(fileId, null, userId))
                                .isInstanceOf(SecurityException.class);
        }

        @Test
        void updateFileFolder_detachToRoot() {
                UUID fileId = UUID.randomUUID();
                Folder oldFolder = Folder.builder().id(UUID.randomUUID()).user(currentUser).build();
                File f = File.builder().id(fileId).user(currentUser).folder(oldFolder).build();
                when(fileRepository.findById(fileId)).thenReturn(Optional.of(f));
                when(fileRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

                File result = service.updateFileFolder(fileId, null, userId);

                assertThat(result.getFolder()).isNull();
        }

        @Test
        void updateFileFolder_folderOwnedByAnother_throws() {
                UUID fileId = UUID.randomUUID();
                UUID folderId = UUID.randomUUID();
                File f = File.builder().id(fileId).user(currentUser).build();
                Folder other = Folder.builder().id(folderId).user(User.builder().id(UUID.randomUUID()).build()).build();
                when(fileRepository.findById(fileId)).thenReturn(Optional.of(f));
                when(folderRepository.findById(folderId)).thenReturn(Optional.of(other));

                assertThatThrownBy(() -> service.updateFileFolder(fileId, folderId, userId))
                                .isInstanceOf(SecurityException.class);
        }

        @Test
        void updateFileFolder_success() {
                UUID fileId = UUID.randomUUID();
                UUID folderId = UUID.randomUUID();
                Folder folder = Folder.builder().id(folderId).user(currentUser).build();
                File f = File.builder().id(fileId).user(currentUser).build();
                when(fileRepository.findById(fileId)).thenReturn(Optional.of(f));
                when(folderRepository.findById(folderId)).thenReturn(Optional.of(folder));
                when(fileRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

                File result = service.updateFileFolder(fileId, folderId, userId);

                assertThat(result.getFolder()).isSameAs(folder);
        }

        @Test
        void getFileById_notFound_throws() {
                UUID fileId = UUID.randomUUID();
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.empty());

                assertThatThrownBy(() -> service.getFileById(fileId, userId))
                                .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        void getAllFilesForUser_delegates() {
                Pageable pageable = PageRequest.of(0, 10);
                Page<File> expected = new PageImpl<>(List.of());
                when(fileRepository.findByUserIdAndIsDeletedFalse(userId, pageable)).thenReturn(expected);

                assertThat(service.getAllFilesForUser(userId, pageable)).isSameAs(expected);
        }

        @Test
        void getLatestFilesForUser_delegates() {
                Pageable pageable = PageRequest.of(0, 10);
                Page<File> expected = new PageImpl<>(List.of());
                when(fileRepository.findLatestByUserId(userId, pageable)).thenReturn(expected);

                assertThat(service.getLatestFilesForUser(userId, pageable)).isSameAs(expected);
        }

        @Test
        void getUsersNodes_delegates() {
                Page<File> expected = new PageImpl<>(List.of());
                when(fileRepository.findNotesByUserId(eq(userId), any(Pageable.class))).thenReturn(expected);

                assertThat(service.getUsersNodes(userId, 0, 10)).isSameAs(expected);
        }

        @Test
        void existsFileContentForUser_existingOwned_returnsTrue() {
                String hash = "a".repeat(64);
                FileContent c = content("k", false);
                when(fileContentRepository.findByHashAndIsPublic(hash, false)).thenReturn(Optional.of(c));
                when(fileRepository.existsByUserIdAndFileContentId(userId, c.getId())).thenReturn(true);

                assertThat(service.existsFileContentForUser(hash, false, userId)).isTrue();
        }

        @Test
        void existsFileContentForUser_noContent_returnsFalse() {
                when(fileContentRepository.findByHashAndIsPublic(anyString(), any()))
                                .thenReturn(Optional.empty());

                assertThat(service.existsFileContentForUser("hash", false, userId)).isFalse();
        }

        @Test
        void findExistingFileContentId_found() {
                FileContent c = content("k", false);
                when(fileContentRepository.findByHashAndIsPublic("h", false)).thenReturn(Optional.of(c));

                assertThat(service.findExistingFileContentId("h", false)).isEqualTo(c.getId());
        }

        @Test
        void findExistingFileContentId_missing_returnsNull() {
                when(fileContentRepository.findByHashAndIsPublic("h", false)).thenReturn(Optional.empty());

                assertThat(service.findExistingFileContentId("h", false)).isNull();
        }

        @Test
        void createNote_nullFilename_throws() {
                MockMultipartFile file = new MockMultipartFile("file", null, null, new byte[0]);

                assertThatThrownBy(() -> service.createNote(file, null, userId))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void createNote_wrongOwner_throws() throws Exception {
                MockMultipartFile file = multipart("note.shps", shpsContainer(50));
                when(shpsSecurityService.validateHeaderOnly(any(java.nio.file.Path.class), eq("note.shps")))
                                .thenReturn(header("server", userId.toString()));

                assertThatThrownBy(() -> service.createNote(file, null, userId))
                                .isInstanceOf(SecurityException.class)
                                .hasMessageContaining("note owner");
        }

        @Test
        void createNote_success() throws Exception {
                MockMultipartFile file = multipart("note.shps", shpsContainer(50));
                when(shpsSecurityService.validateHeaderOnly(any(java.nio.file.Path.class), eq("note.shps")))
                                .thenReturn(header("user", userId.toString()));
                when(s3Service.uploadFileWithMultipart(any(), anyString(), anyString()))
                                .thenReturn("note-key");
                when(s3Service.getPublicUrl("note-key")).thenReturn("https://cdn/note-key");
                when(fileContentRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
                when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

                File note = service.createNote(file, null, userId);

                assertThat(note.getIsNote()).isTrue();
                assertThat(note.getName()).isEqualTo("note");
        }

        @Test
        void updateNoteContent_noteNotFound_throws() {
                UUID fileId = UUID.randomUUID();
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.empty());

                MockMultipartFile file = multipart("note.shps", new byte[] { 1, 2, 3 });

                assertThatThrownBy(() -> service.updateNoteContent(fileId, file, userId))
                                .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        void updateNoteContent_notANote_throws() {
                UUID fileId = UUID.randomUUID();
                File f = File.builder().id(fileId).user(currentUser).isNote(false).build();
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.of(f));

                MockMultipartFile file = multipart("note.shps", new byte[] { 1, 2, 3 });

                assertThatThrownBy(() -> service.updateNoteContent(fileId, file, userId))
                                .isInstanceOf(IllegalArgumentException.class)
                                .hasMessageContaining("Not a note");
        }

        @Test
        void updateNoteContent_nullFilename_throws() {
                UUID fileId = UUID.randomUUID();
                File f = File.builder().id(fileId).user(currentUser).isNote(true)
                                .fileContent(content("old-key", false)).build();
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.of(f));

                MockMultipartFile file = new MockMultipartFile("file", null, null, new byte[0]);

                assertThatThrownBy(() -> service.updateNoteContent(fileId, file, userId))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void updateNoteContent_success_replacesContent() throws Exception {
                UUID fileId = UUID.randomUUID();
                FileContent oldContent = content("old-key", false);
                File f = File.builder().id(fileId).user(currentUser).isNote(true)
                                .fileContent(oldContent).build();
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.of(f));

                MockMultipartFile file = multipart("note.shps", shpsContainer(50));
                when(shpsSecurityService.validateHeaderOnly(any(java.nio.file.Path.class), eq("note.shps")))
                                .thenReturn(header("user", userId.toString()));
                when(s3Service.uploadFileWithMultipart(any(), anyString(), anyString()))
                                .thenReturn("new-key");
                when(s3Service.getPublicUrl("new-key")).thenReturn("https://cdn/new-key");
                when(fileContentRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
                when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

                service.updateNoteContent(fileId, file, userId);

                assertThat(oldContent.getS3Key()).isEqualTo("new-key");
                verify(s3Service).deleteFile("https://cdn/old-key");
        }

        @Test
        void getDecryptionMetadataForUser_privateFile_returnsMetadata() throws Exception {
                UUID fileId = UUID.randomUUID();
                FileContent c = content("s3-key", false);
                File f = File.builder().id(fileId).user(currentUser)
                                .fileContent(c).isPublic(false)
                                .originalName("doc.shps").mimeType("application/x-shirmps")
                                .build();
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.of(f));

                when(s3Service.getObjectStream("s3-key")).thenReturn(new ByteArrayInputStream(new byte[] { 1 }));
                ShirmpsHeader h = header("user", userId.toString());
                h.setOriginalFileSize(50L);
                when(shpsSecurityService.extractHeader(any())).thenReturn(h);
                when(s3Service.generatePresignedUrl(eq("s3-key"), any()))
                                .thenReturn("https://presigned");

                DecryptionMetadata md = service.getDecryptionMetadataForUser(fileId, userId);

                assertThat(md.getPresignedUrl()).isEqualTo("https://presigned");
                assertThat(md.getEncryptedKey()).isEqualTo(h.getEncryptedKey());
                assertThat(md.getIv()).isEqualTo(h.getIv());
                assertThat(md.getFileName()).isEqualTo("doc.shps");
        }

        @Test
        void getDecryptionMetadataForUser_privateFile_wrongOwner_throws() throws Exception {
                UUID fileId = UUID.randomUUID();
                FileContent c = content("s3-key", false);
                File f = File.builder().id(fileId).user(currentUser)
                                .fileContent(c).isPublic(false)
                                .build();
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.of(f));

                when(s3Service.getObjectStream("s3-key")).thenReturn(new ByteArrayInputStream(new byte[] { 1 }));
                when(shpsSecurityService.extractHeader(any()))
                                .thenReturn(header("user", UUID.randomUUID().toString()));

                assertThatThrownBy(() -> service.getDecryptionMetadataForUser(fileId, userId))
                                .isInstanceOf(RuntimeException.class);
        }

        @Test
        void getDecryptionMetadataForUser_publicFile_success() throws Exception {
                UUID fileId = UUID.randomUUID();
                FileContent c = content("s3-key", true);
                File f = File.builder().id(fileId).user(currentUser)
                                .fileContent(c).isPublic(true)
                                .originalName("doc.shps").mimeType("application/x-shirmps")
                                .build();
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.of(f));

                KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
                kpg.initialize(2048);
                KeyPair serverKp = kpg.generateKeyPair();
                KeyPair userKp = kpg.generateKeyPair();

                KeyGenerator aesGen = KeyGenerator.getInstance("AES");
                aesGen.init(256);
                SecretKey aesKey = aesGen.generateKey();

                Cipher rsaEnc = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
                OAEPParameterSpec oaep = new OAEPParameterSpec(
                                "SHA-256", "MGF1", MGF1ParameterSpec.SHA256, PSource.PSpecified.DEFAULT);
                rsaEnc.init(Cipher.ENCRYPT_MODE, serverKp.getPublic(), oaep);
                byte[] encryptedAesKey = rsaEnc.doFinal(aesKey.getEncoded());

                ShirmpsHeader h = header("server", userId.toString());
                h.setEncryptedKey(Base64.getEncoder().encodeToString(encryptedAesKey));
                h.setOriginalFileSize(50L);

                when(s3Service.getObjectStream("s3-key")).thenReturn(new ByteArrayInputStream(new byte[] { 1 }));
                when(shpsSecurityService.extractHeader(any())).thenReturn(h);
                when(serverKeyService.getPrivateKey()).thenReturn((PrivateKey) serverKp.getPrivate());
                when(userKeyService.getPublicKey(userId)).thenReturn((PublicKey) userKp.getPublic());
                when(s3Service.generatePresignedUrl(eq("s3-key"), any()))
                                .thenReturn("https://presigned");

                DecryptionMetadata md = service.getDecryptionMetadataForUser(fileId, userId);

                assertThat(md.getPresignedUrl()).isEqualTo("https://presigned");
                assertThat(md.getEncryptedKey()).isNotBlank();
                assertThat(md.getOriginalSize()).isEqualTo(50L);
        }

        @Test
        void getDecryptionMetadataForUser_publicFile_notServerOwned_throws() throws Exception {
                UUID fileId = UUID.randomUUID();
                FileContent c = content("s3-key", true);
                File f = File.builder().id(fileId).user(currentUser)
                                .fileContent(c).isPublic(true).build();
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.of(f));

                when(s3Service.getObjectStream("s3-key")).thenReturn(new ByteArrayInputStream(new byte[] { 1 }));
                when(shpsSecurityService.extractHeader(any()))
                                .thenReturn(header("user", userId.toString()));

                assertThatThrownBy(() -> service.getDecryptionMetadataForUser(fileId, userId))
                                .isInstanceOf(BadRequestException.class)
                                .hasMessageContaining("marked public but its key is not encrypted for server");
        }

        @Test
        void getDecryptionMetadataForTempAccess_privateFile_throws() {
                FileContent c = content("s3-key", false);
                File f = File.builder().id(UUID.randomUUID()).user(currentUser)
                                .fileContent(c).isPublic(false).build();
                TempFileAccess ta = TempFileAccess.builder().file(f).build();

                assertThatThrownBy(() -> service.getDecryptionMetadataForTempAccess(ta, userId))
                                .isInstanceOf(SecurityException.class)
                                .hasMessageContaining("public");
        }

        @Test
        void uploadShpsFile_public_dedupNotOwned_throws() throws Exception {
                String hash = "a".repeat(64);
                FileContent existing = content("existing", true);

                when(fileContentRepository.findByHashAndIsPublic(hash, true))
                                .thenReturn(Optional.of(existing));
                when(fileRepository.existsByUserIdAndFileContentId(userId, existing.getId()))
                                .thenReturn(false);

                MockMultipartFile file = multipart("doc.shps", shpsContainer(100));

                assertThatThrownBy(() -> service.uploadShpsFile(file, null, true, hash, userId))
                                .isInstanceOf(BadRequestException.class)
                                .hasMessageContaining("not yours");
        }

        @Test
        void uploadPublicFile_dedupOwned_createsLink() throws Exception {
                String hash = "b".repeat(64);
                FileContent existing = content("existing", true);

                when(fileContentRepository.findByHashAndIsPublic(hash, true))
                                .thenReturn(Optional.of(existing));
                when(fileRepository.existsByUserIdAndFileContentId(userId, existing.getId()))
                                .thenReturn(true);
                when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

                MockMultipartFile file = multipart("doc.txt", "x".getBytes(StandardCharsets.UTF_8));
                FileDto dto = service.uploadPublicFile(file, null, hash, userId);

                assertThat(dto).isNotNull();
                verify(s3Service, never()).uploadFileWithMultipart(any(), anyString(), anyString());
        }

        @Test
        void uploadPublicFile_dedupNotOwned_throws() throws Exception {
                String hash = "c".repeat(64);
                FileContent existing = content("existing", true);

                when(fileContentRepository.findByHashAndIsPublic(hash, true))
                                .thenReturn(Optional.of(existing));
                when(fileRepository.existsByUserIdAndFileContentId(userId, existing.getId()))
                                .thenReturn(false);

                MockMultipartFile file = multipart("doc.txt", "x".getBytes(StandardCharsets.UTF_8));

                assertThatThrownBy(() -> service.uploadPublicFile(file, null, hash, userId))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void uploadPublicFile_withFolder_passesFolderId() throws Exception {
                UUID folderId = UUID.randomUUID();
                Folder folder = Folder.builder().id(folderId).user(currentUser).build();
                MockMultipartFile file = multipart("plain.txt", "hello".getBytes(StandardCharsets.UTF_8));

                java.io.File tempShps = java.io.File.createTempFile("test-", ".shps");
                tempShps.deleteOnExit();
                when(shpsEncryptionService.encryptForServerToTempFile(
                                any(InputStream.class), anyLong(), eq("plain.txt"), eq(userId)))
                                .thenReturn(tempShps);
                when(s3Service.uploadFileWithMultipart(any(), anyString(), anyString())).thenReturn("s3-key");
                when(s3Service.getPublicUrl("s3-key")).thenReturn("https://cdn/s3-key");
                when(fileContentRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
                when(folderRepository.findById(folderId)).thenReturn(Optional.of(folder));
                when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

                FileDto dto = service.uploadPublicFile(file, folderId, null, userId);

                assertThat(dto.getFolderId()).isEqualTo(folderId);
        }

        @Test
        void createMetadataForPublicFile_badPadding_throwsBadRequest() throws Exception {
                UUID fileId = UUID.randomUUID();
                FileContent c = content("s3-key", true);
                File f = File.builder().id(fileId).user(currentUser)
                                .fileContent(c).isPublic(true)
                                .originalName("doc.shps").mimeType("application/x-shirmps").build();
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.of(f));

                KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
                kpg.initialize(2048);
                KeyPair serverKp = kpg.generateKeyPair();
                KeyPair otherKp = kpg.generateKeyPair();

                KeyGenerator aesGen = KeyGenerator.getInstance("AES");
                aesGen.init(256);
                SecretKey aesKey = aesGen.generateKey();

                Cipher rsaEnc = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
                OAEPParameterSpec oaep = new OAEPParameterSpec(
                                "SHA-256", "MGF1", MGF1ParameterSpec.SHA256, PSource.PSpecified.DEFAULT);
                rsaEnc.init(Cipher.ENCRYPT_MODE, otherKp.getPublic(), oaep);
                byte[] encryptedAesKey = rsaEnc.doFinal(aesKey.getEncoded());

                ShirmpsHeader h = header("server", userId.toString());
                h.setEncryptedKey(Base64.getEncoder().encodeToString(encryptedAesKey));
                h.setOriginalFileSize(50L);

                when(s3Service.getObjectStream("s3-key")).thenReturn(new ByteArrayInputStream(new byte[] { 1 }));
                when(shpsSecurityService.extractHeader(any())).thenReturn(h);
                when(serverKeyService.getPrivateKey()).thenReturn((PrivateKey) serverKp.getPrivate());

                assertThatThrownBy(() -> service.getDecryptionMetadataForUser(fileId, userId))
                                .isInstanceOf(BadRequestException.class)
                                .hasMessageContaining("Cannot decrypt file key");
        }

        @Test
        void createNote_s3FailureRollsBack() throws Exception {
                MockMultipartFile file = multipart("note.shps", shpsContainer(50));
                when(shpsSecurityService.validateHeaderOnly(any(java.nio.file.Path.class), eq("note.shps")))
                                .thenReturn(header("user", userId.toString()));
                when(s3Service.uploadFileWithMultipart(any(), anyString(), anyString()))
                                .thenReturn("note-key");
                when(s3Service.getPublicUrl("note-key")).thenReturn("https://cdn/note-key");
                when(fileContentRepository.save(any())).thenThrow(new RuntimeException("db down"));

                assertThatThrownBy(() -> service.createNote(file, null, userId))
                                .isInstanceOf(RuntimeException.class);

                verify(s3Service).deleteFile("https://cdn/note-key");
        }

        @Test
        void updateNoteContent_wrongOwner_throws() throws Exception {
                UUID fileId = UUID.randomUUID();
                FileContent oldContent = content("old-key", false);
                File f = File.builder().id(fileId).user(currentUser).isNote(true)
                                .fileContent(oldContent).build();
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.of(f));

                MockMultipartFile file = multipart("note.shps", shpsContainer(50));
                when(shpsSecurityService.validateHeaderOnly(any(java.nio.file.Path.class), eq("note.shps")))
                                .thenReturn(header("server", userId.toString()));

                assertThatThrownBy(() -> service.updateNoteContent(fileId, file, userId))
                                .isInstanceOf(SecurityException.class);
        }

        @Test
        void updateNoteContent_s3FailureRollsBackNew() throws Exception {
                UUID fileId = UUID.randomUUID();
                FileContent oldContent = content("old-key", false);
                File f = File.builder().id(fileId).user(currentUser).isNote(true)
                                .fileContent(oldContent).build();
                when(fileRepository.findByIdAndUserId(fileId, userId)).thenReturn(Optional.of(f));

                MockMultipartFile file = multipart("note.shps", shpsContainer(50));
                when(shpsSecurityService.validateHeaderOnly(any(java.nio.file.Path.class), eq("note.shps")))
                                .thenReturn(header("user", userId.toString()));
                when(s3Service.uploadFileWithMultipart(any(), anyString(), anyString()))
                                .thenReturn("new-key");
                when(s3Service.getPublicUrl("new-key")).thenReturn("https://cdn/new-key");
                when(fileContentRepository.save(any())).thenThrow(new RuntimeException("db down"));

                assertThatThrownBy(() -> service.updateNoteContent(fileId, file, userId))
                                .isInstanceOf(RuntimeException.class);

                verify(s3Service).deleteFile("https://cdn/new-key");
        }

        @Test
        void mapToDto_withFolder_includesFolderFields() throws Exception {
                MockMultipartFile file = multipart("doc.shps", shpsContainer(100));
                UUID folderId = UUID.randomUUID();
                Folder folder = Folder.builder().id(folderId).user(currentUser).name("MyFolder").build();

                when(shpsSecurityService.validateHeaderOnly(any(java.nio.file.Path.class), eq("doc.shps")))
                                .thenReturn(header("user", userId.toString()));
                when(s3Service.uploadFileWithMultipart(any(), anyString(), anyString())).thenReturn("s3-key");
                when(s3Service.getPublicUrl("s3-key")).thenReturn("https://cdn/s3-key");
                when(fileContentRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
                when(folderRepository.findById(folderId)).thenReturn(Optional.of(folder));
                when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

                FileDto dto = service.uploadShpsFile(file, folderId, false, null, userId);

                assertThat(dto.getFolderId()).isEqualTo(folderId);
                assertThat(dto.getFolderName()).isEqualTo("MyFolder");
        }

        @Test
        void linkExistingFile_withFolder_createsLinkInFolder() throws Exception {
                UUID contentId = UUID.randomUUID();
                UUID folderId = UUID.randomUUID();
                Folder folder = Folder.builder().id(folderId).user(currentUser).build();
                FileContent c = content("k", false);

                when(fileContentRepository.findById(contentId)).thenReturn(Optional.of(c));
                when(fileRepository.existsByUserIdAndFileContentId(userId, contentId)).thenReturn(true);
                when(folderRepository.findById(folderId)).thenReturn(Optional.of(folder));
                when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

                File result = service.linkExistingFile(userId, contentId, "doc", folderId, false);

                assertThat(result.getFolder()).isSameAs(folder);
        }

        @Test
        void getDecryptionMetadataForTempAccess_publicFile_delegatesToPublic() throws Exception {
                KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
                kpg.initialize(2048);
                KeyPair serverKp = kpg.generateKeyPair();
                KeyPair userKp = kpg.generateKeyPair();

                KeyGenerator aesGen = KeyGenerator.getInstance("AES");
                aesGen.init(256);
                SecretKey aesKey = aesGen.generateKey();

                Cipher rsaEnc = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
                OAEPParameterSpec oaep = new OAEPParameterSpec(
                                "SHA-256", "MGF1", MGF1ParameterSpec.SHA256, PSource.PSpecified.DEFAULT);
                rsaEnc.init(Cipher.ENCRYPT_MODE, serverKp.getPublic(), oaep);
                byte[] encryptedAesKey = rsaEnc.doFinal(aesKey.getEncoded());

                ShirmpsHeader h = header("server", userId.toString());
                h.setEncryptedKey(Base64.getEncoder().encodeToString(encryptedAesKey));
                h.setOriginalFileSize(50L);

                FileContent c = content("s3-key", true);
                File f = File.builder().id(UUID.randomUUID()).user(currentUser)
                                .fileContent(c).isPublic(true)
                                .originalName("doc.shps").mimeType("application/x-shirmps").build();
                TempFileAccess ta = TempFileAccess.builder().file(f).build();

                when(s3Service.getObjectStream("s3-key")).thenReturn(new ByteArrayInputStream(new byte[] { 1 }));
                when(shpsSecurityService.extractHeader(any())).thenReturn(h);
                when(serverKeyService.getPrivateKey()).thenReturn((PrivateKey) serverKp.getPrivate());
                when(userKeyService.getPublicKey(userId)).thenReturn((PublicKey) userKp.getPublic());
                when(s3Service.generatePresignedUrl(eq("s3-key"), any())).thenReturn("https://presigned");

                DecryptionMetadata md = service.getDecryptionMetadataForTempAccess(ta, userId);

                assertThat(md.getPresignedUrl()).isEqualTo("https://presigned");
        }

        @Test
        void updateFileFolder_noFolder_passesNull() {
                UUID fileId = UUID.randomUUID();
                File f = File.builder().id(fileId).user(currentUser).build();
                when(fileRepository.findById(fileId)).thenReturn(Optional.of(f));
                when(fileRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

                File result = service.updateFileFolder(fileId, null, userId);

                assertThat(result.getFolder()).isNull();
        }
}
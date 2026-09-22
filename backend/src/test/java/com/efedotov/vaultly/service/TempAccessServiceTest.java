package com.efedotov.vaultly.service;

import com.efedotov.vaultly.dto.tempaccess.CreateTempLinkRequest;
import com.efedotov.vaultly.dto.tempaccess.TempLinkInfo;
import com.efedotov.vaultly.dto.tempaccess.TempLinkResponse;
import com.efedotov.vaultly.exception.BadRequestException;
import com.efedotov.vaultly.exception.ForbiddenException;
import com.efedotov.vaultly.exception.NotFoundException;
import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.model.FileContent;
import com.efedotov.vaultly.model.TempFileAccess;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.FileContentRepository;
import com.efedotov.vaultly.repository.FileRepository;
import com.efedotov.vaultly.repository.TempFileAccessRepository;
import com.efedotov.vaultly.repository.UserRepository;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.shirmps.ShirmpsHeader;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.time.LocalDateTime;
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
class TempAccessServiceTest {

        @Mock
        TempFileAccessRepository tempRepo;
        @Mock
        FileRepository fileRepo;
        @Mock
        FileContentRepository fileContentRepo;
        @Mock
        S3Service s3Service;
        @Mock
        UserRepository userRepo;
        @Mock
        ShpsSecurityService shpsSecurityService;
        @Mock
        PasswordEncoder passwordEncoder;
        @Mock
        LoginAttemptService loginAttemptService;

        @InjectMocks
        TempAccessService service;

        private UUID userId;
        private User currentUser;

        @BeforeEach
        void setUp() {
                ReflectionTestUtils.setField(service, "baseUrl", "https://vaultly.example");

                userId = UUID.randomUUID();
                currentUser = User.builder().id(userId).username("alice").build();

                CustomUserDetails principal = new CustomUserDetails(currentUser);
                UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(principal, null,
                                List.of());
                SecurityContextHolder.getContext().setAuthentication(auth);
        }

        @AfterEach
        void tearDown() {
                SecurityContextHolder.clearContext();
        }

        @Test
        void getTempLinkInfo_notFound_throws() {
                when(tempRepo.findByToken("t")).thenReturn(Optional.empty());
                assertThatThrownBy(() -> service.getTempLinkInfo("t"))
                                .isInstanceOf(NotFoundException.class);
        }

        @Test
        void getTempLinkInfo_inactive_throws() {
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(false)
                                .expiresAt(LocalDateTime.now().plusHours(1))
                                .file(File.builder().build())
                                .build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));
                assertThatThrownBy(() -> service.getTempLinkInfo("t"))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void getTempLinkInfo_expired_throws() {
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(true)
                                .expiresAt(LocalDateTime.now().minusMinutes(1))
                                .file(File.builder().build())
                                .build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));
                assertThatThrownBy(() -> service.getTempLinkInfo("t"))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void getTempLinkInfo_valid_returnsInfo() {
                File f = File.builder().originalName("doc.pdf").mimeType("application/pdf").build();
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(true)
                                .expiresAt(LocalDateTime.now().plusHours(1))
                                .file(f).passwordHash(null)
                                .build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));

                TempLinkInfo info = service.getTempLinkInfo("t");
                assertThat(info.getFileName()).isEqualTo("doc.pdf");
                assertThat(info.getMimeType()).isEqualTo("application/pdf");
                assertThat(info.isHasPassword()).isFalse();
        }

        @Test
        void getTempLinkInfo_withPassword_hasPasswordTrue() {
                File f = File.builder().originalName("doc.pdf").mimeType("application/pdf").build();
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(true)
                                .expiresAt(LocalDateTime.now().plusHours(1))
                                .file(f).passwordHash("$2a$hash")
                                .build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));

                assertThat(service.getTempLinkInfo("t").isHasPassword()).isTrue();
        }

        @Test
        void validateTempLink_expired_throws() {
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(true)
                                .expiresAt(LocalDateTime.now().minusMinutes(1))
                                .build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));
                assertThatThrownBy(() -> service.validateTempLink("t", null))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void validateTempLink_wrongPassword_throws() {
                File f = File.builder().isPublic(true).isDeleted(false).build();
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(true)
                                .expiresAt(LocalDateTime.now().plusHours(1))
                                .file(f).passwordHash("$hash")
                                .build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));
                when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(false);
                when(passwordEncoder.matches("wrong", "$hash")).thenReturn(false);
                assertThatThrownBy(() -> service.validateTempLink("t", "wrong"))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void validateTempLink_passwordNull_throws() {
                File f = File.builder().isPublic(true).isDeleted(false).build();
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(true)
                                .expiresAt(LocalDateTime.now().plusHours(1))
                                .file(f).passwordHash("$hash")
                                .build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));
                when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(false);
                assertThatThrownBy(() -> service.validateTempLink("t", null))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void validateTempLink_passwordBlocked_throwsSecurity() {
                File f = File.builder().isPublic(true).isDeleted(false).build();
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(true)
                                .expiresAt(LocalDateTime.now().plusHours(1))
                                .file(f).passwordHash("$hash")
                                .build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));
                when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(true);

                assertThatThrownBy(() -> service.validateTempLink("t", "pwd"))
                                .isInstanceOf(SecurityException.class);
        }

        @Test
        void validateTempLink_correctPassword_succeeds() {
                File f = File.builder().isPublic(true).isDeleted(false).build();
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(true)
                                .expiresAt(LocalDateTime.now().plusHours(1))
                                .file(f).passwordHash("$hash")
                                .build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));
                when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(false);
                when(passwordEncoder.matches("pwd", "$hash")).thenReturn(true);

                assertThat(service.validateTempLink("t", "pwd")).isSameAs(ta);
                verify(loginAttemptService).folderPasswordSucceeded(anyString());
        }

        @Test
        void validateTempLink_maxDownloadsReached_throws() {
                File f = File.builder().isPublic(true).isDeleted(false).build();
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(true)
                                .expiresAt(LocalDateTime.now().plusHours(1))
                                .maxDownloads(5).downloadsCount(5)
                                .file(f)
                                .build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));
                assertThatThrownBy(() -> service.validateTempLink("t", null))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void validateTempLink_fileNotPublic_throws() {
                File f = File.builder().isPublic(false).isDeleted(false).build();
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(true)
                                .expiresAt(LocalDateTime.now().plusHours(1))
                                .file(f)
                                .build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));
                assertThatThrownBy(() -> service.validateTempLink("t", null))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void validateTempLink_fileDeleted_throws() {
                File f = File.builder().isPublic(true).isDeleted(true).build();
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(true)
                                .expiresAt(LocalDateTime.now().plusHours(1))
                                .file(f)
                                .build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));
                assertThatThrownBy(() -> service.validateTempLink("t", null))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void validateTempLink_valid_returnsEntity() {
                File f = File.builder().isPublic(true).isDeleted(false).build();
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(true)
                                .expiresAt(LocalDateTime.now().plusHours(1))
                                .file(f)
                                .build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));
                assertThat(service.validateTempLink("t", null)).isSameAs(ta);
        }

        @Test
        void createTempLink_happyPath_noPassword() {
                UUID fileId = UUID.randomUUID();
                File file = File.builder()
                                .id(fileId).user(currentUser).isPublic(true).isDeleted(false)
                                .build();
                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.of(file));
                when(tempRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

                CreateTempLinkRequest req = new CreateTempLinkRequest();
                req.setFileId(fileId);
                req.setExpiresAt(LocalDateTime.now().plusHours(2));
                req.setMaxDownloads(10);

                TempLinkResponse resp = service.createTempLink(req);

                assertThat(resp.getToken()).isNotBlank();
                assertThat(resp.getAccessUrl()).contains("https://vaultly.example").contains(resp.getToken());
                assertThat(resp.getMaxDownloads()).isEqualTo(10);
                assertThat(resp.getDownloadsCount()).isZero();
        }

        @Test
        void createTempLink_withPassword_hashes() {
                UUID fileId = UUID.randomUUID();
                File file = File.builder()
                                .id(fileId).user(currentUser).isPublic(true).isDeleted(false)
                                .build();
                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.of(file));
                when(passwordEncoder.encode("pwd")).thenReturn("$2a$hash");
                when(tempRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

                CreateTempLinkRequest req = new CreateTempLinkRequest();
                req.setFileId(fileId);
                req.setExpiresAt(LocalDateTime.now().plusHours(2));
                req.setPassword("pwd");

                service.createTempLink(req);

                verify(passwordEncoder).encode("pwd");
        }

        @Test
        void createTempLink_userMissing_throws() {
                when(userRepo.findById(userId)).thenReturn(Optional.empty());

                CreateTempLinkRequest req = new CreateTempLinkRequest();
                req.setFileId(UUID.randomUUID());
                req.setExpiresAt(LocalDateTime.now().plusHours(2));

                assertThatThrownBy(() -> service.createTempLink(req))
                                .isInstanceOf(NotFoundException.class);
        }

        @Test
        void createTempLink_fileMissing_throws() {
                UUID fileId = UUID.randomUUID();
                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.empty());

                CreateTempLinkRequest req = new CreateTempLinkRequest();
                req.setFileId(fileId);
                req.setExpiresAt(LocalDateTime.now().plusHours(2));

                assertThatThrownBy(() -> service.createTempLink(req))
                                .isInstanceOf(NotFoundException.class);
        }

        @Test
        void createTempLink_fileOwnedByAnother_throws() {
                UUID fileId = UUID.randomUUID();
                User another = User.builder().id(UUID.randomUUID()).username("bob").build();
                File file = File.builder().id(fileId).user(another).isPublic(true).build();
                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.of(file));

                CreateTempLinkRequest req = new CreateTempLinkRequest();
                req.setFileId(fileId);
                req.setExpiresAt(LocalDateTime.now().plusHours(2));

                assertThatThrownBy(() -> service.createTempLink(req))
                                .isInstanceOf(ForbiddenException.class);
        }

        @Test
        void createTempLink_notPublic_throws() {
                UUID fileId = UUID.randomUUID();
                File file = File.builder().id(fileId).user(currentUser).isPublic(false).build();
                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.of(file));

                CreateTempLinkRequest req = new CreateTempLinkRequest();
                req.setFileId(fileId);
                req.setExpiresAt(LocalDateTime.now().plusHours(2));

                assertThatThrownBy(() -> service.createTempLink(req))
                                .isInstanceOf(BadRequestException.class)
                                .hasMessageContaining("not public");
        }

        @Test
        void createTempLink_deleted_throws() {
                UUID fileId = UUID.randomUUID();
                File file = File.builder().id(fileId).user(currentUser)
                                .isPublic(true).isDeleted(true).build();
                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.of(file));

                CreateTempLinkRequest req = new CreateTempLinkRequest();
                req.setFileId(fileId);
                req.setExpiresAt(LocalDateTime.now().plusHours(2));

                assertThatThrownBy(() -> service.createTempLink(req))
                                .isInstanceOf(BadRequestException.class)
                                .hasMessageContaining("deleted");
        }

        @Test
        void createTempLink_pastExpiration_throws() {
                UUID fileId = UUID.randomUUID();
                File file = File.builder().id(fileId).user(currentUser).isPublic(true).build();
                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.of(file));

                CreateTempLinkRequest req = new CreateTempLinkRequest();
                req.setFileId(fileId);
                req.setExpiresAt(LocalDateTime.now().minusHours(1));

                assertThatThrownBy(() -> service.createTempLink(req))
                                .isInstanceOf(BadRequestException.class)
                                .hasMessageContaining("future");
        }

        @Test
        void setFilePublic_fileMissing_throws() {
                UUID fileId = UUID.randomUUID();
                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.empty());

                assertThatThrownBy(() -> service.setFilePublic(fileId, true))
                                .isInstanceOf(NotFoundException.class);
        }

        @Test
        void setFilePublic_notOwned_throws() {
                UUID fileId = UUID.randomUUID();
                User another = User.builder().id(UUID.randomUUID()).build();
                File file = File.builder().id(fileId).user(another).build();
                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.of(file));

                assertThatThrownBy(() -> service.setFilePublic(fileId, true))
                                .isInstanceOf(ForbiddenException.class);
        }

        @Test
        void setFilePublic_noContent_throws() {
                UUID fileId = UUID.randomUUID();
                File file = File.builder().id(fileId).user(currentUser).fileContent(null).build();
                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.of(file));

                assertThatThrownBy(() -> service.setFilePublic(fileId, true))
                                .isInstanceOf(BadRequestException.class)
                                .hasMessageContaining("content");
        }

        @Test
        void setFilePublic_makingPrivate_saves() {
                UUID fileId = UUID.randomUUID();
                FileContent content = FileContent.builder().s3Key("k").isPublic(true).build();
                File file = File.builder().id(fileId).user(currentUser)
                                .isPublic(true).fileContent(content).build();
                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.of(file));
                when(fileRepo.countActiveLinksByFileContent(content)).thenReturn(1L);
                when(fileContentRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));
                when(fileRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

                service.setFilePublic(fileId, false);

                assertThat(content.getIsPublic()).isFalse();
                assertThat(file.getIsPublic()).isFalse();
        }

        @Test
        void setFilePublic_makingPublicWithServerKey_succeeds() throws Exception {
                UUID fileId = UUID.randomUUID();
                FileContent content = FileContent.builder().s3Key("k").isPublic(false).build();
                File file = File.builder().id(fileId).user(currentUser)
                                .isPublic(false).fileContent(content).build();

                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.of(file));

                InputStream stream = new ByteArrayInputStream(new byte[] { 1 });
                when(s3Service.getObjectStream("k")).thenReturn(stream);

                ShirmpsHeader header = new ShirmpsHeader();
                header.setKeyOwner("server");
                when(shpsSecurityService.extractHeader(any())).thenReturn(header);

                when(fileRepo.countActiveLinksByFileContent(content)).thenReturn(1L);
                when(fileContentRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));
                when(fileRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

                service.setFilePublic(fileId, true);

                assertThat(content.getIsPublic()).isTrue();
                assertThat(file.getIsPublic()).isTrue();
        }

        @Test
        void setFilePublic_makingPublicUserEncrypted_throws() throws Exception {
                UUID fileId = UUID.randomUUID();
                FileContent content = FileContent.builder().s3Key("k").isPublic(false).build();
                File file = File.builder().id(fileId).user(currentUser)
                                .isPublic(false).fileContent(content).build();

                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.of(file));
                when(s3Service.getObjectStream("k")).thenReturn(new ByteArrayInputStream(new byte[] { 1 }));

                ShirmpsHeader header = new ShirmpsHeader();
                header.setKeyOwner("user");
                when(shpsSecurityService.extractHeader(any())).thenReturn(header);

                assertThatThrownBy(() -> service.setFilePublic(fileId, true))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void setFilePublic_sharedContent_throws() throws Exception {
                UUID fileId = UUID.randomUUID();
                FileContent content = FileContent.builder().s3Key("k").isPublic(false).build();
                File file = File.builder().id(fileId).user(currentUser)
                                .isPublic(false).fileContent(content).build();

                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.of(file));

                when(s3Service.getObjectStream("k")).thenReturn(new ByteArrayInputStream(new byte[] { 1 }));
                ShirmpsHeader serverHeader = new ShirmpsHeader();
                serverHeader.setKeyOwner("server");
                when(shpsSecurityService.extractHeader(any())).thenReturn(serverHeader);

                when(fileRepo.countActiveLinksByFileContent(content)).thenReturn(3L);

                assertThatThrownBy(() -> service.setFilePublic(fileId, true))
                                .isInstanceOf(BadRequestException.class)
                                .hasMessageContaining("shared");
        }

        @Test
        void setFilePublic_sameValue_savesFileOnly() throws Exception {
                UUID fileId = UUID.randomUUID();
                FileContent content = FileContent.builder().s3Key("k").isPublic(true).build();
                File file = File.builder().id(fileId).user(currentUser)
                                .isPublic(true).fileContent(content).build();

                when(userRepo.findById(userId)).thenReturn(Optional.of(currentUser));
                when(fileRepo.findById(fileId)).thenReturn(Optional.of(file));

                when(s3Service.getObjectStream("k")).thenReturn(new ByteArrayInputStream(new byte[] { 1 }));
                ShirmpsHeader serverHeader = new ShirmpsHeader();
                serverHeader.setKeyOwner("server");
                when(shpsSecurityService.extractHeader(any())).thenReturn(serverHeader);

                when(fileRepo.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

                service.setFilePublic(fileId, true);

                verify(fileContentRepo, never()).save(any());
        }

        @Test
        void reserveDownloadSlot_repoReturns0_returnsFalse() {
                when(tempRepo.incrementDownloadsAndCheck(eq("t"), any())).thenReturn(0);
                assertThat(service.reserveDownloadSlot("t")).isFalse();
        }

        @Test
        void reserveDownloadSlot_success_notMaxed_returnsTrue() {
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").maxDownloads(10).downloadsCount(5).isActive(true).build();
                when(tempRepo.incrementDownloadsAndCheck(eq("t"), any())).thenReturn(1);
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));

                assertThat(service.reserveDownloadSlot("t")).isTrue();
                assertThat(ta.getIsActive()).isTrue();
        }

        @Test
        void reserveDownloadSlot_reachedMax_deactivates() {
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").maxDownloads(5).downloadsCount(5).isActive(true).build();
                when(tempRepo.incrementDownloadsAndCheck(eq("t"), any())).thenReturn(1);
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));
                when(tempRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

                service.reserveDownloadSlot("t");

                assertThat(ta.getIsActive()).isFalse();
        }

        @Test
        void incrementDownloadCount_limitReached_throws() {
                when(tempRepo.incrementDownloadsAndCheck(eq("t"), any())).thenReturn(0);
                assertThatThrownBy(() -> service.incrementDownloadCount("t"))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void incrementDownloadCount_success_returns() {
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").maxDownloads(10).downloadsCount(5).isActive(true).build();
                when(tempRepo.incrementDownloadsAndCheck(eq("t"), any())).thenReturn(1);
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));

                service.incrementDownloadCount("t");

                verify(tempRepo).incrementDownloadsAndCheck(eq("t"), any());
        }

        @Test
        void streamDecryptedFile_limitReached_throws() throws Exception {
                File f = File.builder().isPublic(true).isDeleted(false).build();
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(true)
                                .expiresAt(LocalDateTime.now().plusHours(1))
                                .file(f).build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));
                when(tempRepo.incrementDownloadsAndCheck(eq("t"), any())).thenReturn(0);

                assertThatThrownBy(() -> service.streamDecryptedFile("t", null, new ByteArrayOutputStream()))
                                .isInstanceOf(BadRequestException.class);
        }

        @Test
        void streamDecryptedFile_happyPath_writesToOutput() throws Exception {
                FileContent content = FileContent.builder().s3Key("k").build();
                File f = File.builder().isPublic(true).isDeleted(false).fileContent(content).build();
                TempFileAccess ta = TempFileAccess.builder()
                                .token("t").isActive(true)
                                .expiresAt(LocalDateTime.now().plusHours(1))
                                .file(f).maxDownloads(10).downloadsCount(0).build();
                when(tempRepo.findByToken("t")).thenReturn(Optional.of(ta));
                when(tempRepo.incrementDownloadsAndCheck(eq("t"), any())).thenReturn(1);
                when(s3Service.getObjectStream("k")).thenReturn(new ByteArrayInputStream(new byte[] { 1 }));

                ByteArrayOutputStream out = new ByteArrayOutputStream();
                service.streamDecryptedFile("t", null, out);

                verify(shpsSecurityService).decryptServerEncryptedToStream(any(), eq(out));
        }

        @Test
        void validateBaseUrl_blank_throws() {
                ReflectionTestUtils.setField(service, "baseUrl", "");
                assertThatThrownBy(() -> service.validateBaseUrl())
                                .isInstanceOf(IllegalStateException.class);
        }

        @Test
        void validateBaseUrl_null_throws() {
                ReflectionTestUtils.setField(service, "baseUrl", null);
                assertThatThrownBy(() -> service.validateBaseUrl())
                                .isInstanceOf(IllegalStateException.class);
        }

        @Test
        void validateBaseUrl_localhost_warnsButPasses() {
                ReflectionTestUtils.setField(service, "baseUrl", "http://localhost:8085");
                service.validateBaseUrl();
        }

        @Test
        void validateBaseUrl_valid_passes() {
                ReflectionTestUtils.setField(service, "baseUrl", "https://vaultly.example");
                service.validateBaseUrl();
        }
}
package com.efedotov.vaultly.controller;

import com.efedotov.vaultly.dto.file.DecryptionMetadata;
import com.efedotov.vaultly.dto.tempaccess.TempLinkInfo;
import com.efedotov.vaultly.dto.tempaccess.TempLinkResponse;
import com.efedotov.vaultly.model.TempFileAccess;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.DeviceService;
import com.efedotov.vaultly.service.FileService;
import com.efedotov.vaultly.service.TempAccessService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = TempAccessController.class)
class TempAccessControllerTest extends BaseControllerTest {

        private static final String BASE = "/tempacces/version132";

        @Autowired
        MockMvc mockMvc;

        @MockitoBean
        TempAccessService tempAccessService;
        @MockitoBean
        DeviceService deviceService;
        @MockitoBean
        FileService fileService;

        private UUID userId;
        private UsernamePasswordAuthenticationToken auth;

        @BeforeEach
        void setUp() {
                userId = UUID.randomUUID();
                User user = User.builder().id(userId).username("alice").isActive(true).build();
                CustomUserDetails principal = new CustomUserDetails(user);
                auth = new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities());
                SecurityContextHolder.getContext().setAuthentication(auth);
        }

        @AfterEach
        void tearDown() {
                SecurityContextHolder.clearContext();
        }

        private TempLinkInfo info() {
                return TempLinkInfo.builder()
                                .fileName("doc.pdf")
                                .mimeType("application/pdf")
                                .expiresAt(LocalDateTime.now().plusHours(1))
                                .hasPassword(false)
                                .build();
        }

        

        @Test
        void setFilePublic_returns200() throws Exception {
                UUID fileId = UUID.randomUUID();
                String body = """
                                {"isPublic":true}
                                """;

                mockMvc.perform(post(BASE + "/files/{fileId}/public", fileId)
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk());

                verify(tempAccessService).setFilePublic(fileId, true);
        }

        @Test
        void setFilePublic_nullValue_returns200() throws Exception {
                UUID fileId = UUID.randomUUID();
                String body = """
                                {"isPublic":false}
                                """;

                mockMvc.perform(post(BASE + "/files/{fileId}/public", fileId)
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk());

                verify(tempAccessService).setFilePublic(fileId, false);
        }

        

        @Test
        void createTempLink_returnsResponse() throws Exception {
                UUID fileId = UUID.randomUUID();
                TempLinkResponse resp = new TempLinkResponse();
                resp.setToken("tok");
                resp.setAccessUrl("https://example.com/tempacces/version132/temp-access/tok");

                when(tempAccessService.createTempLink(any())).thenReturn(resp);

                String body = """
                                {"fileId":"%s","expiresAt":"2030-01-01T00:00:00","maxDownloads":5}
                                """.formatted(fileId);

                mockMvc.perform(post(BASE + "/temp-access/create")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.token").value("tok"))
                                .andExpect(jsonPath("$.accessUrl")
                                                .value("https://example.com/tempacces/version132/temp-access/tok"));
        }

        @Test
        void createTempLink_missingFileId_returns400() throws Exception {
                String body = """
                                {"expiresAt":"2030-01-01T00:00:00"}
                                """;

                mockMvc.perform(post(BASE + "/temp-access/create")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isBadRequest());
        }

        @Test
        void createTempLink_maxDownloadsOutOfRange_returns400() throws Exception {
                UUID fileId = UUID.randomUUID();
                String body = """
                                {"fileId":"%s","expiresAt":"2030-01-01T00:00:00","maxDownloads":0}
                                """.formatted(fileId);

                mockMvc.perform(post(BASE + "/temp-access/create")
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isBadRequest());
        }

        

        @Test
        void checkTempLinkPassword_valid_returns200() throws Exception {
                when(tempAccessService.validateTempLink(eq("tok"), any())).thenReturn(null);

                mockMvc.perform(post(BASE + "/temp-access/{token}/metadata", "tok")
                                .param("password", "p"))
                                .andExpect(status().isOk());

                verify(tempAccessService).validateTempLink("tok", "p");
        }

        @Test
        void checkTempLinkPassword_noPassword_returns200() throws Exception {
                when(tempAccessService.validateTempLink(eq("tok"), eq(null))).thenReturn(null);

                mockMvc.perform(post(BASE + "/temp-access/{token}/metadata", "tok"))
                                .andExpect(status().isOk());

                verify(tempAccessService).validateTempLink("tok", null);
        }

        @Test
        void checkTempLinkPassword_invalid_returns400() throws Exception {
                when(tempAccessService.validateTempLink(eq("tok"), any()))
                                .thenThrow(new com.efedotov.vaultly.exception.BadRequestException("Invalid password"));

                mockMvc.perform(post(BASE + "/temp-access/{token}/metadata", "tok")
                                .param("password", "wrong"))
                                .andExpect(status().isBadRequest());
        }

        

        @Test
        void downloadByTempLinkStreaming_returnsStreamHeaders() throws Exception {
                when(tempAccessService.getTempLinkInfo("tok")).thenReturn(info());

                mockMvc.perform(get(BASE + "/temp-access/{token}/download", "tok"))
                                .andExpect(status().isOk())
                                .andExpect(header().string("Content-Type", "application/pdf"))
                                .andExpect(header().string("Content-Disposition",
                                                org.hamcrest.Matchers.containsString("attachment")))
                                .andExpect(header().string("Content-Disposition",
                                                org.hamcrest.Matchers.containsString("doc.pdf")));

                verify(tempAccessService).getTempLinkInfo("tok");
        }

        @Test
        void downloadByTempLinkStreaming_notFound_returns404() throws Exception {
                when(tempAccessService.getTempLinkInfo("tok"))
                                .thenThrow(new com.efedotov.vaultly.exception.NotFoundException("not found"));

                mockMvc.perform(get(BASE + "/temp-access/{token}/download", "tok"))
                                .andExpect(status().isNotFound());
        }

        

        @Test
        void getTempAccessPage_authenticated_returnsView() throws Exception {
                when(tempAccessService.getTempLinkInfo("tok")).thenReturn(info());

                mockMvc.perform(get(BASE + "/{token}", "tok").with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(content().string(org.hamcrest.Matchers.containsString("temp-download")));
        }

        @Test
        void getTempAccessPage_notAuthenticated_returnsView() throws Exception {
                SecurityContextHolder.clearContext(); 

                when(tempAccessService.getTempLinkInfo("tok")).thenReturn(info());

                mockMvc.perform(get(BASE + "/{token}", "tok"))
                                .andExpect(status().isOk())
                                .andExpect(content().string(org.hamcrest.Matchers.containsString("temp-download")));
        }

        

        @Test
        void showDownloadPage_authenticated_registersDevice() throws Exception {
                when(tempAccessService.getTempLinkInfo("tok")).thenReturn(info());

                mockMvc.perform(get(BASE + "/temp-access/{token}", "tok").with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(content().string(org.hamcrest.Matchers.containsString("temp-download")));

                verify(deviceService).ensureTempDownloadDeviceExists(userId);
        }

        @Test
        void showDownloadPage_notAuthenticated_noDeviceRegistration() throws Exception {
                SecurityContextHolder.clearContext(); 

                when(tempAccessService.getTempLinkInfo("tok")).thenReturn(info());

                mockMvc.perform(get(BASE + "/temp-access/{token}", "tok"))
                                .andExpect(status().isOk())
                                .andExpect(content().string(org.hamcrest.Matchers.containsString("temp-download")));

                verify(deviceService, never()).ensureTempDownloadDeviceExists(any());
        }

        
        

        @Test
        void getDecryptionMetadata_withoutAuth_returns401() throws Exception {
                
                SecurityContextHolder.clearContext();

                mockMvc.perform(post(BASE + "/temp-access/{token}/decryption-metadata", "tok"))
                                .andExpect(status().isUnauthorized());
        }

        @Test
        void getDecryptionMetadata_success_returnsMetadata() throws Exception {
                TempFileAccess ta = TempFileAccess.builder().token("tok").build();
                DecryptionMetadata md = new DecryptionMetadata();
                md.setEncryptedKey("enc");
                md.setIv("iv");
                md.setOriginalSize(100);
                md.setFileName("doc.pdf");

                when(tempAccessService.validateTempLink(eq("tok"), any())).thenReturn(ta);
                when(fileService.getDecryptionMetadataForTempAccess(eq(ta), eq(userId))).thenReturn(md);

                mockMvc.perform(post(BASE + "/temp-access/{token}/decryption-metadata", "tok")
                                .with(authentication(auth))
                                .param("password", "p"))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.encryptedKey").value("enc"))
                                .andExpect(jsonPath("$.originalSize").value(100));

                verify(tempAccessService).incrementDownloadCount("tok");
        }

        @Test
        void getDecryptionMetadata_noPasswordParam_ok() throws Exception {
                TempFileAccess ta = TempFileAccess.builder().token("tok").build();
                DecryptionMetadata md = new DecryptionMetadata();
                md.setEncryptedKey("enc");
                md.setIv("iv");
                md.setOriginalSize(50);
                md.setFileName("doc.pdf");

                when(tempAccessService.validateTempLink(eq("tok"), eq(null))).thenReturn(ta);
                when(fileService.getDecryptionMetadataForTempAccess(eq(ta), eq(userId))).thenReturn(md);

                mockMvc.perform(post(BASE + "/temp-access/{token}/decryption-metadata", "tok")
                                .with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.encryptedKey").value("enc"));
        }

        @Test
        void getDecryptionMetadata_invalidLink_returns400() throws Exception {
                when(tempAccessService.validateTempLink(eq("tok"), any()))
                                .thenThrow(new com.efedotov.vaultly.exception.BadRequestException("expired"));

                mockMvc.perform(post(BASE + "/temp-access/{token}/decryption-metadata", "tok")
                                .with(authentication(auth)))
                                .andExpect(status().isBadRequest());

                verify(tempAccessService, never()).incrementDownloadCount(any());
        }
}
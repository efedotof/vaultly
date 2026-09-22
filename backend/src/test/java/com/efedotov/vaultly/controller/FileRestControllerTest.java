package com.efedotov.vaultly.controller;

import com.efedotov.vaultly.dto.file.DecryptionMetadata;
import com.efedotov.vaultly.dto.file.FileDto;
import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.model.FileContent;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.FileService;
import com.efedotov.vaultly.service.S3Service;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = FileRestController.class)
class FileRestControllerTest extends BaseControllerTest {

        @Autowired
        MockMvc mockMvc;

        @MockitoBean
        FileService fileService;
        @MockitoBean
        S3Service s3Service;

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

        private File sampleFile() {
                FileContent c = FileContent.builder()
                                .id(UUID.randomUUID()).s3Key("some-key").s3Url("https://cdn/x").build();
                return File.builder()
                                .id(UUID.randomUUID()).name("doc").originalName("doc.shps")
                                .size(100L).mimeType("application/x-shirmps")
                                .isEncrypted(true).isPublic(false).isNote(false)
                                .fileContent(c).user(User.builder().id(userId).build())
                                .build();
        }

        private FileDto dtoFrom(File f) {
                FileDto dto = new FileDto();
                dto.setId(f.getId());
                dto.setName(f.getName());
                dto.setOriginalName(f.getOriginalName());
                dto.setSize(f.getSize());
                dto.setMimeType(f.getMimeType());
                dto.setIsEncrypted(f.getIsEncrypted());
                dto.setIsPublic(f.getIsPublic());
                dto.setIsNote(f.getIsNote());
                if (f.getFolder() != null) {
                        dto.setFolderId(f.getFolder().getId());
                        dto.setFolderName(f.getFolder().getName());
                }
                return dto;
        }

        

        @Test
        void getAllFiles_defaultPagination_returns200() throws Exception {
                when(fileService.getAllFilesForUser(eq(userId), any()))
                                .thenReturn(new PageImpl<>(List.of(), PageRequest.of(0, 20), 0));

                mockMvc.perform(get("/api/files").with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        void getAllFiles_invalidPagination_returns400() throws Exception {
                mockMvc.perform(get("/api/files?page=-1&size=20").with(authentication(auth)))
                                .andExpect(status().isBadRequest());

                mockMvc.perform(get("/api/files?page=0&size=1000").with(authentication(auth)))
                                .andExpect(status().isBadRequest());
        }

        

        @Test
        void getRecentFiles_returnsPage() throws Exception {
                when(fileService.getLatestFilesForUser(eq(userId), any()))
                                .thenReturn(new PageImpl<>(List.of(), PageRequest.of(0, 10), 0));

                mockMvc.perform(get("/api/files/recent").with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        void getRecentFiles_invalidPagination_returns400() throws Exception {
                mockMvc.perform(get("/api/files/recent?page=-1").with(authentication(auth)))
                                .andExpect(status().isBadRequest());
        }

        

        @Test
        void getNotes_returnsPage() throws Exception {
                when(fileService.getUsersNodes(eq(userId), eq(0), eq(20)))
                                .thenReturn(new PageImpl<>(List.of(), PageRequest.of(0, 20), 0));

                mockMvc.perform(get("/api/files/notes").with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.content").isArray());
        }

        

        @Test
        void uploadShps_success_returnsFileDto() throws Exception {
                MockMultipartFile file = new MockMultipartFile(
                                "file", "doc.shps", "application/x-shirmps", new byte[] { 1, 2, 3 });

                when(fileService.uploadShpsFile(any(), any(), eq(false), any(), eq(userId)))
                                .thenReturn(dtoFrom(sampleFile()));

                mockMvc.perform(multipart("/api/files/upload/shps")
                                .file(file)
                                .param("isPublic", "false")
                                .with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.name").value("doc"));
        }

        @Test
        void uploadShps_withFolderAndHash_passesAllParams() throws Exception {
                UUID folderId = UUID.randomUUID();
                String hash = "a".repeat(64);
                MockMultipartFile file = new MockMultipartFile(
                                "file", "doc.shps", "application/x-shirmps", new byte[] { 1, 2, 3 });

                when(fileService.uploadShpsFile(any(), eq(folderId), eq(true), eq(hash), eq(userId)))
                                .thenReturn(dtoFrom(sampleFile()));

                mockMvc.perform(multipart("/api/files/upload/shps")
                                .file(file)
                                .param("folderId", folderId.toString())
                                .param("isPublic", "true")
                                .param("contentHash", hash)
                                .with(authentication(auth)))
                                .andExpect(status().isOk());
        }

        

        @Test
        void uploadPublicFile_success_returnsFileDto() throws Exception {
                MockMultipartFile file = new MockMultipartFile(
                                "file", "doc.txt", "text/plain", new byte[] { 1, 2, 3 });
                File publicFile = sampleFile();
                publicFile.setIsPublic(true);

                when(fileService.uploadPublicFile(any(), any(), any(), eq(userId)))
                                .thenReturn(dtoFrom(publicFile));

                mockMvc.perform(multipart("/api/files/upload/public")
                                .file(file)
                                .with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.isPublic").value(true));
        }

        

        @Test
        void createNote_returnsFileDto() throws Exception {
                MockMultipartFile file = new MockMultipartFile(
                                "file", "note.shps", "application/x-shirmps", new byte[] { 1, 2, 3 });
                File note = sampleFile();
                note.setIsNote(true);
                note.setName("note");

                when(fileService.createNote(any(), any(), eq(userId))).thenReturn(note);

                mockMvc.perform(multipart("/api/files/notes")
                                .file(file)
                                .with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.name").value("note"))
                                .andExpect(jsonPath("$.isNote").value(true));
        }

        

        @Test
        void updateNoteContent_returnsUpdatedDto() throws Exception {
                UUID noteId = UUID.randomUUID();
                MockMultipartFile file = new MockMultipartFile(
                                "file", "note.shps", "application/x-shirmps", new byte[] { 1, 2, 3 });
                File note = sampleFile();
                note.setIsNote(true);

                when(fileService.updateNoteContent(eq(noteId), any(), eq(userId))).thenReturn(note);

                mockMvc.perform(multipart("/api/files/notes/{id}/content", noteId)
                                .file(file)
                                .with(req -> {
                                        req.setMethod("PUT");
                                        return req;
                                })
                                .with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.id").value(note.getId().toString()));
        }

        

        @Test
        void downloadFile_returnsPresignedUrl() throws Exception {
                UUID fileId = UUID.randomUUID();
                File file = sampleFile();

                when(fileService.getFileById(fileId, userId)).thenReturn(file);
                when(s3Service.generatePresignedUrl(eq("some-key"), any()))
                                .thenReturn("https://s3/presigned");

                mockMvc.perform(get("/api/files/{id}/download", fileId).with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.url").value("https://s3/presigned"));
        }

        

        @Test
        void getDecryptionMetadata_returnsMetadata() throws Exception {
                UUID fileId = UUID.randomUUID();
                DecryptionMetadata md = new DecryptionMetadata();
                md.setEncryptedKey("enc");
                md.setIv("iv");
                md.setOriginalSize(100);
                md.setFileName("doc.shps");

                when(fileService.getDecryptionMetadataForUser(fileId, userId)).thenReturn(md);

                mockMvc.perform(get("/api/files/{id}/content", fileId).with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.encryptedKey").value("enc"))
                                .andExpect(jsonPath("$.originalSize").value(100));
        }

        

        @Test
        void deleteFile_returns204() throws Exception {
                UUID fileId = UUID.randomUUID();

                mockMvc.perform(delete("/api/files/{id}", fileId).with(authentication(auth)))
                                .andExpect(status().isNoContent());

                verify(fileService).deleteFile(fileId, userId);
        }

        

        @Test
        void checkDuplicate_returnsTrue() throws Exception {
                when(fileService.existsFileContentForUser(anyString(), any(), eq(userId)))
                                .thenReturn(true);

                String body = """
                                {"hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","isPublic":false}
                                """;

                mockMvc.perform(post("/api/files/check-duplicate")
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.exists").value(true));
        }

        @Test
        void checkDuplicate_returnsFalse() throws Exception {
                when(fileService.existsFileContentForUser(anyString(), any(), eq(userId)))
                                .thenReturn(false);

                String body = """
                                {"hash":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","isPublic":true}
                                """;

                mockMvc.perform(post("/api/files/check-duplicate")
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.exists").value(false));
        }

        

        @Test
        void linkExistingFile_returnsDto() throws Exception {
                UUID contentId = UUID.randomUUID();
                File linked = sampleFile();

                when(fileService.linkExistingFile(eq(userId), eq(contentId), anyString(), any(), eq(false)))
                                .thenReturn(linked);

                String body = """
                                {"fileContentId":"%s","fileName":"linked.shps","isPublic":false}
                                """.formatted(contentId);

                mockMvc.perform(post("/api/files/link")
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.id").value(linked.getId().toString()));
        }
}
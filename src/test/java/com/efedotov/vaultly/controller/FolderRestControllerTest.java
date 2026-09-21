package com.efedotov.vaultly.controller;

import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.model.Folder;
import com.efedotov.vaultly.model.FolderAccess;
import com.efedotov.vaultly.model.FolderType;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.security.CustomUserDetails;
import com.efedotov.vaultly.service.FolderService;
import com.efedotov.vaultly.service.LoginAttemptService;
import com.efedotov.vaultly.service.PasswordCheckResult;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = FolderRestController.class)
class FolderRestControllerTest extends BaseControllerTest {

        @Autowired
        MockMvc mockMvc;

        @MockitoBean
        FolderService folderService;
        @MockitoBean
        LoginAttemptService loginAttemptService;

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

        private Folder folder(String name) {
                return Folder.builder()
                                .id(UUID.randomUUID()).name(name).type(FolderType.CUSTOM).build();
        }

        

        @Test
        void createFolder_valid_returnsDto() throws Exception {
                Folder folder = folder("Photos");
                when(folderService.createFolder(any(), any())).thenReturn(folder);

                mockMvc.perform(post("/api/folders")
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                                {"name":"Photos"}
                                                """))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.name").value("Photos"));
        }

        @Test
        void createFolder_blankName_returns400() throws Exception {
                mockMvc.perform(post("/api/folders")
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                                {"name":""}
                                                """))
                                .andExpect(status().isBadRequest());
        }

        

        @Test
        void deleteFolder_returns200() throws Exception {
                UUID folderId = UUID.randomUUID();

                mockMvc.perform(delete("/api/folders/{id}", folderId)
                                .with(authentication(auth)))
                                .andExpect(status().isOk());

                verify(folderService).deleteFolder(folderId, userId);
        }

        

        @Test
        void renameFolder_valid_returnsDto() throws Exception {
                UUID folderId = UUID.randomUUID();
                Folder renamed = folder("New name");

                when(folderService.renameFolder(eq(folderId), any(), any())).thenReturn(renamed);

                mockMvc.perform(put("/api/folders/{id}", folderId)
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                                {"name":"New name"}
                                                """))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.name").value("New name"));
        }

        @Test
        void renameFolder_blankName_returns400() throws Exception {
                mockMvc.perform(put("/api/folders/{id}", UUID.randomUUID())
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                                {"name":""}
                                                """))
                                .andExpect(status().isBadRequest());
        }

        

        @Test
        void addFileToFolder_valid_returnsFileDto() throws Exception {
                UUID folderId = UUID.randomUUID();
                UUID fileId = UUID.randomUUID();
                File f = File.builder().id(fileId).name("doc")
                                .user(User.builder().id(userId).build()).build();

                when(folderService.addFileToFolder(eq(fileId), eq(folderId), eq(userId))).thenReturn(f);

                mockMvc.perform(post("/api/folders/{id}/files", folderId)
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                                {"fileId":"%s"}
                                                """.formatted(fileId)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.id").value(fileId.toString()));
        }

        

        @Test
        void moveFiles_valid_returnsList() throws Exception {
                UUID targetId = UUID.randomUUID();
                UUID fileId = UUID.randomUUID();
                File f = File.builder().id(fileId).name("doc")
                                .user(User.builder().id(userId).build()).build();

                when(folderService.moveFiles(any(), eq(userId))).thenReturn(List.of(f));

                mockMvc.perform(post("/api/folders/move")
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                                {"fileIds":["%s"],"targetFolderId":"%s","copy":false}
                                                """.formatted(fileId, targetId)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$[0].id").value(fileId.toString()));
        }

        
        

        @Test
        void removeFileFromFolder_returnsFileDto() throws Exception {
                UUID folderId = UUID.randomUUID();
                UUID fileId = UUID.randomUUID();
                File f = File.builder().id(fileId).name("doc")
                                .user(User.builder().id(userId).build()).build();

                when(folderService.removeFileFromFolder(eq(fileId), eq(userId))).thenReturn(f);

                mockMvc.perform(delete("/api/folders/{folderId}/files/{fileId}", folderId, fileId)
                                .with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.id").value(fileId.toString()));
        }

        

        @Test
        void closeFolder_returnsDto() throws Exception {
                UUID folderId = UUID.randomUUID();
                Folder closed = folder("Photos");

                when(folderService.closeFolderForOthers(eq(folderId), eq(userId))).thenReturn(closed);

                mockMvc.perform(post("/api/folders/{id}/close", folderId)
                                .with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.name").value("Photos"));
        }

        

        @Test
        void shareFolder_valid_returnsAccessList() throws Exception {
                UUID folderId = UUID.randomUUID();
                UUID targetUser = UUID.randomUUID();

                FolderAccess access = FolderAccess.builder()
                                .id(UUID.randomUUID())
                                .accessLevel(FolderAccess.AccessLevel.READ)
                                .build();
                when(folderService.shareFolder(any(), eq(userId))).thenReturn(List.of(access));

                mockMvc.perform(post("/api/folders/{id}/share", folderId)
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                                {"userIds":["%s"]}
                                                """.formatted(targetUser)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$[0].id").value(access.getId().toString()));
        }

        

        @Test
        void checkFolderAccess_rateLimited_returnsFalse() throws Exception {
                when(loginAttemptService.isFolderCheckBlocked(anyString())).thenReturn(true);

                mockMvc.perform(post("/api/folders/{id}/access/check", UUID.randomUUID())
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                                {"password":"x"}
                                                """))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$").value(false));
        }

        @Test
        void checkFolderAccess_passwordMissing_returnsFalse() throws Exception {
                UUID folderId = UUID.randomUUID();
                Folder f = folder("locked");

                when(loginAttemptService.isFolderCheckBlocked(anyString())).thenReturn(false);
                when(folderService.getFolderById(folderId)).thenReturn(f);
                when(folderService.hasActivePassword(folderId, userId)).thenReturn(true);

                mockMvc.perform(post("/api/folders/{id}/access/check", folderId)
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{}"))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$").value(false));
        }

        @Test
        void checkFolderAccess_correctPassword_returnsTrue() throws Exception {
                UUID folderId = UUID.randomUUID();
                Folder f = folder("locked");

                when(loginAttemptService.isFolderCheckBlocked(anyString())).thenReturn(false);
                when(folderService.getFolderById(folderId)).thenReturn(f);
                when(folderService.hasActivePassword(folderId, userId)).thenReturn(true);
                when(folderService.checkFolderPassword(folderId, "good"))
                                .thenReturn(PasswordCheckResult.OK);

                mockMvc.perform(post("/api/folders/{id}/access/check", folderId)
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                                {"password":"good"}
                                                """))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$").value(true));
        }

        @Test
        void checkFolderAccess_wrongPassword_returnsFalse() throws Exception {
                UUID folderId = UUID.randomUUID();
                Folder f = folder("locked");

                when(loginAttemptService.isFolderCheckBlocked(anyString())).thenReturn(false);
                when(folderService.getFolderById(folderId)).thenReturn(f);
                when(folderService.hasActivePassword(folderId, userId)).thenReturn(true);
                when(folderService.checkFolderPassword(folderId, "bad"))
                                .thenReturn(PasswordCheckResult.INVALID);

                mockMvc.perform(post("/api/folders/{id}/access/check", folderId)
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                                {"password":"bad"}
                                                """))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$").value(false));
        }

        @Test
        void checkFolderAccess_passwordBlocked_returnsFalse() throws Exception {
                UUID folderId = UUID.randomUUID();
                Folder f = folder("locked");

                when(loginAttemptService.isFolderCheckBlocked(anyString())).thenReturn(false);
                when(folderService.getFolderById(folderId)).thenReturn(f);
                when(folderService.hasActivePassword(folderId, userId)).thenReturn(true);
                when(folderService.checkFolderPassword(folderId, "x"))
                                .thenReturn(PasswordCheckResult.BLOCKED);

                mockMvc.perform(post("/api/folders/{id}/access/check", folderId)
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                                {"password":"x"}
                                                """))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$").value(false));
        }

        @Test
        void checkFolderAccess_hiddenKey_returnsResult() throws Exception {
                UUID folderId = UUID.randomUUID();
                Folder f = folder("hidden");

                when(loginAttemptService.isFolderCheckBlocked(anyString())).thenReturn(false);
                when(folderService.getFolderById(folderId)).thenReturn(f);
                when(folderService.hasActivePassword(folderId, userId)).thenReturn(false);
                when(folderService.checkHiddenFolderKey(folderId, "my-key")).thenReturn(true);

                mockMvc.perform(post("/api/folders/{id}/access/check", folderId)
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                                {"hiddenFolderKey":"my-key"}
                                                """))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$").value(true));
        }

        @Test
        void checkFolderAccess_noPasswordNoKey_checksAccessAndReturnsTrue() throws Exception {
                UUID folderId = UUID.randomUUID();
                Folder f = folder("plain");

                when(loginAttemptService.isFolderCheckBlocked(anyString())).thenReturn(false);
                when(folderService.getFolderById(folderId)).thenReturn(f);
                when(folderService.hasActivePassword(folderId, userId)).thenReturn(false);

                mockMvc.perform(post("/api/folders/{id}/access/check", folderId)
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{}"))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$").value(true));

                verify(folderService).checkFolderAccess(f, userId, FolderAccess.AccessLevel.READ);
        }

        

        @Test
        void getFolderTree_returnsList() throws Exception {
                Folder root = folder("Root");
                when(folderService.getFolderTree(userId)).thenReturn(List.of(root));

                mockMvc.perform(get("/api/folders/tree").with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$[0].name").value("Root"));
        }

        

        @Test
        void getFolderFiles_returnsPage() throws Exception {
                UUID folderId = UUID.randomUUID();
                when(folderService.getFolderFilesPaged(eq(folderId), eq(userId), any()))
                                .thenReturn(new PageImpl<>(List.of(), PageRequest.of(0, 50), 0));

                mockMvc.perform(get("/api/folders/{id}/files", folderId)
                                .with(authentication(auth)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        void getFolderFiles_invalidPagination_returns400() throws Exception {
                UUID folderId = UUID.randomUUID();
                mockMvc.perform(get("/api/folders/{id}/files?page=-1", folderId)
                                .with(authentication(auth)))
                                .andExpect(status().isBadRequest());
        }

        

        @Test
        void setFolderPassword_returns200() throws Exception {
                UUID folderId = UUID.randomUUID();

                mockMvc.perform(post("/api/folders/{id}/password", folderId)
                                .with(authentication(auth))
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("""
                                                {"password":"secret"}
                                                """))
                                .andExpect(status().isOk());

                verify(folderService).setFolderPassword(folderId, "secret", userId);
        }
}
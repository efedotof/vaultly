package com.efedotov.vaultly.service;

import com.efedotov.vaultly.dto.folder.FolderCreateDto;
import com.efedotov.vaultly.dto.folder.FolderMoveDto;
import com.efedotov.vaultly.dto.folder.FolderShareDto;
import com.efedotov.vaultly.dto.folder.FolderUpdateDto;
import com.efedotov.vaultly.model.File;
import com.efedotov.vaultly.model.FileContent;
import com.efedotov.vaultly.model.Folder;
import com.efedotov.vaultly.model.FolderAccess;
import com.efedotov.vaultly.model.FolderPassword;
import com.efedotov.vaultly.model.FolderType;
import com.efedotov.vaultly.model.User;
import com.efedotov.vaultly.repository.FileRepository;
import com.efedotov.vaultly.repository.FolderAccessRepository;
import com.efedotov.vaultly.repository.FolderPasswordRepository;
import com.efedotov.vaultly.repository.FolderRepository;
import com.efedotov.vaultly.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FolderServiceTest {

    @Mock
    FolderRepository folderRepository;
    @Mock
    FileRepository fileRepository;
    @Mock
    FolderAccessRepository folderAccessRepository;
    @Mock
    FolderPasswordRepository folderPasswordRepository;
    @Mock
    UserRepository userRepository;
    @Mock
    PasswordEncoder passwordEncoder;
    @Mock
    LoginAttemptService loginAttemptService;

    @InjectMocks
    FolderService service;

    private User user(UUID id) {
        User u = new User();
        u.setId(id);
        u.setUsername("u" + id);
        return u;
    }

    private Folder folder(UUID ownerId, String name) {
        return Folder.builder()
                .id(UUID.randomUUID())
                .user(user(ownerId))
                .name(name)
                .type(FolderType.CUSTOM)
                .isDeleted(false)
                .isHidden(false)
                .build();
    }

    private static String sha256Hex(String s) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(s.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    @Test
    void getFolderById_found_returns() {
        UUID id = UUID.randomUUID();
        Folder f = folder(UUID.randomUUID(), "root");
        when(folderRepository.findByIdWithUser(id)).thenReturn(Optional.of(f));

        assertThat(service.getFolderById(id)).isSameAs(f);
    }

    @Test
    void getFolderById_notFound_throws() {
        UUID id = UUID.randomUUID();
        when(folderRepository.findByIdWithUser(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getFolderById(id))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("не найдена");
    }

    @Test
    void checkFolderAccess_owner_passes() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(uid, "f");
        service.checkFolderAccess(f, uid, FolderAccess.AccessLevel.OWNER);
    }

    @Test
    void checkFolderAccess_deleted_throws() {
        UUID uid = UUID.randomUUID();
        Folder f = Folder.builder().user(user(uid)).isDeleted(true).build();
        assertThatThrownBy(() -> service.checkFolderAccess(f, uid, FolderAccess.AccessLevel.READ))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("удалена");
    }

    @Test
    void checkFolderAccess_noAccessRecord_throws() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(UUID.randomUUID(), "f");
        when(folderAccessRepository.findByFolderIdAndUserId(f.getId(), uid))
                .thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.checkFolderAccess(f, uid, FolderAccess.AccessLevel.READ))
                .isInstanceOf(SecurityException.class);
    }

    @Test
    void checkFolderAccess_revoked_throws() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(UUID.randomUUID(), "f");
        FolderAccess fa = FolderAccess.builder()
                .accessLevel(FolderAccess.AccessLevel.READ).isActive(false).build();
        when(folderAccessRepository.findByFolderIdAndUserId(f.getId(), uid))
                .thenReturn(Optional.of(fa));
        assertThatThrownBy(() -> service.checkFolderAccess(f, uid, FolderAccess.AccessLevel.READ))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("отозван");
    }

    @Test
    void checkFolderAccess_insufficientLevel_throws() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(UUID.randomUUID(), "f");
        FolderAccess fa = FolderAccess.builder()
                .accessLevel(FolderAccess.AccessLevel.READ).isActive(true).build();
        when(folderAccessRepository.findByFolderIdAndUserId(f.getId(), uid))
                .thenReturn(Optional.of(fa));
        assertThatThrownBy(() -> service.checkFolderAccess(f, uid, FolderAccess.AccessLevel.WRITE))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("Недостаточно прав");
    }

    @Test
    void checkFolderAccess_sufficient_passes() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(UUID.randomUUID(), "f");
        FolderAccess fa = FolderAccess.builder()
                .accessLevel(FolderAccess.AccessLevel.WRITE).isActive(true).build();
        when(folderAccessRepository.findByFolderIdAndUserId(f.getId(), uid))
                .thenReturn(Optional.of(fa));
        service.checkFolderAccess(f, uid, FolderAccess.AccessLevel.READ);
    }

    @Test
    void createFolder_noUser_throws() {
        UUID uid = UUID.randomUUID();
        when(userRepository.findById(uid)).thenReturn(Optional.empty());

        FolderCreateDto req = new FolderCreateDto();
        req.setName("Photos");

        assertThatThrownBy(() -> service.createFolder(req, uid))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Пользователь");
    }

    @Test
    void createFolder_root_success() {
        UUID uid = UUID.randomUUID();
        User u = user(uid);
        when(userRepository.findById(uid)).thenReturn(Optional.of(u));
        when(folderRepository.existsByUserAndNameAndParentFolder(u, "Photos", null))
                .thenReturn(false);
        when(folderRepository.save(any(Folder.class))).thenAnswer(inv -> inv.getArgument(0));
        when(folderAccessRepository.save(any(FolderAccess.class))).thenAnswer(inv -> inv.getArgument(0));

        FolderCreateDto req = new FolderCreateDto();
        req.setName("Photos");

        Folder result = service.createFolder(req, uid);

        assertThat(result.getName()).isEqualTo("Photos");
        assertThat(result.getType()).isEqualTo(FolderType.CUSTOM);
        verify(folderAccessRepository).save(any(FolderAccess.class));
    }

    @Test
    void createFolder_nameConflict_throws() {
        UUID uid = UUID.randomUUID();
        User u = user(uid);
        when(userRepository.findById(uid)).thenReturn(Optional.of(u));
        when(folderRepository.existsByUserAndNameAndParentFolder(u, "Photos", null))
                .thenReturn(true);

        FolderCreateDto req = new FolderCreateDto();
        req.setName("Photos");

        assertThatThrownBy(() -> service.createFolder(req, uid))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("уже существует");
    }

    @Test
    void createFolder_withParent_success() {
        UUID uid = UUID.randomUUID();
        UUID parentId = UUID.randomUUID();
        User u = user(uid);
        Folder parent = folder(uid, "parent");

        when(userRepository.findById(uid)).thenReturn(Optional.of(u));
        when(folderRepository.findById(parentId)).thenReturn(Optional.of(parent));
        when(folderRepository.existsByUserAndNameAndParentFolder(u, "child", parent))
                .thenReturn(false);
        when(folderRepository.save(any(Folder.class))).thenAnswer(inv -> inv.getArgument(0));
        when(folderAccessRepository.save(any(FolderAccess.class))).thenAnswer(inv -> inv.getArgument(0));

        FolderCreateDto req = new FolderCreateDto();
        req.setName("child");
        req.setParentFolderId(parentId);

        Folder result = service.createFolder(req, uid);

        assertThat(result.getParentFolder()).isSameAs(parent);
        assertThat(result.getName()).isEqualTo("child");
    }

    @Test
    void createFolder_parentNotFound_throws() {
        UUID uid = UUID.randomUUID();
        UUID parentId = UUID.randomUUID();
        when(userRepository.findById(uid)).thenReturn(Optional.of(user(uid)));
        when(folderRepository.findById(parentId)).thenReturn(Optional.empty());

        FolderCreateDto req = new FolderCreateDto();
        req.setName("child");
        req.setParentFolderId(parentId);

        assertThatThrownBy(() -> service.createFolder(req, uid))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Родительская");
    }

    @Test
    void createFolder_withHiddenKey_encodesKey() {
        UUID uid = UUID.randomUUID();
        User u = user(uid);
        when(userRepository.findById(uid)).thenReturn(Optional.of(u));
        when(folderRepository.existsByUserAndNameAndParentFolder(u, "secret", null))
                .thenReturn(false);
        when(folderRepository.save(any(Folder.class))).thenAnswer(inv -> inv.getArgument(0));
        when(folderAccessRepository.save(any(FolderAccess.class))).thenAnswer(inv -> inv.getArgument(0));
        when(passwordEncoder.encode("hidden-key")).thenReturn("$2a$hashed");

        FolderCreateDto req = new FolderCreateDto();
        req.setName("secret");
        req.setIsHidden(true);
        req.setHiddenFolderKey("hidden-key");

        Folder result = service.createFolder(req, uid);

        assertThat(result.getHiddenFolderKeyHash()).isEqualTo("$2a$hashed");
        verify(passwordEncoder).encode("hidden-key");
    }

    @Test
    void createFolder_withPassword_savesPassword() {
        UUID uid = UUID.randomUUID();
        User u = user(uid);
        when(userRepository.findById(uid)).thenReturn(Optional.of(u));
        when(folderRepository.existsByUserAndNameAndParentFolder(u, "locked", null))
                .thenReturn(false);
        when(folderRepository.save(any(Folder.class))).thenAnswer(inv -> inv.getArgument(0));
        when(folderAccessRepository.save(any(FolderAccess.class))).thenAnswer(inv -> inv.getArgument(0));
        when(passwordEncoder.encode("secret-pw")).thenReturn("$2a$pw-hash");
        when(folderPasswordRepository.save(any(FolderPassword.class))).thenAnswer(inv -> inv.getArgument(0));

        FolderCreateDto req = new FolderCreateDto();
        req.setName("locked");
        req.setPassword("secret-pw");

        service.createFolder(req, uid);

        verify(folderPasswordRepository).save(any(FolderPassword.class));
    }

    @Test
    void deleteFolder_notFound_throws() {
        UUID uid = UUID.randomUUID();
        UUID fid = UUID.randomUUID();
        when(folderRepository.findById(fid)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.deleteFolder(fid, uid))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void deleteFolder_noAccess_throws() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(UUID.randomUUID(), "f");
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(folderAccessRepository.findByFolderIdAndUserId(f.getId(), uid))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.deleteFolder(f.getId(), uid))
                .isInstanceOf(SecurityException.class);
    }

    @Test
    void deleteFolder_owner_softDeletesRecursively() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(uid, "root");

        File file1 = File.builder().id(UUID.randomUUID()).user(user(uid)).isDeleted(false).build();
        File file2 = File.builder().id(UUID.randomUUID()).user(user(uid)).isDeleted(true).build();
        Folder sub = folder(uid, "sub");

        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(fileRepository.findByFolderId(f.getId())).thenReturn(List.of(file1, file2));
        when(folderRepository.findByParentFolder(f)).thenReturn(List.of(sub));
        when(fileRepository.findByFolderId(sub.getId())).thenReturn(List.of());
        when(folderRepository.findByParentFolder(sub)).thenReturn(List.of());
        when(folderRepository.save(any(Folder.class))).thenAnswer(inv -> inv.getArgument(0));
        when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

        service.deleteFolder(f.getId(), uid);

        assertThat(f.getIsDeleted()).isTrue();
        assertThat(sub.getIsDeleted()).isTrue();
        assertThat(file1.getIsDeleted()).isTrue();

        verify(fileRepository, times(1)).save(file1);
    }

    @Test
    void renameFolder_success() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(uid, "old");
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(userRepository.findById(uid)).thenReturn(Optional.of(user(uid)));
        when(folderRepository.existsByUserAndNameAndParentFolder(any(), eq("new"), eq(null)))
                .thenReturn(false);
        when(folderRepository.save(any(Folder.class))).thenAnswer(inv -> inv.getArgument(0));

        FolderUpdateDto req = new FolderUpdateDto();
        req.setName("new");

        Folder result = service.renameFolder(f.getId(), req, uid);

        assertThat(result.getName()).isEqualTo("new");
    }

    @Test
    void renameFolder_nameConflict_throws() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(uid, "old");
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(userRepository.findById(uid)).thenReturn(Optional.of(user(uid)));
        when(folderRepository.existsByUserAndNameAndParentFolder(any(), eq("taken"), eq(null)))
                .thenReturn(true);

        FolderUpdateDto req = new FolderUpdateDto();
        req.setName("taken");

        assertThatThrownBy(() -> service.renameFolder(f.getId(), req, uid))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void renameFolder_ownerOfFolderMissing_throws() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(UUID.randomUUID(), "old");

        FolderAccess fa = FolderAccess.builder()
                .accessLevel(FolderAccess.AccessLevel.WRITE).isActive(true).build();
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(folderAccessRepository.findByFolderIdAndUserId(f.getId(), uid))
                .thenReturn(Optional.of(fa));
        when(userRepository.findById(f.getUser().getId())).thenReturn(Optional.empty());

        FolderUpdateDto req = new FolderUpdateDto();
        req.setName("new");

        assertThatThrownBy(() -> service.renameFolder(f.getId(), req, uid))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Владелец");
    }

    @Test
    void addFileToFolder_fileNotFound_throws() {
        UUID uid = UUID.randomUUID();
        UUID fid = UUID.randomUUID();
        when(fileRepository.findById(fid)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.addFileToFolder(fid, null, uid))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void addFileToFolder_fileOwnedByAnother_throws() {
        UUID uid = UUID.randomUUID();
        UUID fid = UUID.randomUUID();
        File f = File.builder().id(fid).user(user(UUID.randomUUID())).build();
        when(fileRepository.findById(fid)).thenReturn(Optional.of(f));

        assertThatThrownBy(() -> service.addFileToFolder(fid, null, uid))
                .isInstanceOf(SecurityException.class);
    }

    @Test
    void addFileToFolder_nullFolder_detachesFile() {
        UUID uid = UUID.randomUUID();
        File f = File.builder().id(UUID.randomUUID()).user(user(uid)).build();
        when(fileRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

        File result = service.addFileToFolder(f.getId(), null, uid);

        assertThat(result.getFolder()).isNull();
    }

    @Test
    void addFileToFolder_success() {
        UUID uid = UUID.randomUUID();
        File f = File.builder().id(UUID.randomUUID()).user(user(uid)).build();
        Folder folder = folder(uid, "target");

        when(fileRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(folderRepository.findById(folder.getId())).thenReturn(Optional.of(folder));
        when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

        File result = service.addFileToFolder(f.getId(), folder.getId(), uid);

        assertThat(result.getFolder()).isSameAs(folder);
    }

    @Test
    void addFileToFolder_folderNotFound_throws() {
        UUID uid = UUID.randomUUID();
        UUID folderId = UUID.randomUUID();
        File f = File.builder().id(UUID.randomUUID()).user(user(uid)).build();
        when(fileRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(folderRepository.findById(folderId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.addFileToFolder(f.getId(), folderId, uid))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void moveFiles_move_success() {
        UUID uid = UUID.randomUUID();
        Folder target = folder(uid, "target");
        File f1 = File.builder().id(UUID.randomUUID()).user(user(uid)).build();
        File f2 = File.builder().id(UUID.randomUUID()).user(user(uid)).build();

        when(folderRepository.findById(target.getId())).thenReturn(Optional.of(target));
        when(fileRepository.findById(f1.getId())).thenReturn(Optional.of(f1));
        when(fileRepository.findById(f2.getId())).thenReturn(Optional.of(f2));
        when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

        FolderMoveDto req = new FolderMoveDto();
        req.setTargetFolderId(target.getId());
        req.setFileIds(List.of(f1.getId(), f2.getId()));
        req.setCopy(false);

        List<File> result = service.moveFiles(req, uid);

        assertThat(result).hasSize(2);
        assertThat(f1.getFolder()).isSameAs(target);
        assertThat(f2.getFolder()).isSameAs(target);
    }

    @Test
    void moveFiles_copy_createsNewFile() {
        UUID uid = UUID.randomUUID();
        File original = File.builder()
                .id(UUID.randomUUID()).user(user(uid))
                .name("doc").originalName("doc")
                .fileContent(FileContent.builder().id(UUID.randomUUID()).build())
                .size(100L).mimeType("x").isEncrypted(true).isPublic(false)
                .build();

        when(fileRepository.findById(original.getId())).thenReturn(Optional.of(original));
        when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

        FolderMoveDto req = new FolderMoveDto();
        req.setFileIds(List.of(original.getId()));
        req.setCopy(true);

        List<File> result = service.moveFiles(req, uid);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("doc (копия)");
        assertThat(result.get(0).getFileContent()).isSameAs(original.getFileContent());
    }

    @Test
    void moveFiles_fileNotFound_throws() {
        UUID uid = UUID.randomUUID();
        UUID fid = UUID.randomUUID();
        when(fileRepository.findById(fid)).thenReturn(Optional.empty());

        FolderMoveDto req = new FolderMoveDto();
        req.setFileIds(List.of(fid));

        assertThatThrownBy(() -> service.moveFiles(req, uid))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void moveFiles_fileOwnedByAnother_throws() {
        UUID uid = UUID.randomUUID();
        File f = File.builder().id(UUID.randomUUID()).user(user(UUID.randomUUID())).build();
        when(fileRepository.findById(f.getId())).thenReturn(Optional.of(f));

        FolderMoveDto req = new FolderMoveDto();
        req.setFileIds(List.of(f.getId()));

        assertThatThrownBy(() -> service.moveFiles(req, uid))
                .isInstanceOf(SecurityException.class);
    }

    @Test
    void moveFiles_targetFolderNotFound_throws() {
        UUID uid = UUID.randomUUID();
        UUID targetId = UUID.randomUUID();
        when(folderRepository.findById(targetId)).thenReturn(Optional.empty());

        FolderMoveDto req = new FolderMoveDto();
        req.setTargetFolderId(targetId);
        req.setFileIds(List.of(UUID.randomUUID()));

        assertThatThrownBy(() -> service.moveFiles(req, uid))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void removeFileFromFolder_delegatesToAddNull() {
        UUID uid = UUID.randomUUID();
        File f = File.builder().id(UUID.randomUUID()).user(user(uid)).folder(folder(uid, "x")).build();
        when(fileRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(fileRepository.save(any(File.class))).thenAnswer(inv -> inv.getArgument(0));

        File result = service.removeFileFromFolder(f.getId(), uid);

        assertThat(result.getFolder()).isNull();
    }

    @Test
    void hasActivePassword_noPassword_returnsFalse() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(uid, "f");
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(folderPasswordRepository.findByFolderAndIsActive(f, true)).thenReturn(Optional.empty());

        assertThat(service.hasActivePassword(f.getId(), uid)).isFalse();
    }

    @Test
    void hasActivePassword_present_returnsTrue() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(uid, "f");
        FolderPassword fp = FolderPassword.builder().build();
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(folderPasswordRepository.findByFolderAndIsActive(f, true)).thenReturn(Optional.of(fp));

        assertThat(service.hasActivePassword(f.getId(), uid)).isTrue();
    }

    @Test
    void closeFolderForOthers_owner_removesNonOwnerAccesses() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(uid, "root");
        User other = user(UUID.randomUUID());
        User third = user(UUID.randomUUID());

        FolderAccess ownAccess = FolderAccess.builder()
                .user(user(uid)).accessLevel(FolderAccess.AccessLevel.OWNER).build();
        FolderAccess readAccess = FolderAccess.builder()
                .user(other).accessLevel(FolderAccess.AccessLevel.READ).build();
        FolderAccess secondOwner = FolderAccess.builder()
                .user(third).accessLevel(FolderAccess.AccessLevel.OWNER).build();

        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(folderAccessRepository.findByFolder(f))
                .thenReturn(List.of(ownAccess, readAccess, secondOwner));

        service.closeFolderForOthers(f.getId(), uid);

        verify(folderAccessRepository).delete(readAccess);
        verify(folderAccessRepository, never()).delete(ownAccess);
        verify(folderAccessRepository, never()).delete(secondOwner);
    }

    @Test
    void closeFolderForOthers_notOwner_throws() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(UUID.randomUUID(), "root");
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(folderAccessRepository.findByFolderIdAndUserId(f.getId(), uid))
                .thenReturn(Optional.of(FolderAccess.builder()
                        .accessLevel(FolderAccess.AccessLevel.ADMIN).isActive(true).build()));

        assertThatThrownBy(() -> service.closeFolderForOthers(f.getId(), uid))
                .isInstanceOf(SecurityException.class);
    }

    @Test
    void shareFolder_emptyUserIds_returnsEmpty() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(uid, "f");
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));

        FolderShareDto req = new FolderShareDto();
        req.setFolderId(f.getId());
        req.setUserIds(List.of());

        assertThat(service.shareFolder(req, uid)).isEmpty();
    }

    @Test
    void shareFolder_nullUserIds_returnsEmpty() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(uid, "f");
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));

        FolderShareDto req = new FolderShareDto();
        req.setFolderId(f.getId());
        req.setUserIds(null);

        assertThat(service.shareFolder(req, uid)).isEmpty();
    }

    @Test
    void shareFolder_newUser_createsAccess() {
        UUID uid = UUID.randomUUID();
        UUID targetUser = UUID.randomUUID();
        Folder f = folder(uid, "f");

        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(userRepository.findById(targetUser)).thenReturn(Optional.of(user(targetUser)));
        when(folderAccessRepository.existsByFolderIdAndUserId(f.getId(), targetUser))
                .thenReturn(false);
        when(folderAccessRepository.save(any(FolderAccess.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        FolderShareDto req = new FolderShareDto();
        req.setFolderId(f.getId());
        req.setUserIds(List.of(targetUser));
        req.setCanEdit(true);
        req.setCanShare(true);

        List<FolderAccess> result = service.shareFolder(req, uid);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getAccessLevel()).isEqualTo(FolderAccess.AccessLevel.READ);
        assertThat(result.get(0).getCanEdit()).isTrue();
        assertThat(result.get(0).getCanShare()).isTrue();
    }

    @Test
    void shareFolder_existingAccess_skips() {
        UUID uid = UUID.randomUUID();
        UUID targetUser = UUID.randomUUID();
        Folder f = folder(uid, "f");

        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(userRepository.findById(targetUser)).thenReturn(Optional.of(user(targetUser)));
        when(folderAccessRepository.existsByFolderIdAndUserId(f.getId(), targetUser))
                .thenReturn(true);

        FolderShareDto req = new FolderShareDto();
        req.setFolderId(f.getId());
        req.setUserIds(List.of(targetUser));

        List<FolderAccess> result = service.shareFolder(req, uid);

        assertThat(result).isEmpty();
        verify(folderAccessRepository, never()).save(any());
    }

    @Test
    void shareFolder_userNotFound_throws() {
        UUID uid = UUID.randomUUID();
        UUID targetUser = UUID.randomUUID();
        Folder f = folder(uid, "f");

        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(userRepository.findById(targetUser)).thenReturn(Optional.empty());

        FolderShareDto req = new FolderShareDto();
        req.setFolderId(f.getId());
        req.setUserIds(List.of(targetUser));

        assertThatThrownBy(() -> service.shareFolder(req, uid))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void shareFolder_noSharePermission_throws() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(UUID.randomUUID(), "f");
        FolderAccess fa = FolderAccess.builder()
                .accessLevel(FolderAccess.AccessLevel.READ)
                .isActive(true).canShare(false).build();
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(folderAccessRepository.findByFolderIdAndUserId(f.getId(), uid))
                .thenReturn(Optional.of(fa));

        FolderShareDto req = new FolderShareDto();
        req.setFolderId(f.getId());
        req.setUserIds(List.of(UUID.randomUUID()));

        assertThatThrownBy(() -> service.shareFolder(req, uid))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("шаринг");
    }

    @Test
    void setFolderPassword_withPassword_createsActivePassword() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(uid, "f");
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(passwordEncoder.encode("pw")).thenReturn("$2a$hash");
        when(folderPasswordRepository.save(any(FolderPassword.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        service.setFolderPassword(f.getId(), "pw", uid);

        verify(folderPasswordRepository).deactivateByFolder(f);
        verify(folderPasswordRepository).save(any(FolderPassword.class));
    }

    @Test
    void setFolderPassword_null_deactivatesOnly() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(uid, "f");
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));

        service.setFolderPassword(f.getId(), null, uid);

        verify(folderPasswordRepository).deactivateByFolder(f);
        verify(folderPasswordRepository, never()).save(any());
    }

    @Test
    void setFolderPassword_emptyString_deactivatesOnly() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(uid, "f");
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));

        service.setFolderPassword(f.getId(), "", uid);

        verify(folderPasswordRepository).deactivateByFolder(f);
        verify(folderPasswordRepository, never()).save(any());
    }

    @Test
    void getFolderTree_noUser_throws() {
        UUID uid = UUID.randomUUID();
        when(userRepository.findById(uid)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getFolderTree(uid))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void getFolderTree_filtersDeletedAndHidden() {
        UUID uid = UUID.randomUUID();
        User u = user(uid);

        Folder visible = folder(uid, "visible");
        Folder hidden = folder(uid, "hidden");
        hidden.setIsHidden(true);
        Folder deleted = folder(uid, "deleted");
        deleted.setIsDeleted(true);

        when(userRepository.findById(uid)).thenReturn(Optional.of(u));
        when(folderRepository.findByUserAndParentFolderIsNull(u))
                .thenReturn(List.of(visible, hidden, deleted));
        when(folderRepository.findByParentFolder(visible)).thenReturn(List.of());

        List<Folder> result = service.getFolderTree(uid);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getName()).isEqualTo("visible");
    }

    @Test
    void getFolderTree_nestedSubfolders_enriched() {
        UUID uid = UUID.randomUUID();
        User u = user(uid);
        Folder root = folder(uid, "root");
        Folder child = folder(uid, "child");
        child.setParentFolder(root);

        when(userRepository.findById(uid)).thenReturn(Optional.of(u));
        when(folderRepository.findByUserAndParentFolderIsNull(u)).thenReturn(List.of(root));
        when(folderRepository.findByParentFolder(root)).thenReturn(List.of(child));
        when(folderRepository.findByParentFolder(child)).thenReturn(List.of());

        List<Folder> result = service.getFolderTree(uid);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getSubfolders()).hasSize(1);
        assertThat(result.get(0).getSubfolders().get(0).getName()).isEqualTo("child");
    }

    @Test
    void checkHiddenFolderKey_nullHash_returnsFalse() {
        UUID fid = UUID.randomUUID();
        Folder f = Folder.builder().id(fid).hiddenFolderKeyHash(null).build();
        when(folderRepository.findById(fid)).thenReturn(Optional.of(f));
        assertThat(service.checkHiddenFolderKey(fid, "any")).isFalse();
    }

    @Test
    void checkHiddenFolderKey_correct_returnsTrue() {
        UUID fid = UUID.randomUUID();
        Folder f = Folder.builder().id(fid).hiddenFolderKeyHash("hash").build();
        when(folderRepository.findById(fid)).thenReturn(Optional.of(f));
        when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(false);
        when(passwordEncoder.matches("key", "hash")).thenReturn(true);
        assertThat(service.checkHiddenFolderKey(fid, "key")).isTrue();
        verify(loginAttemptService).folderPasswordSucceeded(anyString());
    }

    @Test
    void checkHiddenFolderKey_wrong_returnsFalse_andRecordsFailure() {
        UUID fid = UUID.randomUUID();
        Folder f = Folder.builder().id(fid).hiddenFolderKeyHash("hash").build();
        when(folderRepository.findById(fid)).thenReturn(Optional.of(f));
        when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(false);
        when(passwordEncoder.matches("wrong", "hash")).thenReturn(false);
        assertThat(service.checkHiddenFolderKey(fid, "wrong")).isFalse();
        verify(loginAttemptService).folderPasswordFailed(anyString());
    }

    @Test
    void checkHiddenFolderKey_blocked_throws() {
        UUID fid = UUID.randomUUID();
        Folder f = Folder.builder().id(fid).hiddenFolderKeyHash("hash").build();
        when(folderRepository.findById(fid)).thenReturn(Optional.of(f));
        when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(true);
        assertThatThrownBy(() -> service.checkHiddenFolderKey(fid, "key"))
                .isInstanceOf(SecurityException.class);
    }

    @Test
    void checkFolderPassword_folderNotFound_throws() {
        UUID fid = UUID.randomUUID();
        when(folderRepository.findById(fid)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.checkFolderPassword(fid, "x"))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void checkFolderPassword_blocked_returnsBlocked() {
        UUID fid = UUID.randomUUID();
        Folder f = Folder.builder().id(fid).build();
        when(folderRepository.findById(fid)).thenReturn(Optional.of(f));
        when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(true);
        assertThat(service.checkFolderPassword(fid, "x")).isEqualTo(PasswordCheckResult.BLOCKED);
    }

    @Test
    void checkFolderPassword_noPassword_returnsOk() {
        UUID fid = UUID.randomUUID();
        Folder f = Folder.builder().id(fid).build();
        when(folderRepository.findById(fid)).thenReturn(Optional.of(f));
        when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(false);
        when(folderPasswordRepository.findByFolderAndIsActive(f, true)).thenReturn(Optional.empty());
        assertThat(service.checkFolderPassword(fid, "x")).isEqualTo(PasswordCheckResult.OK);
    }

    @Test
    void checkFolderPassword_bcryptCorrect_returnsOk() {
        UUID fid = UUID.randomUUID();
        Folder f = Folder.builder().id(fid).build();
        FolderPassword fp = FolderPassword.builder()
                .passwordHash("$2a$hash").algorithm("BCRYPT").build();
        when(folderRepository.findById(fid)).thenReturn(Optional.of(f));
        when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(false);
        when(folderPasswordRepository.findByFolderAndIsActive(f, true)).thenReturn(Optional.of(fp));
        when(passwordEncoder.matches("pw", "$2a$hash")).thenReturn(true);
        assertThat(service.checkFolderPassword(fid, "pw")).isEqualTo(PasswordCheckResult.OK);
        verify(loginAttemptService).folderPasswordSucceeded(anyString());
    }

    @Test
    void checkFolderPassword_bcryptWrong_returnsInvalid() {
        UUID fid = UUID.randomUUID();
        Folder f = Folder.builder().id(fid).build();
        FolderPassword fp = FolderPassword.builder()
                .passwordHash("$2a$hash").algorithm("BCRYPT").build();
        when(folderRepository.findById(fid)).thenReturn(Optional.of(f));
        when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(false);
        when(folderPasswordRepository.findByFolderAndIsActive(f, true)).thenReturn(Optional.of(fp));
        when(passwordEncoder.matches("pw", "$2a$hash")).thenReturn(false);
        assertThat(service.checkFolderPassword(fid, "pw")).isEqualTo(PasswordCheckResult.INVALID);
        verify(loginAttemptService).folderPasswordFailed(anyString());
    }

    @Test
    void checkFolderPassword_legacySha256_matches() {
        UUID fid = UUID.randomUUID();
        Folder f = Folder.builder().id(fid).build();
        FolderPassword fp = FolderPassword.builder()
                .passwordHash(sha256Hex("pw"))
                .algorithm("LEGACY-SHA256")
                .build();
        when(folderRepository.findById(fid)).thenReturn(Optional.of(f));
        when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(false);
        when(folderPasswordRepository.findByFolderAndIsActive(f, true)).thenReturn(Optional.of(fp));
        assertThat(service.checkFolderPassword(fid, "pw")).isEqualTo(PasswordCheckResult.OK);
    }

    @Test
    void checkFolderPassword_legacySha256_wrong() {
        UUID fid = UUID.randomUUID();
        Folder f = Folder.builder().id(fid).build();
        FolderPassword fp = FolderPassword.builder()
                .passwordHash(sha256Hex("real"))
                .algorithm("LEGACY-SHA256")
                .build();
        when(folderRepository.findById(fid)).thenReturn(Optional.of(f));
        when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(false);
        when(folderPasswordRepository.findByFolderAndIsActive(f, true)).thenReturn(Optional.of(fp));
        assertThat(service.checkFolderPassword(fid, "wrong")).isEqualTo(PasswordCheckResult.INVALID);
    }

    @Test
    void checkFolderPassword_nullPassword_returnsInvalid() {
        UUID fid = UUID.randomUUID();
        Folder f = Folder.builder().id(fid).build();
        FolderPassword fp = FolderPassword.builder()
                .passwordHash("$2a$hash").algorithm("BCRYPT").build();
        when(folderRepository.findById(fid)).thenReturn(Optional.of(f));
        when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(false);
        when(folderPasswordRepository.findByFolderAndIsActive(f, true)).thenReturn(Optional.of(fp));
        assertThat(service.checkFolderPassword(fid, null)).isEqualTo(PasswordCheckResult.INVALID);
    }

    @Test
    void checkFolderPassword_unknownAlgorithm_throws() {
        UUID fid = UUID.randomUUID();
        Folder f = Folder.builder().id(fid).build();
        FolderPassword fp = FolderPassword.builder()
                .passwordHash("some-hash").algorithm("UNKNOWN-ALGO").build();
        when(folderRepository.findById(fid)).thenReturn(Optional.of(f));
        when(loginAttemptService.isFolderPasswordBlocked(anyString())).thenReturn(false);
        when(folderPasswordRepository.findByFolderAndIsActive(f, true)).thenReturn(Optional.of(fp));

        assertThatThrownBy(() -> service.checkFolderPassword(fid, "pw"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Unknown password algorithm");
    }

    @Test
    void getFolderFilesPaged_noAccess_throws() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(UUID.randomUUID(), "f");
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(folderAccessRepository.findByFolderIdAndUserId(f.getId(), uid))
                .thenReturn(Optional.empty());

        Pageable pageable = PageRequest.of(0, 10);

        assertThatThrownBy(() -> service.getFolderFilesPaged(f.getId(), uid, pageable))
                .isInstanceOf(SecurityException.class);
    }

    @Test
    void getFolderFilesPaged_owner_returnsPage() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(uid, "f");
        Pageable pageable = PageRequest.of(0, 10);
        Page<File> expected = new PageImpl<>(List.of());

        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(fileRepository.findByFolderIdAndIsDeletedFalse(f.getId(), pageable))
                .thenReturn(expected);

        Page<File> result = service.getFolderFilesPaged(f.getId(), uid, pageable);

        assertThat(result).isSameAs(expected);
    }

    @Test
    void checkCanShare_revokedAccess_throws() {
        UUID uid = UUID.randomUUID();
        Folder f = folder(UUID.randomUUID(), "f");
        FolderAccess fa = FolderAccess.builder()
                .accessLevel(FolderAccess.AccessLevel.READ)
                .isActive(false).canShare(true).build();
        when(folderRepository.findById(f.getId())).thenReturn(Optional.of(f));
        when(folderAccessRepository.findByFolderIdAndUserId(f.getId(), uid))
                .thenReturn(Optional.of(fa));

        FolderShareDto req = new FolderShareDto();
        req.setFolderId(f.getId());
        req.setUserIds(List.of(UUID.randomUUID()));

        assertThatThrownBy(() -> service.shareFolder(req, uid))
                .isInstanceOf(SecurityException.class)
                .hasMessageContaining("отозван");
    }

    @Test
    void createFolder_hiddenWithoutKey_stillWorks() {
        UUID uid = UUID.randomUUID();
        User u = user(uid);
        when(userRepository.findById(uid)).thenReturn(Optional.of(u));
        when(folderRepository.existsByUserAndNameAndParentFolder(u, "h", null)).thenReturn(false);
        when(folderRepository.save(any(Folder.class))).thenAnswer(inv -> inv.getArgument(0));
        when(folderAccessRepository.save(any(FolderAccess.class))).thenAnswer(inv -> inv.getArgument(0));

        FolderCreateDto req = new FolderCreateDto();
        req.setName("h");
        req.setIsHidden(true);

        Folder result = service.createFolder(req, uid);
        assertThat(result.getIsHidden()).isTrue();
    }

    @Test
    void softDeleteFolder_recursiveWithSubfoldersAndFiles() {
        UUID uid = UUID.randomUUID();
        Folder root = folder(uid, "root");
        Folder sub = folder(uid, "sub");
        File f1 = File.builder().id(UUID.randomUUID()).user(user(uid)).isDeleted(false).build();
        File f2 = File.builder().id(UUID.randomUUID()).user(user(uid)).isDeleted(false).build();

        when(folderRepository.findById(root.getId())).thenReturn(Optional.of(root));
        when(fileRepository.findByFolderId(root.getId())).thenReturn(List.of(f1));
        when(folderRepository.findByParentFolder(root)).thenReturn(List.of(sub));
        when(fileRepository.findByFolderId(sub.getId())).thenReturn(List.of(f2));
        when(folderRepository.findByParentFolder(sub)).thenReturn(List.of());
        when(folderRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(fileRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.deleteFolder(root.getId(), uid);

        assertThat(f1.getIsDeleted()).isTrue();
        assertThat(f2.getIsDeleted()).isTrue();
        assertThat(sub.getIsDeleted()).isTrue();
    }
}
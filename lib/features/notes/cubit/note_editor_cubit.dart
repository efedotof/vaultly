import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vaulth_app/features/auth/cubit/auth_cubit.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/repository/file/file_interface.dart';
import 'package:vaulth_app/server/service/shirm_encryption_service.dart';
import 'package:vaulth_app/server/service/shirm_encryption_service_web.dart';
import 'package:vaulth_app/server/service/shirm_decryption_service.dart';
import 'package:vaulth_app/server/service/shirm_decryption_service_web.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

part 'note_editor_state.dart';
part 'note_editor_cubit.freezed.dart';

class NoteEditorCubit extends Cubit<NoteEditorState> {
  final FileInterface fileRepository;
  final AuthLocalStorage authStorage;
  final AuthCubit authCubit;
  final dynamic keyManager;

  NoteEditorCubit({
    required this.fileRepository,
    required this.authStorage,
    required this.authCubit,
    required this.keyManager,
  }) : super(const NoteEditorState.initial());

  void initialize(FileDto? note) {
    if (note != null) {
      loadNote(note);
    } else {
      emit(
        NoteEditorState.loaded(
          note: null,
          content: '# Новая заметка\n\nНачните писать...',
          noteName: 'Новая заметка',
        ),
      );
    }
  }

  Future<void> loadNote(FileDto note) async {
    emit(const NoteEditorState.loading());
    try {
      final password = authCubit.currentPassword ?? '';
      final encryptedBytes = await fileRepository.downloadShps(note.id!);

      dynamic privateKey;
      if (kIsWeb) {
        privateKey = await keyManager.getPrivateKeyPEM(password);
      } else {
        privateKey = await keyManager.getPrivateKey(password);
        if (privateKey != null) {
          privateKey = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);
        }
      }

      if (privateKey == null) {
        throw Exception('Не удалось получить приватный ключ');
      }

      Uint8List decrypted;
      if (kIsWeb) {
        decrypted = await ShirmDecryptionServiceWeb.decryptShps(
          encryptedBytes,
          privateKeyPem: privateKey,
        );
      } else {
        decrypted = ShirmDecryptionService.decryptShps(
          encryptedBytes,
          privateKey: CryptoUtils.rsaPrivateKeyFromPem(privateKey),
        );
      }

      final content = utf8.decode(decrypted);
      emit(
        NoteEditorState.loaded(
          note: note,
          content: content,
          noteName: note.name.replaceAll('.md', ''),
        ),
      );
    } catch (e) {
      emit(NoteEditorState.error(e.toString()));
    }
  }

  void updateNoteName(String name) {
    state.maybeWhen(
      loaded: (note, content, _) => emit(
        NoteEditorState.loaded(note: note, content: content, noteName: name),
      ),
      orElse: () {},
    );
  }

  void updateContent(String content) {
    state.maybeWhen(
      loaded: (note, _, noteName) => emit(
        NoteEditorState.loaded(
          note: note,
          content: content,
          noteName: noteName,
        ),
      ),
      orElse: () {},
    );
  }

  Future<void> saveNote({
    required FileDto? existingNote,
    required String content,
    required String noteName,
  }) async {
    emit(const NoteEditorState.saving());
    try {
      final bytes = utf8.encode(content);
      final fileName = '$noteName.md';

      final userId = await authStorage.getUserId();
      if (userId == null) throw Exception('Пользователь не авторизован');

      final password = authCubit.currentPassword ?? '';

      Uint8List encryptedData;

      if (kIsWeb) {
        final publicKeyPem = await keyManager.getUserPublicKey() ?? '';
        final privateKeyPem = await keyManager.getPrivateKeyPEM(password) ?? '';
        encryptedData = await ShirmEncryptionServiceWeb.encryptBytes(
          Uint8List.fromList(bytes),
          publicKeyPem: publicKeyPem,
          userId: userId,
          keyOwner: 'user',
          privateKeyPem: privateKeyPem,
          originalFileName: fileName,
        );
      } else {
        final publicKeyObj = await keyManager.getUserPublicKeyObject();
        final privateKeyObj = await keyManager.getPrivateKey(password);
        if (publicKeyObj == null || privateKeyObj == null) {
          throw Exception('Не удалось получить ключи шифрования');
        }

        final tempDir = await getTemporaryDirectory();
        final tempPlainFile = File(
          '${tempDir.path}/temp_note_${DateTime.now().millisecondsSinceEpoch}.md',
        );
        await tempPlainFile.writeAsBytes(bytes);

        try {
          encryptedData = await ShirmEncryptionService.encryptFile(
            tempPlainFile,
            publicKey: publicKeyObj as RSAPublicKey,
            userId: userId,
            keyOwner: 'user',
            privateKey: privateKeyObj as RSAPrivateKey,
          );
        } finally {
          await tempPlainFile.delete();
        }
      }

      if (existingNote == null) {
        await fileRepository.createNote(
          encryptedData: encryptedData,
          fileName: fileName,
          userId: userId,
          keyOwner: 'user',
        );
      } else {
        await fileRepository.updateNoteContent(
          noteId: existingNote.id!,
          encryptedData: encryptedData,
          fileName: fileName,
        );
      }

      emit(const NoteEditorState.saved());
    } catch (e) {
      emit(NoteEditorState.error(e.toString()));
    }
  }
}

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vaulth_app/server/model/user/update_user_request/update_user_request.dart';
import 'package:vaulth_app/server/model/user/user_profile_dto/user_profile_dto.dart';
import 'package:vaulth_app/server/repository/user/user_interface.dart';

part 'profile_state.dart';
part 'profile_cubit.freezed.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserInterface userRepository;

  ProfileCubit({required this.userRepository})
    : super(const ProfileState.initial());

  Future<void> loadCurrentUser() async {
    emit(const ProfileState.loading());
    try {
      final profile = await userRepository.getCurrentUserProfile();

      emit(ProfileState.loaded(profile));
    } catch (e) {
      debugPrint(e.toString());
      emit(ProfileState.error(e.toString()));
    }
  }

  Future<void> updateCurrentUser(UpdateUserRequest request) async {
    emit(const ProfileState.updating());
    try {
      final updatedProfile = await userRepository.updateCurrentUser(request);
      emit(ProfileState.updateSuccess(updatedProfile));
    } catch (e) {
      debugPrint(e.toString());
      emit(ProfileState.updateError(e.toString()));
    }
  }

  Future<void> loadUserById(String id) async {
    emit(const ProfileState.loading());
    try {
      final profile = await userRepository.getUserProfileById(id);
      emit(ProfileState.loaded(profile));
    } catch (e) {
      debugPrint(e.toString());
      emit(ProfileState.error(e.toString()));
    }
  }

  void reset() {
    emit(const ProfileState.initial());
  }
}

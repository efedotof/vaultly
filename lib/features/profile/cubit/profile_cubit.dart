import 'package:bloc/bloc.dart';
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
      if (_is403Error(e)) {
        emit(ProfileState.unauthorized());
        return;
      }
      emit(ProfileState.error(e.toString()));
    }
  }

  Future<void> updateCurrentUser(UpdateUserRequest request) async {
    emit(const ProfileState.updating());
    try {
      final updatedProfile = await userRepository.updateCurrentUser(request);
      emit(ProfileState.updateSuccess(updatedProfile));
    } catch (e) {
      if (_is403Error(e)) {
        emit(ProfileState.unauthorized());
        return;
      }
      emit(ProfileState.updateError(e.toString()));
    }
  }

  Future<void> loadUserById(String id) async {
    emit(const ProfileState.loading());
    try {
      final profile = await userRepository.getUserProfileById(id);
      emit(ProfileState.loaded(profile));
    } catch (e) {
      if (_is403Error(e)) {
        emit(ProfileState.unauthorized());
        return;
      }
      emit(ProfileState.error(e.toString()));
    }
  }

  bool _is403Error(Object e) {
    final errorString = e.toString();
    return errorString.contains('403') ||
        errorString.contains('status code of 403') ||
        (e is Exception && errorString.contains('Network error'));
  }

  void reset() {
    emit(const ProfileState.initial());
  }
}

import 'package:get/get.dart';

//варианты состояния ProfileScreen
enum ProfileStates { myProfile, otherProfile, createProfile, updateProfile }

class ProfileController extends GetxController {
  final state = ProfileStates.createProfile.obs;

  //смена состоятий
  void updateStates({required ProfileStates newState}) {
    state.value = newState;
  }
}

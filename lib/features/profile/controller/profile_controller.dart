import 'package:get/get.dart';

//варианты состояния ProfileScreen
enum ProfileStates { myProfile, otherProfile, createProfile, updateProfile }

class ProfileController extends GetxController {
  final state = ProfileStates.createProfile.obs;

  final userId = "my_profile".obs;

  @override
  void onInit() {
    final parm = Get.parameters['user'];

    if (parm != null) {
      userId.value = parm;
      _updateStates(parm);
    } else {
      state.value = ProfileStates.myProfile;
    }
    super.onInit();
  }

  //смена состоятий
  void _updateStates(String userId) {
    switch (userId) {
      case "my_profile":
        state.value = ProfileStates.myProfile;
        break;
      case "create_profile":
        state.value = ProfileStates.createProfile;
        break;
      case "update_my_profile":
        state.value = ProfileStates.updateProfile;
        break;
      default:
        state.value = ProfileStates.updateProfile;
        break;
    }

    if (userId == "my_profile") {
      state.value = ProfileStates.otherProfile;
    }
  }
}

import 'package:get/get.dart';

enum FilesUploadStates { loading, encription, decription, uploaded, noSelected }

class AddFilesController extends GetxController {
  final state = FilesUploadStates.noSelected.obs;

  //выбор файла
  void selectFiles() {}

  //шифрование
  void encyptionFiles({required List<String> files}) {}

  //расшифровка ключами + кэширование файла,чтобы сразу показывать превью
  void decryptionAndSaveCached() {}
}

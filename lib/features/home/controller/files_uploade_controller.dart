import 'package:get/get.dart';

//состояния загрузки файла
enum FilesUploadStates { loading, encription, decription, uploaded, noSelected }

class FilesUploadeController extends GetxController {
  final state = FilesUploadStates.noSelected.obs;

  //выбор файла
  void selectFiles() {}

  //шифрование
  void encyptionFiles({required List<String> files}) {}

  //расшифровка ключами + кэширование файла,чтобы сразу показывать превью
  void decryptionAndSaveCached() {}
}

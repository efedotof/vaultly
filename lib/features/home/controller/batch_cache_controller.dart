import 'package:get/get.dart';

enum BatchCacheStates { loading, decription, loadingUserKeys, done, noFiles }

class BatchCacheController extends GetxController {
  final state = BatchCacheStates.noFiles.obs;

  //загрузка ключей пользователя
  void _loadUserKeys() {
    _updateState(BatchCacheStates.loadingUserKeys);
  }

  //дешифровка файлов пользователя
  void _decryptFiles() {}


  //автоматически расшифровывать
  void _autoBatch(){}

  //обновляем стайт
  void _updateState(BatchCacheStates newState) => state.value = newState;
}

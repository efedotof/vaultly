import 'package:get/get.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

class EncryptService extends GetxService {
  bool _isInit = false;

  Future<EncryptService> init() async {
    try {
      _isInit = true;
      Logger.d("Успешная инициализация", tag: 'EncryptService');
      return this;
    } catch (e) {
      Logger.d("Ошибка инициализации: $e", tag: 'EncryptService');
      return throw Exception("[EncryptService] ошибка инициализации сервиса");
    }
  }

  bool get isInitial => _isInit;
}

import 'package:get/get.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

class DecryptService extends GetxService {
  bool _isInit = false;

  Future<DecryptService> init() async {
    try {
      _isInit = true;
      Logger.d("Успешная инициализация", tag: 'DecryptService');
      return this;
    } catch (e) {
      Logger.d("Ошибка инициализации: $e", tag: 'DecryptService');
      return throw Exception("[DecryptService] ошибка инициализации сервиса");
    }
  }

  bool get isInitial => _isInit;
}

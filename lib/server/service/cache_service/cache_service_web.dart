import 'package:get/get.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

class CacheService extends GetxService {
  bool _isInit = false;

  Future<CacheService> init() async {
    try {
      _isInit = true;
      Logger.d("Успешная инициализация", tag: 'CacheService');
      return this;
    } catch (e) {
      Logger.d("Ошибка инициализации: $e", tag: 'CacheService');
      return throw Exception("[CacheService] ошибка инициализации сервиса");
    }
  }

  bool get isInitial => _isInit;
}

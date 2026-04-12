import 'package:pointycastle/asymmetric/api.dart';

abstract class ServerKeyInterface {
  Future<RSAPublicKey> getServerPublicKey();
  Future<String> getServerPublicKeyPem();
}

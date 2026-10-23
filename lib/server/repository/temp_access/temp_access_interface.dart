import 'package:vaulth_app/server/model/file/decryption_metadata.dart';
import 'package:vaulth_app/server/model/tempaccess/create_temp_link_request.dart';
import 'package:vaulth_app/server/model/tempaccess/temp_link_response.dart';

abstract interface class TempAccessInterface {
  Future<void> setFilePublic({required String fileId, required bool isPublic});

  Future<TempLinkResponse> createTempLink({
    required CreateTempLinkRequest request,
  });

  Future<void> checkTempLinkPassword({required String token, String? password});

  Future<DecryptionMetadata> getDecryptionMetadata({
    required String token,
    String? password,
  });

  Uri downloadUrl({required String token, String? password});
}

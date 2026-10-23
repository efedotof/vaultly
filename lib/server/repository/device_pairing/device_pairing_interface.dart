import 'package:vaulth_app/server/model/pair/pair_blob_response.dart';
import 'package:vaulth_app/server/model/pair/pair_blob_upload_request.dart';
import 'package:vaulth_app/server/model/pair/pair_info_response.dart';
import 'package:vaulth_app/server/model/pair/pair_init_request.dart';
import 'package:vaulth_app/server/model/pair/pair_init_response.dart';

abstract interface class DevicePairingInterface {
  Future<PairInitResponse> init({required PairInitRequest request});

  Future<PairInfoResponse> getInfo({required String pairingId});

  Future<void> uploadBlob({
    required String pairingId,
    required PairBlobUploadRequest request,
  });

  Future<PairBlobResponse> fetchBlob({required String pairingId});
}

import 'package:vaulth_app/server/model/tempaccess/create_temp_link_request/create_temp_link_request.dart';
import 'package:vaulth_app/server/model/tempaccess/temp_link_response/temp_link_response.dart';

abstract class TempAccessInterface {
  Future<TempLinkResponse> createTempLink(CreateTempLinkRequest request);
}

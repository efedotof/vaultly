import '../user/user_profile_dto.dart';
import 'auth_dto.dart';

class AuthInfo {
  static final AuthInfo _instance = AuthInfo._internal();

  factory AuthInfo() => AuthInfo._instance;

  AuthInfo._internal();

  AuthResponse? authResponse;
  UserProfileDto? user;

  String get id => user?.id ?? "";
  String get email => user?.email ?? "";
  String get username => user?.username ?? "";
  String get name => "${user?.firstName ?? ""} ${user?.lastName ?? ""}";
  String? get avatarUrl => user?.avatarUrl;
  int get storageUsed => user?.storageUsed ?? 0;
  int get storageLimit => user?.storageLimit ?? 0;
  String get publicKey => user?.publicKey ?? "";

  bool get isAuth => authResponse?.accessToken != null ? true : false;

  

}

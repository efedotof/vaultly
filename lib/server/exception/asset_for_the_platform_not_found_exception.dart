class AssetForThePlatformNotFoundException implements Exception {
  final String message;

  AssetForThePlatformNotFoundException([String? message])
    : message = message ?? "Ассет для платформы не найден";
}

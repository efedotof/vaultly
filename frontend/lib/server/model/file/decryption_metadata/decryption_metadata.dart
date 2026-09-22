import 'package:freezed_annotation/freezed_annotation.dart';

part 'decryption_metadata.freezed.dart';
part 'decryption_metadata.g.dart';

@freezed
abstract class DecryptionMetadata with _$DecryptionMetadata {
  const factory DecryptionMetadata({
    required String presignedUrl,
    required String encryptedKey,
    required String iv,
    required int originalSize,
    required String mimeType,
    required String fileName,
  }) = _DecryptionMetadata;

  factory DecryptionMetadata.fromJson(Map<String, dynamic> json) =>
      _$DecryptionMetadataFromJson(json);
}

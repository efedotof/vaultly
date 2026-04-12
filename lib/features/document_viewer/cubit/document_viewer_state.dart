part of 'document_viewer_cubit.dart';

enum ContentType { text, image, binary, pdf, video, office }

@freezed
abstract class DocumentViewerState with _$DocumentViewerState {
  const factory DocumentViewerState.initial() = _Initial;
  const factory DocumentViewerState.loading() = _Loading;
  const factory DocumentViewerState.decrypting() = _Decrypting;
  const factory DocumentViewerState.downloading() = _Downloading;
  const factory DocumentViewerState.loaded({
    required Uint8List data,
    required String fileName,
    required ContentType contentType,
  }) = _Loaded;
  const factory DocumentViewerState.error(String message) = _Error;
}

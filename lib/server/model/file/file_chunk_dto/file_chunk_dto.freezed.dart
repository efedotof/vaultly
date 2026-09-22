// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_chunk_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileChunkDto {

 String get fileName; String get contentType;@Uint8ListConverter() Uint8List? get data; bool get lastChunk; String? get folderId;
/// Create a copy of FileChunkDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileChunkDtoCopyWith<FileChunkDto> get copyWith => _$FileChunkDtoCopyWithImpl<FileChunkDto>(this as FileChunkDto, _$identity);

  /// Serializes this FileChunkDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileChunkDto&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.lastChunk, lastChunk) || other.lastChunk == lastChunk)&&(identical(other.folderId, folderId) || other.folderId == folderId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileName,contentType,const DeepCollectionEquality().hash(data),lastChunk,folderId);

@override
String toString() {
  return 'FileChunkDto(fileName: $fileName, contentType: $contentType, data: $data, lastChunk: $lastChunk, folderId: $folderId)';
}


}

/// @nodoc
abstract mixin class $FileChunkDtoCopyWith<$Res>  {
  factory $FileChunkDtoCopyWith(FileChunkDto value, $Res Function(FileChunkDto) _then) = _$FileChunkDtoCopyWithImpl;
@useResult
$Res call({
 String fileName, String contentType,@Uint8ListConverter() Uint8List? data, bool lastChunk, String? folderId
});




}
/// @nodoc
class _$FileChunkDtoCopyWithImpl<$Res>
    implements $FileChunkDtoCopyWith<$Res> {
  _$FileChunkDtoCopyWithImpl(this._self, this._then);

  final FileChunkDto _self;
  final $Res Function(FileChunkDto) _then;

/// Create a copy of FileChunkDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileName = null,Object? contentType = null,Object? data = freezed,Object? lastChunk = null,Object? folderId = freezed,}) {
  return _then(_self.copyWith(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Uint8List?,lastChunk: null == lastChunk ? _self.lastChunk : lastChunk // ignore: cast_nullable_to_non_nullable
as bool,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FileChunkDto].
extension FileChunkDtoPatterns on FileChunkDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileChunkDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileChunkDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileChunkDto value)  $default,){
final _that = this;
switch (_that) {
case _FileChunkDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileChunkDto value)?  $default,){
final _that = this;
switch (_that) {
case _FileChunkDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileName,  String contentType, @Uint8ListConverter()  Uint8List? data,  bool lastChunk,  String? folderId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileChunkDto() when $default != null:
return $default(_that.fileName,_that.contentType,_that.data,_that.lastChunk,_that.folderId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileName,  String contentType, @Uint8ListConverter()  Uint8List? data,  bool lastChunk,  String? folderId)  $default,) {final _that = this;
switch (_that) {
case _FileChunkDto():
return $default(_that.fileName,_that.contentType,_that.data,_that.lastChunk,_that.folderId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileName,  String contentType, @Uint8ListConverter()  Uint8List? data,  bool lastChunk,  String? folderId)?  $default,) {final _that = this;
switch (_that) {
case _FileChunkDto() when $default != null:
return $default(_that.fileName,_that.contentType,_that.data,_that.lastChunk,_that.folderId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileChunkDto implements FileChunkDto {
  const _FileChunkDto({required this.fileName, required this.contentType, @Uint8ListConverter() this.data, required this.lastChunk, this.folderId});
  factory _FileChunkDto.fromJson(Map<String, dynamic> json) => _$FileChunkDtoFromJson(json);

@override final  String fileName;
@override final  String contentType;
@override@Uint8ListConverter() final  Uint8List? data;
@override final  bool lastChunk;
@override final  String? folderId;

/// Create a copy of FileChunkDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileChunkDtoCopyWith<_FileChunkDto> get copyWith => __$FileChunkDtoCopyWithImpl<_FileChunkDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileChunkDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileChunkDto&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.lastChunk, lastChunk) || other.lastChunk == lastChunk)&&(identical(other.folderId, folderId) || other.folderId == folderId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileName,contentType,const DeepCollectionEquality().hash(data),lastChunk,folderId);

@override
String toString() {
  return 'FileChunkDto(fileName: $fileName, contentType: $contentType, data: $data, lastChunk: $lastChunk, folderId: $folderId)';
}


}

/// @nodoc
abstract mixin class _$FileChunkDtoCopyWith<$Res> implements $FileChunkDtoCopyWith<$Res> {
  factory _$FileChunkDtoCopyWith(_FileChunkDto value, $Res Function(_FileChunkDto) _then) = __$FileChunkDtoCopyWithImpl;
@override @useResult
$Res call({
 String fileName, String contentType,@Uint8ListConverter() Uint8List? data, bool lastChunk, String? folderId
});




}
/// @nodoc
class __$FileChunkDtoCopyWithImpl<$Res>
    implements _$FileChunkDtoCopyWith<$Res> {
  __$FileChunkDtoCopyWithImpl(this._self, this._then);

  final _FileChunkDto _self;
  final $Res Function(_FileChunkDto) _then;

/// Create a copy of FileChunkDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileName = null,Object? contentType = null,Object? data = freezed,Object? lastChunk = null,Object? folderId = freezed,}) {
  return _then(_FileChunkDto(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Uint8List?,lastChunk: null == lastChunk ? _self.lastChunk : lastChunk // ignore: cast_nullable_to_non_nullable
as bool,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

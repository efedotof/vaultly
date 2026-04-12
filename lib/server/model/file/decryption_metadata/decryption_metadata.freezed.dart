// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'decryption_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DecryptionMetadata {

 String get presignedUrl; String get encryptedKey; String get iv; int get originalSize; String get mimeType; String get fileName;
/// Create a copy of DecryptionMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DecryptionMetadataCopyWith<DecryptionMetadata> get copyWith => _$DecryptionMetadataCopyWithImpl<DecryptionMetadata>(this as DecryptionMetadata, _$identity);

  /// Serializes this DecryptionMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DecryptionMetadata&&(identical(other.presignedUrl, presignedUrl) || other.presignedUrl == presignedUrl)&&(identical(other.encryptedKey, encryptedKey) || other.encryptedKey == encryptedKey)&&(identical(other.iv, iv) || other.iv == iv)&&(identical(other.originalSize, originalSize) || other.originalSize == originalSize)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.fileName, fileName) || other.fileName == fileName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,presignedUrl,encryptedKey,iv,originalSize,mimeType,fileName);

@override
String toString() {
  return 'DecryptionMetadata(presignedUrl: $presignedUrl, encryptedKey: $encryptedKey, iv: $iv, originalSize: $originalSize, mimeType: $mimeType, fileName: $fileName)';
}


}

/// @nodoc
abstract mixin class $DecryptionMetadataCopyWith<$Res>  {
  factory $DecryptionMetadataCopyWith(DecryptionMetadata value, $Res Function(DecryptionMetadata) _then) = _$DecryptionMetadataCopyWithImpl;
@useResult
$Res call({
 String presignedUrl, String encryptedKey, String iv, int originalSize, String mimeType, String fileName
});




}
/// @nodoc
class _$DecryptionMetadataCopyWithImpl<$Res>
    implements $DecryptionMetadataCopyWith<$Res> {
  _$DecryptionMetadataCopyWithImpl(this._self, this._then);

  final DecryptionMetadata _self;
  final $Res Function(DecryptionMetadata) _then;

/// Create a copy of DecryptionMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? presignedUrl = null,Object? encryptedKey = null,Object? iv = null,Object? originalSize = null,Object? mimeType = null,Object? fileName = null,}) {
  return _then(_self.copyWith(
presignedUrl: null == presignedUrl ? _self.presignedUrl : presignedUrl // ignore: cast_nullable_to_non_nullable
as String,encryptedKey: null == encryptedKey ? _self.encryptedKey : encryptedKey // ignore: cast_nullable_to_non_nullable
as String,iv: null == iv ? _self.iv : iv // ignore: cast_nullable_to_non_nullable
as String,originalSize: null == originalSize ? _self.originalSize : originalSize // ignore: cast_nullable_to_non_nullable
as int,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DecryptionMetadata].
extension DecryptionMetadataPatterns on DecryptionMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DecryptionMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DecryptionMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DecryptionMetadata value)  $default,){
final _that = this;
switch (_that) {
case _DecryptionMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DecryptionMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _DecryptionMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String presignedUrl,  String encryptedKey,  String iv,  int originalSize,  String mimeType,  String fileName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DecryptionMetadata() when $default != null:
return $default(_that.presignedUrl,_that.encryptedKey,_that.iv,_that.originalSize,_that.mimeType,_that.fileName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String presignedUrl,  String encryptedKey,  String iv,  int originalSize,  String mimeType,  String fileName)  $default,) {final _that = this;
switch (_that) {
case _DecryptionMetadata():
return $default(_that.presignedUrl,_that.encryptedKey,_that.iv,_that.originalSize,_that.mimeType,_that.fileName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String presignedUrl,  String encryptedKey,  String iv,  int originalSize,  String mimeType,  String fileName)?  $default,) {final _that = this;
switch (_that) {
case _DecryptionMetadata() when $default != null:
return $default(_that.presignedUrl,_that.encryptedKey,_that.iv,_that.originalSize,_that.mimeType,_that.fileName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DecryptionMetadata implements DecryptionMetadata {
  const _DecryptionMetadata({required this.presignedUrl, required this.encryptedKey, required this.iv, required this.originalSize, required this.mimeType, required this.fileName});
  factory _DecryptionMetadata.fromJson(Map<String, dynamic> json) => _$DecryptionMetadataFromJson(json);

@override final  String presignedUrl;
@override final  String encryptedKey;
@override final  String iv;
@override final  int originalSize;
@override final  String mimeType;
@override final  String fileName;

/// Create a copy of DecryptionMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DecryptionMetadataCopyWith<_DecryptionMetadata> get copyWith => __$DecryptionMetadataCopyWithImpl<_DecryptionMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DecryptionMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DecryptionMetadata&&(identical(other.presignedUrl, presignedUrl) || other.presignedUrl == presignedUrl)&&(identical(other.encryptedKey, encryptedKey) || other.encryptedKey == encryptedKey)&&(identical(other.iv, iv) || other.iv == iv)&&(identical(other.originalSize, originalSize) || other.originalSize == originalSize)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.fileName, fileName) || other.fileName == fileName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,presignedUrl,encryptedKey,iv,originalSize,mimeType,fileName);

@override
String toString() {
  return 'DecryptionMetadata(presignedUrl: $presignedUrl, encryptedKey: $encryptedKey, iv: $iv, originalSize: $originalSize, mimeType: $mimeType, fileName: $fileName)';
}


}

/// @nodoc
abstract mixin class _$DecryptionMetadataCopyWith<$Res> implements $DecryptionMetadataCopyWith<$Res> {
  factory _$DecryptionMetadataCopyWith(_DecryptionMetadata value, $Res Function(_DecryptionMetadata) _then) = __$DecryptionMetadataCopyWithImpl;
@override @useResult
$Res call({
 String presignedUrl, String encryptedKey, String iv, int originalSize, String mimeType, String fileName
});




}
/// @nodoc
class __$DecryptionMetadataCopyWithImpl<$Res>
    implements _$DecryptionMetadataCopyWith<$Res> {
  __$DecryptionMetadataCopyWithImpl(this._self, this._then);

  final _DecryptionMetadata _self;
  final $Res Function(_DecryptionMetadata) _then;

/// Create a copy of DecryptionMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? presignedUrl = null,Object? encryptedKey = null,Object? iv = null,Object? originalSize = null,Object? mimeType = null,Object? fileName = null,}) {
  return _then(_DecryptionMetadata(
presignedUrl: null == presignedUrl ? _self.presignedUrl : presignedUrl // ignore: cast_nullable_to_non_nullable
as String,encryptedKey: null == encryptedKey ? _self.encryptedKey : encryptedKey // ignore: cast_nullable_to_non_nullable
as String,iv: null == iv ? _self.iv : iv // ignore: cast_nullable_to_non_nullable
as String,originalSize: null == originalSize ? _self.originalSize : originalSize // ignore: cast_nullable_to_non_nullable
as int,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

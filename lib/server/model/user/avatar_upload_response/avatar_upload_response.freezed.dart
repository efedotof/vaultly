// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'avatar_upload_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AvatarUploadResponse {

 String? get avatarUrl; int? get fileSize;
/// Create a copy of AvatarUploadResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvatarUploadResponseCopyWith<AvatarUploadResponse> get copyWith => _$AvatarUploadResponseCopyWithImpl<AvatarUploadResponse>(this as AvatarUploadResponse, _$identity);

  /// Serializes this AvatarUploadResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvatarUploadResponse&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,avatarUrl,fileSize);

@override
String toString() {
  return 'AvatarUploadResponse(avatarUrl: $avatarUrl, fileSize: $fileSize)';
}


}

/// @nodoc
abstract mixin class $AvatarUploadResponseCopyWith<$Res>  {
  factory $AvatarUploadResponseCopyWith(AvatarUploadResponse value, $Res Function(AvatarUploadResponse) _then) = _$AvatarUploadResponseCopyWithImpl;
@useResult
$Res call({
 String? avatarUrl, int? fileSize
});




}
/// @nodoc
class _$AvatarUploadResponseCopyWithImpl<$Res>
    implements $AvatarUploadResponseCopyWith<$Res> {
  _$AvatarUploadResponseCopyWithImpl(this._self, this._then);

  final AvatarUploadResponse _self;
  final $Res Function(AvatarUploadResponse) _then;

/// Create a copy of AvatarUploadResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? avatarUrl = freezed,Object? fileSize = freezed,}) {
  return _then(_self.copyWith(
avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AvatarUploadResponse].
extension AvatarUploadResponsePatterns on AvatarUploadResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AvatarUploadResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AvatarUploadResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AvatarUploadResponse value)  $default,){
final _that = this;
switch (_that) {
case _AvatarUploadResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AvatarUploadResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AvatarUploadResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? avatarUrl,  int? fileSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AvatarUploadResponse() when $default != null:
return $default(_that.avatarUrl,_that.fileSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? avatarUrl,  int? fileSize)  $default,) {final _that = this;
switch (_that) {
case _AvatarUploadResponse():
return $default(_that.avatarUrl,_that.fileSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? avatarUrl,  int? fileSize)?  $default,) {final _that = this;
switch (_that) {
case _AvatarUploadResponse() when $default != null:
return $default(_that.avatarUrl,_that.fileSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AvatarUploadResponse implements AvatarUploadResponse {
  const _AvatarUploadResponse({this.avatarUrl, this.fileSize});
  factory _AvatarUploadResponse.fromJson(Map<String, dynamic> json) => _$AvatarUploadResponseFromJson(json);

@override final  String? avatarUrl;
@override final  int? fileSize;

/// Create a copy of AvatarUploadResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvatarUploadResponseCopyWith<_AvatarUploadResponse> get copyWith => __$AvatarUploadResponseCopyWithImpl<_AvatarUploadResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AvatarUploadResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AvatarUploadResponse&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,avatarUrl,fileSize);

@override
String toString() {
  return 'AvatarUploadResponse(avatarUrl: $avatarUrl, fileSize: $fileSize)';
}


}

/// @nodoc
abstract mixin class _$AvatarUploadResponseCopyWith<$Res> implements $AvatarUploadResponseCopyWith<$Res> {
  factory _$AvatarUploadResponseCopyWith(_AvatarUploadResponse value, $Res Function(_AvatarUploadResponse) _then) = __$AvatarUploadResponseCopyWithImpl;
@override @useResult
$Res call({
 String? avatarUrl, int? fileSize
});




}
/// @nodoc
class __$AvatarUploadResponseCopyWithImpl<$Res>
    implements _$AvatarUploadResponseCopyWith<$Res> {
  __$AvatarUploadResponseCopyWithImpl(this._self, this._then);

  final _AvatarUploadResponse _self;
  final $Res Function(_AvatarUploadResponse) _then;

/// Create a copy of AvatarUploadResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? avatarUrl = freezed,Object? fileSize = freezed,}) {
  return _then(_AvatarUploadResponse(
avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

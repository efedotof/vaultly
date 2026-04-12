// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'temp_link_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TempLinkResponse {

 String get token; String get accessUrl; DateTime get expiresAt; int? get maxDownloads; int get downloadsCount;
/// Create a copy of TempLinkResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TempLinkResponseCopyWith<TempLinkResponse> get copyWith => _$TempLinkResponseCopyWithImpl<TempLinkResponse>(this as TempLinkResponse, _$identity);

  /// Serializes this TempLinkResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TempLinkResponse&&(identical(other.token, token) || other.token == token)&&(identical(other.accessUrl, accessUrl) || other.accessUrl == accessUrl)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.maxDownloads, maxDownloads) || other.maxDownloads == maxDownloads)&&(identical(other.downloadsCount, downloadsCount) || other.downloadsCount == downloadsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,accessUrl,expiresAt,maxDownloads,downloadsCount);

@override
String toString() {
  return 'TempLinkResponse(token: $token, accessUrl: $accessUrl, expiresAt: $expiresAt, maxDownloads: $maxDownloads, downloadsCount: $downloadsCount)';
}


}

/// @nodoc
abstract mixin class $TempLinkResponseCopyWith<$Res>  {
  factory $TempLinkResponseCopyWith(TempLinkResponse value, $Res Function(TempLinkResponse) _then) = _$TempLinkResponseCopyWithImpl;
@useResult
$Res call({
 String token, String accessUrl, DateTime expiresAt, int? maxDownloads, int downloadsCount
});




}
/// @nodoc
class _$TempLinkResponseCopyWithImpl<$Res>
    implements $TempLinkResponseCopyWith<$Res> {
  _$TempLinkResponseCopyWithImpl(this._self, this._then);

  final TempLinkResponse _self;
  final $Res Function(TempLinkResponse) _then;

/// Create a copy of TempLinkResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? accessUrl = null,Object? expiresAt = null,Object? maxDownloads = freezed,Object? downloadsCount = null,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,accessUrl: null == accessUrl ? _self.accessUrl : accessUrl // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,maxDownloads: freezed == maxDownloads ? _self.maxDownloads : maxDownloads // ignore: cast_nullable_to_non_nullable
as int?,downloadsCount: null == downloadsCount ? _self.downloadsCount : downloadsCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TempLinkResponse].
extension TempLinkResponsePatterns on TempLinkResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TempLinkResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TempLinkResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TempLinkResponse value)  $default,){
final _that = this;
switch (_that) {
case _TempLinkResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TempLinkResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TempLinkResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  String accessUrl,  DateTime expiresAt,  int? maxDownloads,  int downloadsCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TempLinkResponse() when $default != null:
return $default(_that.token,_that.accessUrl,_that.expiresAt,_that.maxDownloads,_that.downloadsCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  String accessUrl,  DateTime expiresAt,  int? maxDownloads,  int downloadsCount)  $default,) {final _that = this;
switch (_that) {
case _TempLinkResponse():
return $default(_that.token,_that.accessUrl,_that.expiresAt,_that.maxDownloads,_that.downloadsCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  String accessUrl,  DateTime expiresAt,  int? maxDownloads,  int downloadsCount)?  $default,) {final _that = this;
switch (_that) {
case _TempLinkResponse() when $default != null:
return $default(_that.token,_that.accessUrl,_that.expiresAt,_that.maxDownloads,_that.downloadsCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TempLinkResponse implements TempLinkResponse {
  const _TempLinkResponse({required this.token, required this.accessUrl, required this.expiresAt, this.maxDownloads, required this.downloadsCount});
  factory _TempLinkResponse.fromJson(Map<String, dynamic> json) => _$TempLinkResponseFromJson(json);

@override final  String token;
@override final  String accessUrl;
@override final  DateTime expiresAt;
@override final  int? maxDownloads;
@override final  int downloadsCount;

/// Create a copy of TempLinkResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TempLinkResponseCopyWith<_TempLinkResponse> get copyWith => __$TempLinkResponseCopyWithImpl<_TempLinkResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TempLinkResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TempLinkResponse&&(identical(other.token, token) || other.token == token)&&(identical(other.accessUrl, accessUrl) || other.accessUrl == accessUrl)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.maxDownloads, maxDownloads) || other.maxDownloads == maxDownloads)&&(identical(other.downloadsCount, downloadsCount) || other.downloadsCount == downloadsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,accessUrl,expiresAt,maxDownloads,downloadsCount);

@override
String toString() {
  return 'TempLinkResponse(token: $token, accessUrl: $accessUrl, expiresAt: $expiresAt, maxDownloads: $maxDownloads, downloadsCount: $downloadsCount)';
}


}

/// @nodoc
abstract mixin class _$TempLinkResponseCopyWith<$Res> implements $TempLinkResponseCopyWith<$Res> {
  factory _$TempLinkResponseCopyWith(_TempLinkResponse value, $Res Function(_TempLinkResponse) _then) = __$TempLinkResponseCopyWithImpl;
@override @useResult
$Res call({
 String token, String accessUrl, DateTime expiresAt, int? maxDownloads, int downloadsCount
});




}
/// @nodoc
class __$TempLinkResponseCopyWithImpl<$Res>
    implements _$TempLinkResponseCopyWith<$Res> {
  __$TempLinkResponseCopyWithImpl(this._self, this._then);

  final _TempLinkResponse _self;
  final $Res Function(_TempLinkResponse) _then;

/// Create a copy of TempLinkResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? accessUrl = null,Object? expiresAt = null,Object? maxDownloads = freezed,Object? downloadsCount = null,}) {
  return _then(_TempLinkResponse(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,accessUrl: null == accessUrl ? _self.accessUrl : accessUrl // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,maxDownloads: freezed == maxDownloads ? _self.maxDownloads : maxDownloads // ignore: cast_nullable_to_non_nullable
as int?,downloadsCount: null == downloadsCount ? _self.downloadsCount : downloadsCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

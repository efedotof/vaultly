// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'totp_setup_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TotpSetupResponse {

 String get secret; String get qrCodeUrl;
/// Create a copy of TotpSetupResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TotpSetupResponseCopyWith<TotpSetupResponse> get copyWith => _$TotpSetupResponseCopyWithImpl<TotpSetupResponse>(this as TotpSetupResponse, _$identity);

  /// Serializes this TotpSetupResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TotpSetupResponse&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.qrCodeUrl, qrCodeUrl) || other.qrCodeUrl == qrCodeUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,secret,qrCodeUrl);

@override
String toString() {
  return 'TotpSetupResponse(secret: $secret, qrCodeUrl: $qrCodeUrl)';
}


}

/// @nodoc
abstract mixin class $TotpSetupResponseCopyWith<$Res>  {
  factory $TotpSetupResponseCopyWith(TotpSetupResponse value, $Res Function(TotpSetupResponse) _then) = _$TotpSetupResponseCopyWithImpl;
@useResult
$Res call({
 String secret, String qrCodeUrl
});




}
/// @nodoc
class _$TotpSetupResponseCopyWithImpl<$Res>
    implements $TotpSetupResponseCopyWith<$Res> {
  _$TotpSetupResponseCopyWithImpl(this._self, this._then);

  final TotpSetupResponse _self;
  final $Res Function(TotpSetupResponse) _then;

/// Create a copy of TotpSetupResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? secret = null,Object? qrCodeUrl = null,}) {
  return _then(_self.copyWith(
secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String,qrCodeUrl: null == qrCodeUrl ? _self.qrCodeUrl : qrCodeUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TotpSetupResponse].
extension TotpSetupResponsePatterns on TotpSetupResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TotpSetupResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TotpSetupResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TotpSetupResponse value)  $default,){
final _that = this;
switch (_that) {
case _TotpSetupResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TotpSetupResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TotpSetupResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String secret,  String qrCodeUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TotpSetupResponse() when $default != null:
return $default(_that.secret,_that.qrCodeUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String secret,  String qrCodeUrl)  $default,) {final _that = this;
switch (_that) {
case _TotpSetupResponse():
return $default(_that.secret,_that.qrCodeUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String secret,  String qrCodeUrl)?  $default,) {final _that = this;
switch (_that) {
case _TotpSetupResponse() when $default != null:
return $default(_that.secret,_that.qrCodeUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TotpSetupResponse implements TotpSetupResponse {
  const _TotpSetupResponse({required this.secret, required this.qrCodeUrl});
  factory _TotpSetupResponse.fromJson(Map<String, dynamic> json) => _$TotpSetupResponseFromJson(json);

@override final  String secret;
@override final  String qrCodeUrl;

/// Create a copy of TotpSetupResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TotpSetupResponseCopyWith<_TotpSetupResponse> get copyWith => __$TotpSetupResponseCopyWithImpl<_TotpSetupResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TotpSetupResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TotpSetupResponse&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.qrCodeUrl, qrCodeUrl) || other.qrCodeUrl == qrCodeUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,secret,qrCodeUrl);

@override
String toString() {
  return 'TotpSetupResponse(secret: $secret, qrCodeUrl: $qrCodeUrl)';
}


}

/// @nodoc
abstract mixin class _$TotpSetupResponseCopyWith<$Res> implements $TotpSetupResponseCopyWith<$Res> {
  factory _$TotpSetupResponseCopyWith(_TotpSetupResponse value, $Res Function(_TotpSetupResponse) _then) = __$TotpSetupResponseCopyWithImpl;
@override @useResult
$Res call({
 String secret, String qrCodeUrl
});




}
/// @nodoc
class __$TotpSetupResponseCopyWithImpl<$Res>
    implements _$TotpSetupResponseCopyWith<$Res> {
  __$TotpSetupResponseCopyWithImpl(this._self, this._then);

  final _TotpSetupResponse _self;
  final $Res Function(_TotpSetupResponse) _then;

/// Create a copy of TotpSetupResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? secret = null,Object? qrCodeUrl = null,}) {
  return _then(_TotpSetupResponse(
secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String,qrCodeUrl: null == qrCodeUrl ? _self.qrCodeUrl : qrCodeUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'totp_verify_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TotpVerifyRequest {

 String get code;
/// Create a copy of TotpVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TotpVerifyRequestCopyWith<TotpVerifyRequest> get copyWith => _$TotpVerifyRequestCopyWithImpl<TotpVerifyRequest>(this as TotpVerifyRequest, _$identity);

  /// Serializes this TotpVerifyRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TotpVerifyRequest&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code);

@override
String toString() {
  return 'TotpVerifyRequest(code: $code)';
}


}

/// @nodoc
abstract mixin class $TotpVerifyRequestCopyWith<$Res>  {
  factory $TotpVerifyRequestCopyWith(TotpVerifyRequest value, $Res Function(TotpVerifyRequest) _then) = _$TotpVerifyRequestCopyWithImpl;
@useResult
$Res call({
 String code
});




}
/// @nodoc
class _$TotpVerifyRequestCopyWithImpl<$Res>
    implements $TotpVerifyRequestCopyWith<$Res> {
  _$TotpVerifyRequestCopyWithImpl(this._self, this._then);

  final TotpVerifyRequest _self;
  final $Res Function(TotpVerifyRequest) _then;

/// Create a copy of TotpVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TotpVerifyRequest].
extension TotpVerifyRequestPatterns on TotpVerifyRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TotpVerifyRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TotpVerifyRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TotpVerifyRequest value)  $default,){
final _that = this;
switch (_that) {
case _TotpVerifyRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TotpVerifyRequest value)?  $default,){
final _that = this;
switch (_that) {
case _TotpVerifyRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TotpVerifyRequest() when $default != null:
return $default(_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code)  $default,) {final _that = this;
switch (_that) {
case _TotpVerifyRequest():
return $default(_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code)?  $default,) {final _that = this;
switch (_that) {
case _TotpVerifyRequest() when $default != null:
return $default(_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TotpVerifyRequest implements TotpVerifyRequest {
  const _TotpVerifyRequest({required this.code});
  factory _TotpVerifyRequest.fromJson(Map<String, dynamic> json) => _$TotpVerifyRequestFromJson(json);

@override final  String code;

/// Create a copy of TotpVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TotpVerifyRequestCopyWith<_TotpVerifyRequest> get copyWith => __$TotpVerifyRequestCopyWithImpl<_TotpVerifyRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TotpVerifyRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TotpVerifyRequest&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code);

@override
String toString() {
  return 'TotpVerifyRequest(code: $code)';
}


}

/// @nodoc
abstract mixin class _$TotpVerifyRequestCopyWith<$Res> implements $TotpVerifyRequestCopyWith<$Res> {
  factory _$TotpVerifyRequestCopyWith(_TotpVerifyRequest value, $Res Function(_TotpVerifyRequest) _then) = __$TotpVerifyRequestCopyWithImpl;
@override @useResult
$Res call({
 String code
});




}
/// @nodoc
class __$TotpVerifyRequestCopyWithImpl<$Res>
    implements _$TotpVerifyRequestCopyWith<$Res> {
  __$TotpVerifyRequestCopyWithImpl(this._self, this._then);

  final _TotpVerifyRequest _self;
  final $Res Function(_TotpVerifyRequest) _then;

/// Create a copy of TotpVerifyRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,}) {
  return _then(_TotpVerifyRequest(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

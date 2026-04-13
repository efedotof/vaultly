// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'totp_disable_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TotpDisableRequest {

 String get code;
/// Create a copy of TotpDisableRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TotpDisableRequestCopyWith<TotpDisableRequest> get copyWith => _$TotpDisableRequestCopyWithImpl<TotpDisableRequest>(this as TotpDisableRequest, _$identity);

  /// Serializes this TotpDisableRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TotpDisableRequest&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code);

@override
String toString() {
  return 'TotpDisableRequest(code: $code)';
}


}

/// @nodoc
abstract mixin class $TotpDisableRequestCopyWith<$Res>  {
  factory $TotpDisableRequestCopyWith(TotpDisableRequest value, $Res Function(TotpDisableRequest) _then) = _$TotpDisableRequestCopyWithImpl;
@useResult
$Res call({
 String code
});




}
/// @nodoc
class _$TotpDisableRequestCopyWithImpl<$Res>
    implements $TotpDisableRequestCopyWith<$Res> {
  _$TotpDisableRequestCopyWithImpl(this._self, this._then);

  final TotpDisableRequest _self;
  final $Res Function(TotpDisableRequest) _then;

/// Create a copy of TotpDisableRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TotpDisableRequest].
extension TotpDisableRequestPatterns on TotpDisableRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TotpDisableRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TotpDisableRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TotpDisableRequest value)  $default,){
final _that = this;
switch (_that) {
case _TotpDisableRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TotpDisableRequest value)?  $default,){
final _that = this;
switch (_that) {
case _TotpDisableRequest() when $default != null:
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
case _TotpDisableRequest() when $default != null:
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
case _TotpDisableRequest():
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
case _TotpDisableRequest() when $default != null:
return $default(_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TotpDisableRequest implements TotpDisableRequest {
  const _TotpDisableRequest({required this.code});
  factory _TotpDisableRequest.fromJson(Map<String, dynamic> json) => _$TotpDisableRequestFromJson(json);

@override final  String code;

/// Create a copy of TotpDisableRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TotpDisableRequestCopyWith<_TotpDisableRequest> get copyWith => __$TotpDisableRequestCopyWithImpl<_TotpDisableRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TotpDisableRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TotpDisableRequest&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code);

@override
String toString() {
  return 'TotpDisableRequest(code: $code)';
}


}

/// @nodoc
abstract mixin class _$TotpDisableRequestCopyWith<$Res> implements $TotpDisableRequestCopyWith<$Res> {
  factory _$TotpDisableRequestCopyWith(_TotpDisableRequest value, $Res Function(_TotpDisableRequest) _then) = __$TotpDisableRequestCopyWithImpl;
@override @useResult
$Res call({
 String code
});




}
/// @nodoc
class __$TotpDisableRequestCopyWithImpl<$Res>
    implements _$TotpDisableRequestCopyWith<$Res> {
  __$TotpDisableRequestCopyWithImpl(this._self, this._then);

  final _TotpDisableRequest _self;
  final $Res Function(_TotpDisableRequest) _then;

/// Create a copy of TotpDisableRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,}) {
  return _then(_TotpDisableRequest(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'totp_verify_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TotpVerifyResponse {

 bool get success; List<String> get backupCodes;
/// Create a copy of TotpVerifyResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TotpVerifyResponseCopyWith<TotpVerifyResponse> get copyWith => _$TotpVerifyResponseCopyWithImpl<TotpVerifyResponse>(this as TotpVerifyResponse, _$identity);

  /// Serializes this TotpVerifyResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TotpVerifyResponse&&(identical(other.success, success) || other.success == success)&&const DeepCollectionEquality().equals(other.backupCodes, backupCodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,const DeepCollectionEquality().hash(backupCodes));

@override
String toString() {
  return 'TotpVerifyResponse(success: $success, backupCodes: $backupCodes)';
}


}

/// @nodoc
abstract mixin class $TotpVerifyResponseCopyWith<$Res>  {
  factory $TotpVerifyResponseCopyWith(TotpVerifyResponse value, $Res Function(TotpVerifyResponse) _then) = _$TotpVerifyResponseCopyWithImpl;
@useResult
$Res call({
 bool success, List<String> backupCodes
});




}
/// @nodoc
class _$TotpVerifyResponseCopyWithImpl<$Res>
    implements $TotpVerifyResponseCopyWith<$Res> {
  _$TotpVerifyResponseCopyWithImpl(this._self, this._then);

  final TotpVerifyResponse _self;
  final $Res Function(TotpVerifyResponse) _then;

/// Create a copy of TotpVerifyResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? backupCodes = null,}) {
  return _then(_self.copyWith(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,backupCodes: null == backupCodes ? _self.backupCodes : backupCodes // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TotpVerifyResponse].
extension TotpVerifyResponsePatterns on TotpVerifyResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TotpVerifyResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TotpVerifyResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TotpVerifyResponse value)  $default,){
final _that = this;
switch (_that) {
case _TotpVerifyResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TotpVerifyResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TotpVerifyResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool success,  List<String> backupCodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TotpVerifyResponse() when $default != null:
return $default(_that.success,_that.backupCodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool success,  List<String> backupCodes)  $default,) {final _that = this;
switch (_that) {
case _TotpVerifyResponse():
return $default(_that.success,_that.backupCodes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool success,  List<String> backupCodes)?  $default,) {final _that = this;
switch (_that) {
case _TotpVerifyResponse() when $default != null:
return $default(_that.success,_that.backupCodes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TotpVerifyResponse implements TotpVerifyResponse {
  const _TotpVerifyResponse({required this.success, required final  List<String> backupCodes}): _backupCodes = backupCodes;
  factory _TotpVerifyResponse.fromJson(Map<String, dynamic> json) => _$TotpVerifyResponseFromJson(json);

@override final  bool success;
 final  List<String> _backupCodes;
@override List<String> get backupCodes {
  if (_backupCodes is EqualUnmodifiableListView) return _backupCodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_backupCodes);
}


/// Create a copy of TotpVerifyResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TotpVerifyResponseCopyWith<_TotpVerifyResponse> get copyWith => __$TotpVerifyResponseCopyWithImpl<_TotpVerifyResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TotpVerifyResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TotpVerifyResponse&&(identical(other.success, success) || other.success == success)&&const DeepCollectionEquality().equals(other._backupCodes, _backupCodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,const DeepCollectionEquality().hash(_backupCodes));

@override
String toString() {
  return 'TotpVerifyResponse(success: $success, backupCodes: $backupCodes)';
}


}

/// @nodoc
abstract mixin class _$TotpVerifyResponseCopyWith<$Res> implements $TotpVerifyResponseCopyWith<$Res> {
  factory _$TotpVerifyResponseCopyWith(_TotpVerifyResponse value, $Res Function(_TotpVerifyResponse) _then) = __$TotpVerifyResponseCopyWithImpl;
@override @useResult
$Res call({
 bool success, List<String> backupCodes
});




}
/// @nodoc
class __$TotpVerifyResponseCopyWithImpl<$Res>
    implements _$TotpVerifyResponseCopyWith<$Res> {
  __$TotpVerifyResponseCopyWithImpl(this._self, this._then);

  final _TotpVerifyResponse _self;
  final $Res Function(_TotpVerifyResponse) _then;

/// Create a copy of TotpVerifyResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? backupCodes = null,}) {
  return _then(_TotpVerifyResponse(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,backupCodes: null == backupCodes ? _self._backupCodes : backupCodes // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on

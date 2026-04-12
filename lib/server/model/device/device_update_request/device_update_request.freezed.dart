// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_update_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceUpdateRequest {

 String? get deviceName; bool? get isActive;
/// Create a copy of DeviceUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceUpdateRequestCopyWith<DeviceUpdateRequest> get copyWith => _$DeviceUpdateRequestCopyWithImpl<DeviceUpdateRequest>(this as DeviceUpdateRequest, _$identity);

  /// Serializes this DeviceUpdateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceUpdateRequest&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceName,isActive);

@override
String toString() {
  return 'DeviceUpdateRequest(deviceName: $deviceName, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $DeviceUpdateRequestCopyWith<$Res>  {
  factory $DeviceUpdateRequestCopyWith(DeviceUpdateRequest value, $Res Function(DeviceUpdateRequest) _then) = _$DeviceUpdateRequestCopyWithImpl;
@useResult
$Res call({
 String? deviceName, bool? isActive
});




}
/// @nodoc
class _$DeviceUpdateRequestCopyWithImpl<$Res>
    implements $DeviceUpdateRequestCopyWith<$Res> {
  _$DeviceUpdateRequestCopyWithImpl(this._self, this._then);

  final DeviceUpdateRequest _self;
  final $Res Function(DeviceUpdateRequest) _then;

/// Create a copy of DeviceUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceName = freezed,Object? isActive = freezed,}) {
  return _then(_self.copyWith(
deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceUpdateRequest].
extension DeviceUpdateRequestPatterns on DeviceUpdateRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceUpdateRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceUpdateRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceUpdateRequest value)  $default,){
final _that = this;
switch (_that) {
case _DeviceUpdateRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceUpdateRequest value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceUpdateRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? deviceName,  bool? isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceUpdateRequest() when $default != null:
return $default(_that.deviceName,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? deviceName,  bool? isActive)  $default,) {final _that = this;
switch (_that) {
case _DeviceUpdateRequest():
return $default(_that.deviceName,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? deviceName,  bool? isActive)?  $default,) {final _that = this;
switch (_that) {
case _DeviceUpdateRequest() when $default != null:
return $default(_that.deviceName,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceUpdateRequest implements DeviceUpdateRequest {
  const _DeviceUpdateRequest({this.deviceName, this.isActive});
  factory _DeviceUpdateRequest.fromJson(Map<String, dynamic> json) => _$DeviceUpdateRequestFromJson(json);

@override final  String? deviceName;
@override final  bool? isActive;

/// Create a copy of DeviceUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceUpdateRequestCopyWith<_DeviceUpdateRequest> get copyWith => __$DeviceUpdateRequestCopyWithImpl<_DeviceUpdateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceUpdateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceUpdateRequest&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceName,isActive);

@override
String toString() {
  return 'DeviceUpdateRequest(deviceName: $deviceName, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$DeviceUpdateRequestCopyWith<$Res> implements $DeviceUpdateRequestCopyWith<$Res> {
  factory _$DeviceUpdateRequestCopyWith(_DeviceUpdateRequest value, $Res Function(_DeviceUpdateRequest) _then) = __$DeviceUpdateRequestCopyWithImpl;
@override @useResult
$Res call({
 String? deviceName, bool? isActive
});




}
/// @nodoc
class __$DeviceUpdateRequestCopyWithImpl<$Res>
    implements _$DeviceUpdateRequestCopyWith<$Res> {
  __$DeviceUpdateRequestCopyWithImpl(this._self, this._then);

  final _DeviceUpdateRequest _self;
  final $Res Function(_DeviceUpdateRequest) _then;

/// Create a copy of DeviceUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceName = freezed,Object? isActive = freezed,}) {
  return _then(_DeviceUpdateRequest(
deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on

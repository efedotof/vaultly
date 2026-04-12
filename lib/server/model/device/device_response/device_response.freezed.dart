// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceResponse {

 String? get id; String? get deviceName; String? get deviceType; String? get uniqueId; bool? get isActive; DateTime? get createdAt; DateTime? get lastUsedAt;
/// Create a copy of DeviceResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceResponseCopyWith<DeviceResponse> get copyWith => _$DeviceResponseCopyWithImpl<DeviceResponse>(this as DeviceResponse, _$identity);

  /// Serializes this DeviceResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.deviceType, deviceType) || other.deviceType == deviceType)&&(identical(other.uniqueId, uniqueId) || other.uniqueId == uniqueId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,deviceName,deviceType,uniqueId,isActive,createdAt,lastUsedAt);

@override
String toString() {
  return 'DeviceResponse(id: $id, deviceName: $deviceName, deviceType: $deviceType, uniqueId: $uniqueId, isActive: $isActive, createdAt: $createdAt, lastUsedAt: $lastUsedAt)';
}


}

/// @nodoc
abstract mixin class $DeviceResponseCopyWith<$Res>  {
  factory $DeviceResponseCopyWith(DeviceResponse value, $Res Function(DeviceResponse) _then) = _$DeviceResponseCopyWithImpl;
@useResult
$Res call({
 String? id, String? deviceName, String? deviceType, String? uniqueId, bool? isActive, DateTime? createdAt, DateTime? lastUsedAt
});




}
/// @nodoc
class _$DeviceResponseCopyWithImpl<$Res>
    implements $DeviceResponseCopyWith<$Res> {
  _$DeviceResponseCopyWithImpl(this._self, this._then);

  final DeviceResponse _self;
  final $Res Function(DeviceResponse) _then;

/// Create a copy of DeviceResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? deviceName = freezed,Object? deviceType = freezed,Object? uniqueId = freezed,Object? isActive = freezed,Object? createdAt = freezed,Object? lastUsedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,deviceType: freezed == deviceType ? _self.deviceType : deviceType // ignore: cast_nullable_to_non_nullable
as String?,uniqueId: freezed == uniqueId ? _self.uniqueId : uniqueId // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceResponse].
extension DeviceResponsePatterns on DeviceResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceResponse value)  $default,){
final _that = this;
switch (_that) {
case _DeviceResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceResponse value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String? deviceName,  String? deviceType,  String? uniqueId,  bool? isActive,  DateTime? createdAt,  DateTime? lastUsedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceResponse() when $default != null:
return $default(_that.id,_that.deviceName,_that.deviceType,_that.uniqueId,_that.isActive,_that.createdAt,_that.lastUsedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String? deviceName,  String? deviceType,  String? uniqueId,  bool? isActive,  DateTime? createdAt,  DateTime? lastUsedAt)  $default,) {final _that = this;
switch (_that) {
case _DeviceResponse():
return $default(_that.id,_that.deviceName,_that.deviceType,_that.uniqueId,_that.isActive,_that.createdAt,_that.lastUsedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String? deviceName,  String? deviceType,  String? uniqueId,  bool? isActive,  DateTime? createdAt,  DateTime? lastUsedAt)?  $default,) {final _that = this;
switch (_that) {
case _DeviceResponse() when $default != null:
return $default(_that.id,_that.deviceName,_that.deviceType,_that.uniqueId,_that.isActive,_that.createdAt,_that.lastUsedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceResponse implements DeviceResponse {
  const _DeviceResponse({this.id, this.deviceName, this.deviceType, this.uniqueId, this.isActive, this.createdAt, this.lastUsedAt});
  factory _DeviceResponse.fromJson(Map<String, dynamic> json) => _$DeviceResponseFromJson(json);

@override final  String? id;
@override final  String? deviceName;
@override final  String? deviceType;
@override final  String? uniqueId;
@override final  bool? isActive;
@override final  DateTime? createdAt;
@override final  DateTime? lastUsedAt;

/// Create a copy of DeviceResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceResponseCopyWith<_DeviceResponse> get copyWith => __$DeviceResponseCopyWithImpl<_DeviceResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.deviceType, deviceType) || other.deviceType == deviceType)&&(identical(other.uniqueId, uniqueId) || other.uniqueId == uniqueId)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,deviceName,deviceType,uniqueId,isActive,createdAt,lastUsedAt);

@override
String toString() {
  return 'DeviceResponse(id: $id, deviceName: $deviceName, deviceType: $deviceType, uniqueId: $uniqueId, isActive: $isActive, createdAt: $createdAt, lastUsedAt: $lastUsedAt)';
}


}

/// @nodoc
abstract mixin class _$DeviceResponseCopyWith<$Res> implements $DeviceResponseCopyWith<$Res> {
  factory _$DeviceResponseCopyWith(_DeviceResponse value, $Res Function(_DeviceResponse) _then) = __$DeviceResponseCopyWithImpl;
@override @useResult
$Res call({
 String? id, String? deviceName, String? deviceType, String? uniqueId, bool? isActive, DateTime? createdAt, DateTime? lastUsedAt
});




}
/// @nodoc
class __$DeviceResponseCopyWithImpl<$Res>
    implements _$DeviceResponseCopyWith<$Res> {
  __$DeviceResponseCopyWithImpl(this._self, this._then);

  final _DeviceResponse _self;
  final $Res Function(_DeviceResponse) _then;

/// Create a copy of DeviceResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? deviceName = freezed,Object? deviceType = freezed,Object? uniqueId = freezed,Object? isActive = freezed,Object? createdAt = freezed,Object? lastUsedAt = freezed,}) {
  return _then(_DeviceResponse(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,deviceType: freezed == deviceType ? _self.deviceType : deviceType // ignore: cast_nullable_to_non_nullable
as String?,uniqueId: freezed == uniqueId ? _self.uniqueId : uniqueId // ignore: cast_nullable_to_non_nullable
as String?,isActive: freezed == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

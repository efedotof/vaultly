// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_access_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FolderAccessDto {

 String? get folderId; String? get password; String? get hiddenFolderKey;
/// Create a copy of FolderAccessDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderAccessDtoCopyWith<FolderAccessDto> get copyWith => _$FolderAccessDtoCopyWithImpl<FolderAccessDto>(this as FolderAccessDto, _$identity);

  /// Serializes this FolderAccessDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderAccessDto&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.password, password) || other.password == password)&&(identical(other.hiddenFolderKey, hiddenFolderKey) || other.hiddenFolderKey == hiddenFolderKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,folderId,password,hiddenFolderKey);

@override
String toString() {
  return 'FolderAccessDto(folderId: $folderId, password: $password, hiddenFolderKey: $hiddenFolderKey)';
}


}

/// @nodoc
abstract mixin class $FolderAccessDtoCopyWith<$Res>  {
  factory $FolderAccessDtoCopyWith(FolderAccessDto value, $Res Function(FolderAccessDto) _then) = _$FolderAccessDtoCopyWithImpl;
@useResult
$Res call({
 String? folderId, String? password, String? hiddenFolderKey
});




}
/// @nodoc
class _$FolderAccessDtoCopyWithImpl<$Res>
    implements $FolderAccessDtoCopyWith<$Res> {
  _$FolderAccessDtoCopyWithImpl(this._self, this._then);

  final FolderAccessDto _self;
  final $Res Function(FolderAccessDto) _then;

/// Create a copy of FolderAccessDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? folderId = freezed,Object? password = freezed,Object? hiddenFolderKey = freezed,}) {
  return _then(_self.copyWith(
folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,hiddenFolderKey: freezed == hiddenFolderKey ? _self.hiddenFolderKey : hiddenFolderKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FolderAccessDto].
extension FolderAccessDtoPatterns on FolderAccessDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FolderAccessDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FolderAccessDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FolderAccessDto value)  $default,){
final _that = this;
switch (_that) {
case _FolderAccessDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FolderAccessDto value)?  $default,){
final _that = this;
switch (_that) {
case _FolderAccessDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? folderId,  String? password,  String? hiddenFolderKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FolderAccessDto() when $default != null:
return $default(_that.folderId,_that.password,_that.hiddenFolderKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? folderId,  String? password,  String? hiddenFolderKey)  $default,) {final _that = this;
switch (_that) {
case _FolderAccessDto():
return $default(_that.folderId,_that.password,_that.hiddenFolderKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? folderId,  String? password,  String? hiddenFolderKey)?  $default,) {final _that = this;
switch (_that) {
case _FolderAccessDto() when $default != null:
return $default(_that.folderId,_that.password,_that.hiddenFolderKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FolderAccessDto implements FolderAccessDto {
  const _FolderAccessDto({this.folderId, this.password, this.hiddenFolderKey});
  factory _FolderAccessDto.fromJson(Map<String, dynamic> json) => _$FolderAccessDtoFromJson(json);

@override final  String? folderId;
@override final  String? password;
@override final  String? hiddenFolderKey;

/// Create a copy of FolderAccessDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FolderAccessDtoCopyWith<_FolderAccessDto> get copyWith => __$FolderAccessDtoCopyWithImpl<_FolderAccessDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FolderAccessDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FolderAccessDto&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.password, password) || other.password == password)&&(identical(other.hiddenFolderKey, hiddenFolderKey) || other.hiddenFolderKey == hiddenFolderKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,folderId,password,hiddenFolderKey);

@override
String toString() {
  return 'FolderAccessDto(folderId: $folderId, password: $password, hiddenFolderKey: $hiddenFolderKey)';
}


}

/// @nodoc
abstract mixin class _$FolderAccessDtoCopyWith<$Res> implements $FolderAccessDtoCopyWith<$Res> {
  factory _$FolderAccessDtoCopyWith(_FolderAccessDto value, $Res Function(_FolderAccessDto) _then) = __$FolderAccessDtoCopyWithImpl;
@override @useResult
$Res call({
 String? folderId, String? password, String? hiddenFolderKey
});




}
/// @nodoc
class __$FolderAccessDtoCopyWithImpl<$Res>
    implements _$FolderAccessDtoCopyWith<$Res> {
  __$FolderAccessDtoCopyWithImpl(this._self, this._then);

  final _FolderAccessDto _self;
  final $Res Function(_FolderAccessDto) _then;

/// Create a copy of FolderAccessDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? folderId = freezed,Object? password = freezed,Object? hiddenFolderKey = freezed,}) {
  return _then(_FolderAccessDto(
folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,hiddenFolderKey: freezed == hiddenFolderKey ? _self.hiddenFolderKey : hiddenFolderKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

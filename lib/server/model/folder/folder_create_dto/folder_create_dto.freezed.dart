// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_create_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FolderCreateDto {

 String get name; String? get parentFolderId; bool? get isHidden; String? get hiddenFolderKey; bool? get isPrivate; String? get password; String? get description;
/// Create a copy of FolderCreateDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderCreateDtoCopyWith<FolderCreateDto> get copyWith => _$FolderCreateDtoCopyWithImpl<FolderCreateDto>(this as FolderCreateDto, _$identity);

  /// Serializes this FolderCreateDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderCreateDto&&(identical(other.name, name) || other.name == name)&&(identical(other.parentFolderId, parentFolderId) || other.parentFolderId == parentFolderId)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.hiddenFolderKey, hiddenFolderKey) || other.hiddenFolderKey == hiddenFolderKey)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate)&&(identical(other.password, password) || other.password == password)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,parentFolderId,isHidden,hiddenFolderKey,isPrivate,password,description);

@override
String toString() {
  return 'FolderCreateDto(name: $name, parentFolderId: $parentFolderId, isHidden: $isHidden, hiddenFolderKey: $hiddenFolderKey, isPrivate: $isPrivate, password: $password, description: $description)';
}


}

/// @nodoc
abstract mixin class $FolderCreateDtoCopyWith<$Res>  {
  factory $FolderCreateDtoCopyWith(FolderCreateDto value, $Res Function(FolderCreateDto) _then) = _$FolderCreateDtoCopyWithImpl;
@useResult
$Res call({
 String name, String? parentFolderId, bool? isHidden, String? hiddenFolderKey, bool? isPrivate, String? password, String? description
});




}
/// @nodoc
class _$FolderCreateDtoCopyWithImpl<$Res>
    implements $FolderCreateDtoCopyWith<$Res> {
  _$FolderCreateDtoCopyWithImpl(this._self, this._then);

  final FolderCreateDto _self;
  final $Res Function(FolderCreateDto) _then;

/// Create a copy of FolderCreateDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? parentFolderId = freezed,Object? isHidden = freezed,Object? hiddenFolderKey = freezed,Object? isPrivate = freezed,Object? password = freezed,Object? description = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,parentFolderId: freezed == parentFolderId ? _self.parentFolderId : parentFolderId // ignore: cast_nullable_to_non_nullable
as String?,isHidden: freezed == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool?,hiddenFolderKey: freezed == hiddenFolderKey ? _self.hiddenFolderKey : hiddenFolderKey // ignore: cast_nullable_to_non_nullable
as String?,isPrivate: freezed == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FolderCreateDto].
extension FolderCreateDtoPatterns on FolderCreateDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FolderCreateDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FolderCreateDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FolderCreateDto value)  $default,){
final _that = this;
switch (_that) {
case _FolderCreateDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FolderCreateDto value)?  $default,){
final _that = this;
switch (_that) {
case _FolderCreateDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? parentFolderId,  bool? isHidden,  String? hiddenFolderKey,  bool? isPrivate,  String? password,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FolderCreateDto() when $default != null:
return $default(_that.name,_that.parentFolderId,_that.isHidden,_that.hiddenFolderKey,_that.isPrivate,_that.password,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? parentFolderId,  bool? isHidden,  String? hiddenFolderKey,  bool? isPrivate,  String? password,  String? description)  $default,) {final _that = this;
switch (_that) {
case _FolderCreateDto():
return $default(_that.name,_that.parentFolderId,_that.isHidden,_that.hiddenFolderKey,_that.isPrivate,_that.password,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? parentFolderId,  bool? isHidden,  String? hiddenFolderKey,  bool? isPrivate,  String? password,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _FolderCreateDto() when $default != null:
return $default(_that.name,_that.parentFolderId,_that.isHidden,_that.hiddenFolderKey,_that.isPrivate,_that.password,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FolderCreateDto implements FolderCreateDto {
  const _FolderCreateDto({required this.name, this.parentFolderId, this.isHidden, this.hiddenFolderKey, this.isPrivate, this.password, this.description});
  factory _FolderCreateDto.fromJson(Map<String, dynamic> json) => _$FolderCreateDtoFromJson(json);

@override final  String name;
@override final  String? parentFolderId;
@override final  bool? isHidden;
@override final  String? hiddenFolderKey;
@override final  bool? isPrivate;
@override final  String? password;
@override final  String? description;

/// Create a copy of FolderCreateDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FolderCreateDtoCopyWith<_FolderCreateDto> get copyWith => __$FolderCreateDtoCopyWithImpl<_FolderCreateDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FolderCreateDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FolderCreateDto&&(identical(other.name, name) || other.name == name)&&(identical(other.parentFolderId, parentFolderId) || other.parentFolderId == parentFolderId)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.hiddenFolderKey, hiddenFolderKey) || other.hiddenFolderKey == hiddenFolderKey)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate)&&(identical(other.password, password) || other.password == password)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,parentFolderId,isHidden,hiddenFolderKey,isPrivate,password,description);

@override
String toString() {
  return 'FolderCreateDto(name: $name, parentFolderId: $parentFolderId, isHidden: $isHidden, hiddenFolderKey: $hiddenFolderKey, isPrivate: $isPrivate, password: $password, description: $description)';
}


}

/// @nodoc
abstract mixin class _$FolderCreateDtoCopyWith<$Res> implements $FolderCreateDtoCopyWith<$Res> {
  factory _$FolderCreateDtoCopyWith(_FolderCreateDto value, $Res Function(_FolderCreateDto) _then) = __$FolderCreateDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, String? parentFolderId, bool? isHidden, String? hiddenFolderKey, bool? isPrivate, String? password, String? description
});




}
/// @nodoc
class __$FolderCreateDtoCopyWithImpl<$Res>
    implements _$FolderCreateDtoCopyWith<$Res> {
  __$FolderCreateDtoCopyWithImpl(this._self, this._then);

  final _FolderCreateDto _self;
  final $Res Function(_FolderCreateDto) _then;

/// Create a copy of FolderCreateDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? parentFolderId = freezed,Object? isHidden = freezed,Object? hiddenFolderKey = freezed,Object? isPrivate = freezed,Object? password = freezed,Object? description = freezed,}) {
  return _then(_FolderCreateDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,parentFolderId: freezed == parentFolderId ? _self.parentFolderId : parentFolderId // ignore: cast_nullable_to_non_nullable
as String?,isHidden: freezed == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool?,hiddenFolderKey: freezed == hiddenFolderKey ? _self.hiddenFolderKey : hiddenFolderKey // ignore: cast_nullable_to_non_nullable
as String?,isPrivate: freezed == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_update_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FolderUpdateDto {

 String? get name; String? get description; bool? get isHidden;
/// Create a copy of FolderUpdateDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderUpdateDtoCopyWith<FolderUpdateDto> get copyWith => _$FolderUpdateDtoCopyWithImpl<FolderUpdateDto>(this as FolderUpdateDto, _$identity);

  /// Serializes this FolderUpdateDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderUpdateDto&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,isHidden);

@override
String toString() {
  return 'FolderUpdateDto(name: $name, description: $description, isHidden: $isHidden)';
}


}

/// @nodoc
abstract mixin class $FolderUpdateDtoCopyWith<$Res>  {
  factory $FolderUpdateDtoCopyWith(FolderUpdateDto value, $Res Function(FolderUpdateDto) _then) = _$FolderUpdateDtoCopyWithImpl;
@useResult
$Res call({
 String? name, String? description, bool? isHidden
});




}
/// @nodoc
class _$FolderUpdateDtoCopyWithImpl<$Res>
    implements $FolderUpdateDtoCopyWith<$Res> {
  _$FolderUpdateDtoCopyWithImpl(this._self, this._then);

  final FolderUpdateDto _self;
  final $Res Function(FolderUpdateDto) _then;

/// Create a copy of FolderUpdateDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? description = freezed,Object? isHidden = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isHidden: freezed == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [FolderUpdateDto].
extension FolderUpdateDtoPatterns on FolderUpdateDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FolderUpdateDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FolderUpdateDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FolderUpdateDto value)  $default,){
final _that = this;
switch (_that) {
case _FolderUpdateDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FolderUpdateDto value)?  $default,){
final _that = this;
switch (_that) {
case _FolderUpdateDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? description,  bool? isHidden)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FolderUpdateDto() when $default != null:
return $default(_that.name,_that.description,_that.isHidden);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? description,  bool? isHidden)  $default,) {final _that = this;
switch (_that) {
case _FolderUpdateDto():
return $default(_that.name,_that.description,_that.isHidden);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? description,  bool? isHidden)?  $default,) {final _that = this;
switch (_that) {
case _FolderUpdateDto() when $default != null:
return $default(_that.name,_that.description,_that.isHidden);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FolderUpdateDto implements FolderUpdateDto {
  const _FolderUpdateDto({this.name, this.description, this.isHidden});
  factory _FolderUpdateDto.fromJson(Map<String, dynamic> json) => _$FolderUpdateDtoFromJson(json);

@override final  String? name;
@override final  String? description;
@override final  bool? isHidden;

/// Create a copy of FolderUpdateDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FolderUpdateDtoCopyWith<_FolderUpdateDto> get copyWith => __$FolderUpdateDtoCopyWithImpl<_FolderUpdateDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FolderUpdateDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FolderUpdateDto&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,description,isHidden);

@override
String toString() {
  return 'FolderUpdateDto(name: $name, description: $description, isHidden: $isHidden)';
}


}

/// @nodoc
abstract mixin class _$FolderUpdateDtoCopyWith<$Res> implements $FolderUpdateDtoCopyWith<$Res> {
  factory _$FolderUpdateDtoCopyWith(_FolderUpdateDto value, $Res Function(_FolderUpdateDto) _then) = __$FolderUpdateDtoCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? description, bool? isHidden
});




}
/// @nodoc
class __$FolderUpdateDtoCopyWithImpl<$Res>
    implements _$FolderUpdateDtoCopyWith<$Res> {
  __$FolderUpdateDtoCopyWithImpl(this._self, this._then);

  final _FolderUpdateDto _self;
  final $Res Function(_FolderUpdateDto) _then;

/// Create a copy of FolderUpdateDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? description = freezed,Object? isHidden = freezed,}) {
  return _then(_FolderUpdateDto(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isHidden: freezed == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on

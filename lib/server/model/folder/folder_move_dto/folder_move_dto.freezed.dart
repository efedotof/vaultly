// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_move_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FolderMoveDto {

 List<String>? get fileIds; String? get targetFolderId; String? get sourceFolderId; bool? get copy;
/// Create a copy of FolderMoveDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderMoveDtoCopyWith<FolderMoveDto> get copyWith => _$FolderMoveDtoCopyWithImpl<FolderMoveDto>(this as FolderMoveDto, _$identity);

  /// Serializes this FolderMoveDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderMoveDto&&const DeepCollectionEquality().equals(other.fileIds, fileIds)&&(identical(other.targetFolderId, targetFolderId) || other.targetFolderId == targetFolderId)&&(identical(other.sourceFolderId, sourceFolderId) || other.sourceFolderId == sourceFolderId)&&(identical(other.copy, copy) || other.copy == copy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(fileIds),targetFolderId,sourceFolderId,copy);

@override
String toString() {
  return 'FolderMoveDto(fileIds: $fileIds, targetFolderId: $targetFolderId, sourceFolderId: $sourceFolderId, copy: $copy)';
}


}

/// @nodoc
abstract mixin class $FolderMoveDtoCopyWith<$Res>  {
  factory $FolderMoveDtoCopyWith(FolderMoveDto value, $Res Function(FolderMoveDto) _then) = _$FolderMoveDtoCopyWithImpl;
@useResult
$Res call({
 List<String>? fileIds, String? targetFolderId, String? sourceFolderId, bool? copy
});




}
/// @nodoc
class _$FolderMoveDtoCopyWithImpl<$Res>
    implements $FolderMoveDtoCopyWith<$Res> {
  _$FolderMoveDtoCopyWithImpl(this._self, this._then);

  final FolderMoveDto _self;
  final $Res Function(FolderMoveDto) _then;

/// Create a copy of FolderMoveDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileIds = freezed,Object? targetFolderId = freezed,Object? sourceFolderId = freezed,Object? copy = freezed,}) {
  return _then(_self.copyWith(
fileIds: freezed == fileIds ? _self.fileIds : fileIds // ignore: cast_nullable_to_non_nullable
as List<String>?,targetFolderId: freezed == targetFolderId ? _self.targetFolderId : targetFolderId // ignore: cast_nullable_to_non_nullable
as String?,sourceFolderId: freezed == sourceFolderId ? _self.sourceFolderId : sourceFolderId // ignore: cast_nullable_to_non_nullable
as String?,copy: freezed == copy ? _self.copy : copy // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [FolderMoveDto].
extension FolderMoveDtoPatterns on FolderMoveDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FolderMoveDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FolderMoveDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FolderMoveDto value)  $default,){
final _that = this;
switch (_that) {
case _FolderMoveDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FolderMoveDto value)?  $default,){
final _that = this;
switch (_that) {
case _FolderMoveDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String>? fileIds,  String? targetFolderId,  String? sourceFolderId,  bool? copy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FolderMoveDto() when $default != null:
return $default(_that.fileIds,_that.targetFolderId,_that.sourceFolderId,_that.copy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String>? fileIds,  String? targetFolderId,  String? sourceFolderId,  bool? copy)  $default,) {final _that = this;
switch (_that) {
case _FolderMoveDto():
return $default(_that.fileIds,_that.targetFolderId,_that.sourceFolderId,_that.copy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String>? fileIds,  String? targetFolderId,  String? sourceFolderId,  bool? copy)?  $default,) {final _that = this;
switch (_that) {
case _FolderMoveDto() when $default != null:
return $default(_that.fileIds,_that.targetFolderId,_that.sourceFolderId,_that.copy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FolderMoveDto implements FolderMoveDto {
  const _FolderMoveDto({final  List<String>? fileIds, this.targetFolderId, this.sourceFolderId, this.copy}): _fileIds = fileIds;
  factory _FolderMoveDto.fromJson(Map<String, dynamic> json) => _$FolderMoveDtoFromJson(json);

 final  List<String>? _fileIds;
@override List<String>? get fileIds {
  final value = _fileIds;
  if (value == null) return null;
  if (_fileIds is EqualUnmodifiableListView) return _fileIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? targetFolderId;
@override final  String? sourceFolderId;
@override final  bool? copy;

/// Create a copy of FolderMoveDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FolderMoveDtoCopyWith<_FolderMoveDto> get copyWith => __$FolderMoveDtoCopyWithImpl<_FolderMoveDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FolderMoveDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FolderMoveDto&&const DeepCollectionEquality().equals(other._fileIds, _fileIds)&&(identical(other.targetFolderId, targetFolderId) || other.targetFolderId == targetFolderId)&&(identical(other.sourceFolderId, sourceFolderId) || other.sourceFolderId == sourceFolderId)&&(identical(other.copy, copy) || other.copy == copy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fileIds),targetFolderId,sourceFolderId,copy);

@override
String toString() {
  return 'FolderMoveDto(fileIds: $fileIds, targetFolderId: $targetFolderId, sourceFolderId: $sourceFolderId, copy: $copy)';
}


}

/// @nodoc
abstract mixin class _$FolderMoveDtoCopyWith<$Res> implements $FolderMoveDtoCopyWith<$Res> {
  factory _$FolderMoveDtoCopyWith(_FolderMoveDto value, $Res Function(_FolderMoveDto) _then) = __$FolderMoveDtoCopyWithImpl;
@override @useResult
$Res call({
 List<String>? fileIds, String? targetFolderId, String? sourceFolderId, bool? copy
});




}
/// @nodoc
class __$FolderMoveDtoCopyWithImpl<$Res>
    implements _$FolderMoveDtoCopyWith<$Res> {
  __$FolderMoveDtoCopyWithImpl(this._self, this._then);

  final _FolderMoveDto _self;
  final $Res Function(_FolderMoveDto) _then;

/// Create a copy of FolderMoveDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileIds = freezed,Object? targetFolderId = freezed,Object? sourceFolderId = freezed,Object? copy = freezed,}) {
  return _then(_FolderMoveDto(
fileIds: freezed == fileIds ? _self._fileIds : fileIds // ignore: cast_nullable_to_non_nullable
as List<String>?,targetFolderId: freezed == targetFolderId ? _self.targetFolderId : targetFolderId // ignore: cast_nullable_to_non_nullable
as String?,sourceFolderId: freezed == sourceFolderId ? _self.sourceFolderId : sourceFolderId // ignore: cast_nullable_to_non_nullable
as String?,copy: freezed == copy ? _self.copy : copy // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on

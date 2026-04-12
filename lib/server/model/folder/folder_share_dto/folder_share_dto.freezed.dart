// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_share_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FolderShareDto {

 String? get folderId; List<String>? get userIds; bool? get canEdit; bool? get canDelete; bool? get canShare; String? get message;
/// Create a copy of FolderShareDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderShareDtoCopyWith<FolderShareDto> get copyWith => _$FolderShareDtoCopyWithImpl<FolderShareDto>(this as FolderShareDto, _$identity);

  /// Serializes this FolderShareDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderShareDto&&(identical(other.folderId, folderId) || other.folderId == folderId)&&const DeepCollectionEquality().equals(other.userIds, userIds)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.canDelete, canDelete) || other.canDelete == canDelete)&&(identical(other.canShare, canShare) || other.canShare == canShare)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,folderId,const DeepCollectionEquality().hash(userIds),canEdit,canDelete,canShare,message);

@override
String toString() {
  return 'FolderShareDto(folderId: $folderId, userIds: $userIds, canEdit: $canEdit, canDelete: $canDelete, canShare: $canShare, message: $message)';
}


}

/// @nodoc
abstract mixin class $FolderShareDtoCopyWith<$Res>  {
  factory $FolderShareDtoCopyWith(FolderShareDto value, $Res Function(FolderShareDto) _then) = _$FolderShareDtoCopyWithImpl;
@useResult
$Res call({
 String? folderId, List<String>? userIds, bool? canEdit, bool? canDelete, bool? canShare, String? message
});




}
/// @nodoc
class _$FolderShareDtoCopyWithImpl<$Res>
    implements $FolderShareDtoCopyWith<$Res> {
  _$FolderShareDtoCopyWithImpl(this._self, this._then);

  final FolderShareDto _self;
  final $Res Function(FolderShareDto) _then;

/// Create a copy of FolderShareDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? folderId = freezed,Object? userIds = freezed,Object? canEdit = freezed,Object? canDelete = freezed,Object? canShare = freezed,Object? message = freezed,}) {
  return _then(_self.copyWith(
folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,userIds: freezed == userIds ? _self.userIds : userIds // ignore: cast_nullable_to_non_nullable
as List<String>?,canEdit: freezed == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool?,canDelete: freezed == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool?,canShare: freezed == canShare ? _self.canShare : canShare // ignore: cast_nullable_to_non_nullable
as bool?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FolderShareDto].
extension FolderShareDtoPatterns on FolderShareDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FolderShareDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FolderShareDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FolderShareDto value)  $default,){
final _that = this;
switch (_that) {
case _FolderShareDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FolderShareDto value)?  $default,){
final _that = this;
switch (_that) {
case _FolderShareDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? folderId,  List<String>? userIds,  bool? canEdit,  bool? canDelete,  bool? canShare,  String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FolderShareDto() when $default != null:
return $default(_that.folderId,_that.userIds,_that.canEdit,_that.canDelete,_that.canShare,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? folderId,  List<String>? userIds,  bool? canEdit,  bool? canDelete,  bool? canShare,  String? message)  $default,) {final _that = this;
switch (_that) {
case _FolderShareDto():
return $default(_that.folderId,_that.userIds,_that.canEdit,_that.canDelete,_that.canShare,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? folderId,  List<String>? userIds,  bool? canEdit,  bool? canDelete,  bool? canShare,  String? message)?  $default,) {final _that = this;
switch (_that) {
case _FolderShareDto() when $default != null:
return $default(_that.folderId,_that.userIds,_that.canEdit,_that.canDelete,_that.canShare,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FolderShareDto implements FolderShareDto {
  const _FolderShareDto({this.folderId, final  List<String>? userIds, this.canEdit, this.canDelete, this.canShare, this.message}): _userIds = userIds;
  factory _FolderShareDto.fromJson(Map<String, dynamic> json) => _$FolderShareDtoFromJson(json);

@override final  String? folderId;
 final  List<String>? _userIds;
@override List<String>? get userIds {
  final value = _userIds;
  if (value == null) return null;
  if (_userIds is EqualUnmodifiableListView) return _userIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  bool? canEdit;
@override final  bool? canDelete;
@override final  bool? canShare;
@override final  String? message;

/// Create a copy of FolderShareDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FolderShareDtoCopyWith<_FolderShareDto> get copyWith => __$FolderShareDtoCopyWithImpl<_FolderShareDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FolderShareDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FolderShareDto&&(identical(other.folderId, folderId) || other.folderId == folderId)&&const DeepCollectionEquality().equals(other._userIds, _userIds)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.canDelete, canDelete) || other.canDelete == canDelete)&&(identical(other.canShare, canShare) || other.canShare == canShare)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,folderId,const DeepCollectionEquality().hash(_userIds),canEdit,canDelete,canShare,message);

@override
String toString() {
  return 'FolderShareDto(folderId: $folderId, userIds: $userIds, canEdit: $canEdit, canDelete: $canDelete, canShare: $canShare, message: $message)';
}


}

/// @nodoc
abstract mixin class _$FolderShareDtoCopyWith<$Res> implements $FolderShareDtoCopyWith<$Res> {
  factory _$FolderShareDtoCopyWith(_FolderShareDto value, $Res Function(_FolderShareDto) _then) = __$FolderShareDtoCopyWithImpl;
@override @useResult
$Res call({
 String? folderId, List<String>? userIds, bool? canEdit, bool? canDelete, bool? canShare, String? message
});




}
/// @nodoc
class __$FolderShareDtoCopyWithImpl<$Res>
    implements _$FolderShareDtoCopyWith<$Res> {
  __$FolderShareDtoCopyWithImpl(this._self, this._then);

  final _FolderShareDto _self;
  final $Res Function(_FolderShareDto) _then;

/// Create a copy of FolderShareDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? folderId = freezed,Object? userIds = freezed,Object? canEdit = freezed,Object? canDelete = freezed,Object? canShare = freezed,Object? message = freezed,}) {
  return _then(_FolderShareDto(
folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,userIds: freezed == userIds ? _self._userIds : userIds // ignore: cast_nullable_to_non_nullable
as List<String>?,canEdit: freezed == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool?,canDelete: freezed == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool?,canShare: freezed == canShare ? _self.canShare : canShare // ignore: cast_nullable_to_non_nullable
as bool?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

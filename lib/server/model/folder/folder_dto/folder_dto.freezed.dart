// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FolderDto {

 String? get id; String? get name; String? get path; FolderType? get type; bool? get isHidden; bool? get isLocked; String? get allowedUsers; DateTime? get createdAt; DateTime? get updatedAt; String? get parentFolderId; String? get parentFolderName; List<FolderDto>? get subfolders; List<FileDto>? get files;
/// Create a copy of FolderDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderDtoCopyWith<FolderDto> get copyWith => _$FolderDtoCopyWithImpl<FolderDto>(this as FolderDto, _$identity);

  /// Serializes this FolderDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.allowedUsers, allowedUsers) || other.allowedUsers == allowedUsers)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.parentFolderId, parentFolderId) || other.parentFolderId == parentFolderId)&&(identical(other.parentFolderName, parentFolderName) || other.parentFolderName == parentFolderName)&&const DeepCollectionEquality().equals(other.subfolders, subfolders)&&const DeepCollectionEquality().equals(other.files, files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,path,type,isHidden,isLocked,allowedUsers,createdAt,updatedAt,parentFolderId,parentFolderName,const DeepCollectionEquality().hash(subfolders),const DeepCollectionEquality().hash(files));

@override
String toString() {
  return 'FolderDto(id: $id, name: $name, path: $path, type: $type, isHidden: $isHidden, isLocked: $isLocked, allowedUsers: $allowedUsers, createdAt: $createdAt, updatedAt: $updatedAt, parentFolderId: $parentFolderId, parentFolderName: $parentFolderName, subfolders: $subfolders, files: $files)';
}


}

/// @nodoc
abstract mixin class $FolderDtoCopyWith<$Res>  {
  factory $FolderDtoCopyWith(FolderDto value, $Res Function(FolderDto) _then) = _$FolderDtoCopyWithImpl;
@useResult
$Res call({
 String? id, String? name, String? path, FolderType? type, bool? isHidden, bool? isLocked, String? allowedUsers, DateTime? createdAt, DateTime? updatedAt, String? parentFolderId, String? parentFolderName, List<FolderDto>? subfolders, List<FileDto>? files
});




}
/// @nodoc
class _$FolderDtoCopyWithImpl<$Res>
    implements $FolderDtoCopyWith<$Res> {
  _$FolderDtoCopyWithImpl(this._self, this._then);

  final FolderDto _self;
  final $Res Function(FolderDto) _then;

/// Create a copy of FolderDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = freezed,Object? path = freezed,Object? type = freezed,Object? isHidden = freezed,Object? isLocked = freezed,Object? allowedUsers = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? parentFolderId = freezed,Object? parentFolderName = freezed,Object? subfolders = freezed,Object? files = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as FolderType?,isHidden: freezed == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool?,isLocked: freezed == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool?,allowedUsers: freezed == allowedUsers ? _self.allowedUsers : allowedUsers // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,parentFolderId: freezed == parentFolderId ? _self.parentFolderId : parentFolderId // ignore: cast_nullable_to_non_nullable
as String?,parentFolderName: freezed == parentFolderName ? _self.parentFolderName : parentFolderName // ignore: cast_nullable_to_non_nullable
as String?,subfolders: freezed == subfolders ? _self.subfolders : subfolders // ignore: cast_nullable_to_non_nullable
as List<FolderDto>?,files: freezed == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<FileDto>?,
  ));
}

}


/// Adds pattern-matching-related methods to [FolderDto].
extension FolderDtoPatterns on FolderDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FolderDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FolderDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FolderDto value)  $default,){
final _that = this;
switch (_that) {
case _FolderDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FolderDto value)?  $default,){
final _that = this;
switch (_that) {
case _FolderDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String? name,  String? path,  FolderType? type,  bool? isHidden,  bool? isLocked,  String? allowedUsers,  DateTime? createdAt,  DateTime? updatedAt,  String? parentFolderId,  String? parentFolderName,  List<FolderDto>? subfolders,  List<FileDto>? files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FolderDto() when $default != null:
return $default(_that.id,_that.name,_that.path,_that.type,_that.isHidden,_that.isLocked,_that.allowedUsers,_that.createdAt,_that.updatedAt,_that.parentFolderId,_that.parentFolderName,_that.subfolders,_that.files);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String? name,  String? path,  FolderType? type,  bool? isHidden,  bool? isLocked,  String? allowedUsers,  DateTime? createdAt,  DateTime? updatedAt,  String? parentFolderId,  String? parentFolderName,  List<FolderDto>? subfolders,  List<FileDto>? files)  $default,) {final _that = this;
switch (_that) {
case _FolderDto():
return $default(_that.id,_that.name,_that.path,_that.type,_that.isHidden,_that.isLocked,_that.allowedUsers,_that.createdAt,_that.updatedAt,_that.parentFolderId,_that.parentFolderName,_that.subfolders,_that.files);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String? name,  String? path,  FolderType? type,  bool? isHidden,  bool? isLocked,  String? allowedUsers,  DateTime? createdAt,  DateTime? updatedAt,  String? parentFolderId,  String? parentFolderName,  List<FolderDto>? subfolders,  List<FileDto>? files)?  $default,) {final _that = this;
switch (_that) {
case _FolderDto() when $default != null:
return $default(_that.id,_that.name,_that.path,_that.type,_that.isHidden,_that.isLocked,_that.allowedUsers,_that.createdAt,_that.updatedAt,_that.parentFolderId,_that.parentFolderName,_that.subfolders,_that.files);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FolderDto implements FolderDto {
  const _FolderDto({required this.id, required this.name, required this.path, required this.type, required this.isHidden, required this.isLocked, required this.allowedUsers, required this.createdAt, required this.updatedAt, this.parentFolderId, this.parentFolderName, final  List<FolderDto>? subfolders = const [], final  List<FileDto>? files = const []}): _subfolders = subfolders,_files = files;
  factory _FolderDto.fromJson(Map<String, dynamic> json) => _$FolderDtoFromJson(json);

@override final  String? id;
@override final  String? name;
@override final  String? path;
@override final  FolderType? type;
@override final  bool? isHidden;
@override final  bool? isLocked;
@override final  String? allowedUsers;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? parentFolderId;
@override final  String? parentFolderName;
 final  List<FolderDto>? _subfolders;
@override@JsonKey() List<FolderDto>? get subfolders {
  final value = _subfolders;
  if (value == null) return null;
  if (_subfolders is EqualUnmodifiableListView) return _subfolders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<FileDto>? _files;
@override@JsonKey() List<FileDto>? get files {
  final value = _files;
  if (value == null) return null;
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of FolderDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FolderDtoCopyWith<_FolderDto> get copyWith => __$FolderDtoCopyWithImpl<_FolderDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FolderDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FolderDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.type, type) || other.type == type)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.allowedUsers, allowedUsers) || other.allowedUsers == allowedUsers)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.parentFolderId, parentFolderId) || other.parentFolderId == parentFolderId)&&(identical(other.parentFolderName, parentFolderName) || other.parentFolderName == parentFolderName)&&const DeepCollectionEquality().equals(other._subfolders, _subfolders)&&const DeepCollectionEquality().equals(other._files, _files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,path,type,isHidden,isLocked,allowedUsers,createdAt,updatedAt,parentFolderId,parentFolderName,const DeepCollectionEquality().hash(_subfolders),const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'FolderDto(id: $id, name: $name, path: $path, type: $type, isHidden: $isHidden, isLocked: $isLocked, allowedUsers: $allowedUsers, createdAt: $createdAt, updatedAt: $updatedAt, parentFolderId: $parentFolderId, parentFolderName: $parentFolderName, subfolders: $subfolders, files: $files)';
}


}

/// @nodoc
abstract mixin class _$FolderDtoCopyWith<$Res> implements $FolderDtoCopyWith<$Res> {
  factory _$FolderDtoCopyWith(_FolderDto value, $Res Function(_FolderDto) _then) = __$FolderDtoCopyWithImpl;
@override @useResult
$Res call({
 String? id, String? name, String? path, FolderType? type, bool? isHidden, bool? isLocked, String? allowedUsers, DateTime? createdAt, DateTime? updatedAt, String? parentFolderId, String? parentFolderName, List<FolderDto>? subfolders, List<FileDto>? files
});




}
/// @nodoc
class __$FolderDtoCopyWithImpl<$Res>
    implements _$FolderDtoCopyWith<$Res> {
  __$FolderDtoCopyWithImpl(this._self, this._then);

  final _FolderDto _self;
  final $Res Function(_FolderDto) _then;

/// Create a copy of FolderDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = freezed,Object? path = freezed,Object? type = freezed,Object? isHidden = freezed,Object? isLocked = freezed,Object? allowedUsers = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? parentFolderId = freezed,Object? parentFolderName = freezed,Object? subfolders = freezed,Object? files = freezed,}) {
  return _then(_FolderDto(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as FolderType?,isHidden: freezed == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool?,isLocked: freezed == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool?,allowedUsers: freezed == allowedUsers ? _self.allowedUsers : allowedUsers // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,parentFolderId: freezed == parentFolderId ? _self.parentFolderId : parentFolderId // ignore: cast_nullable_to_non_nullable
as String?,parentFolderName: freezed == parentFolderName ? _self.parentFolderName : parentFolderName // ignore: cast_nullable_to_non_nullable
as String?,subfolders: freezed == subfolders ? _self._subfolders : subfolders // ignore: cast_nullable_to_non_nullable
as List<FolderDto>?,files: freezed == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<FileDto>?,
  ));
}


}

// dart format on

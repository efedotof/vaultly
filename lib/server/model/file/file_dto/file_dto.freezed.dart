// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileDto {

 String? get id;// UUID
 String get name; String get originalName; int get size; String get mimeType; String? get s3Url; bool? get isEncrypted; bool? get isPublic;@JsonKey(name: 'createdAt') DateTime? get createdAt; String? get folderId; String? get folderName;
/// Create a copy of FileDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileDtoCopyWith<FileDto> get copyWith => _$FileDtoCopyWithImpl<FileDto>(this as FileDto, _$identity);

  /// Serializes this FileDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.size, size) || other.size == size)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.s3Url, s3Url) || other.s3Url == s3Url)&&(identical(other.isEncrypted, isEncrypted) || other.isEncrypted == isEncrypted)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.folderName, folderName) || other.folderName == folderName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,originalName,size,mimeType,s3Url,isEncrypted,isPublic,createdAt,folderId,folderName);

@override
String toString() {
  return 'FileDto(id: $id, name: $name, originalName: $originalName, size: $size, mimeType: $mimeType, s3Url: $s3Url, isEncrypted: $isEncrypted, isPublic: $isPublic, createdAt: $createdAt, folderId: $folderId, folderName: $folderName)';
}


}

/// @nodoc
abstract mixin class $FileDtoCopyWith<$Res>  {
  factory $FileDtoCopyWith(FileDto value, $Res Function(FileDto) _then) = _$FileDtoCopyWithImpl;
@useResult
$Res call({
 String? id, String name, String originalName, int size, String mimeType, String? s3Url, bool? isEncrypted, bool? isPublic,@JsonKey(name: 'createdAt') DateTime? createdAt, String? folderId, String? folderName
});




}
/// @nodoc
class _$FileDtoCopyWithImpl<$Res>
    implements $FileDtoCopyWith<$Res> {
  _$FileDtoCopyWithImpl(this._self, this._then);

  final FileDto _self;
  final $Res Function(FileDto) _then;

/// Create a copy of FileDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,Object? originalName = null,Object? size = null,Object? mimeType = null,Object? s3Url = freezed,Object? isEncrypted = freezed,Object? isPublic = freezed,Object? createdAt = freezed,Object? folderId = freezed,Object? folderName = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,s3Url: freezed == s3Url ? _self.s3Url : s3Url // ignore: cast_nullable_to_non_nullable
as String?,isEncrypted: freezed == isEncrypted ? _self.isEncrypted : isEncrypted // ignore: cast_nullable_to_non_nullable
as bool?,isPublic: freezed == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,folderName: freezed == folderName ? _self.folderName : folderName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FileDto].
extension FileDtoPatterns on FileDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileDto value)  $default,){
final _that = this;
switch (_that) {
case _FileDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileDto value)?  $default,){
final _that = this;
switch (_that) {
case _FileDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String name,  String originalName,  int size,  String mimeType,  String? s3Url,  bool? isEncrypted,  bool? isPublic, @JsonKey(name: 'createdAt')  DateTime? createdAt,  String? folderId,  String? folderName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileDto() when $default != null:
return $default(_that.id,_that.name,_that.originalName,_that.size,_that.mimeType,_that.s3Url,_that.isEncrypted,_that.isPublic,_that.createdAt,_that.folderId,_that.folderName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String name,  String originalName,  int size,  String mimeType,  String? s3Url,  bool? isEncrypted,  bool? isPublic, @JsonKey(name: 'createdAt')  DateTime? createdAt,  String? folderId,  String? folderName)  $default,) {final _that = this;
switch (_that) {
case _FileDto():
return $default(_that.id,_that.name,_that.originalName,_that.size,_that.mimeType,_that.s3Url,_that.isEncrypted,_that.isPublic,_that.createdAt,_that.folderId,_that.folderName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String name,  String originalName,  int size,  String mimeType,  String? s3Url,  bool? isEncrypted,  bool? isPublic, @JsonKey(name: 'createdAt')  DateTime? createdAt,  String? folderId,  String? folderName)?  $default,) {final _that = this;
switch (_that) {
case _FileDto() when $default != null:
return $default(_that.id,_that.name,_that.originalName,_that.size,_that.mimeType,_that.s3Url,_that.isEncrypted,_that.isPublic,_that.createdAt,_that.folderId,_that.folderName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileDto implements FileDto {
  const _FileDto({this.id, required this.name, required this.originalName, required this.size, required this.mimeType, this.s3Url, this.isEncrypted, this.isPublic, @JsonKey(name: 'createdAt') this.createdAt, this.folderId, this.folderName});
  factory _FileDto.fromJson(Map<String, dynamic> json) => _$FileDtoFromJson(json);

@override final  String? id;
// UUID
@override final  String name;
@override final  String originalName;
@override final  int size;
@override final  String mimeType;
@override final  String? s3Url;
@override final  bool? isEncrypted;
@override final  bool? isPublic;
@override@JsonKey(name: 'createdAt') final  DateTime? createdAt;
@override final  String? folderId;
@override final  String? folderName;

/// Create a copy of FileDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileDtoCopyWith<_FileDto> get copyWith => __$FileDtoCopyWithImpl<_FileDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.size, size) || other.size == size)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.s3Url, s3Url) || other.s3Url == s3Url)&&(identical(other.isEncrypted, isEncrypted) || other.isEncrypted == isEncrypted)&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.folderName, folderName) || other.folderName == folderName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,originalName,size,mimeType,s3Url,isEncrypted,isPublic,createdAt,folderId,folderName);

@override
String toString() {
  return 'FileDto(id: $id, name: $name, originalName: $originalName, size: $size, mimeType: $mimeType, s3Url: $s3Url, isEncrypted: $isEncrypted, isPublic: $isPublic, createdAt: $createdAt, folderId: $folderId, folderName: $folderName)';
}


}

/// @nodoc
abstract mixin class _$FileDtoCopyWith<$Res> implements $FileDtoCopyWith<$Res> {
  factory _$FileDtoCopyWith(_FileDto value, $Res Function(_FileDto) _then) = __$FileDtoCopyWithImpl;
@override @useResult
$Res call({
 String? id, String name, String originalName, int size, String mimeType, String? s3Url, bool? isEncrypted, bool? isPublic,@JsonKey(name: 'createdAt') DateTime? createdAt, String? folderId, String? folderName
});




}
/// @nodoc
class __$FileDtoCopyWithImpl<$Res>
    implements _$FileDtoCopyWith<$Res> {
  __$FileDtoCopyWithImpl(this._self, this._then);

  final _FileDto _self;
  final $Res Function(_FileDto) _then;

/// Create a copy of FileDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,Object? originalName = null,Object? size = null,Object? mimeType = null,Object? s3Url = freezed,Object? isEncrypted = freezed,Object? isPublic = freezed,Object? createdAt = freezed,Object? folderId = freezed,Object? folderName = freezed,}) {
  return _then(_FileDto(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,s3Url: freezed == s3Url ? _self.s3Url : s3Url // ignore: cast_nullable_to_non_nullable
as String?,isEncrypted: freezed == isEncrypted ? _self.isEncrypted : isEncrypted // ignore: cast_nullable_to_non_nullable
as bool?,isPublic: freezed == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,folderName: freezed == folderName ? _self.folderName : folderName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

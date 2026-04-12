// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_upload_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FileUploadRequest {

 http.MultipartFile get file; int? get folderId; bool? get encrypt; String? get encryptionPassword;
/// Create a copy of FileUploadRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileUploadRequestCopyWith<FileUploadRequest> get copyWith => _$FileUploadRequestCopyWithImpl<FileUploadRequest>(this as FileUploadRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileUploadRequest&&(identical(other.file, file) || other.file == file)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.encrypt, encrypt) || other.encrypt == encrypt)&&(identical(other.encryptionPassword, encryptionPassword) || other.encryptionPassword == encryptionPassword));
}


@override
int get hashCode => Object.hash(runtimeType,file,folderId,encrypt,encryptionPassword);

@override
String toString() {
  return 'FileUploadRequest(file: $file, folderId: $folderId, encrypt: $encrypt, encryptionPassword: $encryptionPassword)';
}


}

/// @nodoc
abstract mixin class $FileUploadRequestCopyWith<$Res>  {
  factory $FileUploadRequestCopyWith(FileUploadRequest value, $Res Function(FileUploadRequest) _then) = _$FileUploadRequestCopyWithImpl;
@useResult
$Res call({
 http.MultipartFile file, int? folderId, bool? encrypt, String? encryptionPassword
});




}
/// @nodoc
class _$FileUploadRequestCopyWithImpl<$Res>
    implements $FileUploadRequestCopyWith<$Res> {
  _$FileUploadRequestCopyWithImpl(this._self, this._then);

  final FileUploadRequest _self;
  final $Res Function(FileUploadRequest) _then;

/// Create a copy of FileUploadRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? file = null,Object? folderId = freezed,Object? encrypt = freezed,Object? encryptionPassword = freezed,}) {
  return _then(_self.copyWith(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as http.MultipartFile,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as int?,encrypt: freezed == encrypt ? _self.encrypt : encrypt // ignore: cast_nullable_to_non_nullable
as bool?,encryptionPassword: freezed == encryptionPassword ? _self.encryptionPassword : encryptionPassword // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FileUploadRequest].
extension FileUploadRequestPatterns on FileUploadRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileUploadRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileUploadRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileUploadRequest value)  $default,){
final _that = this;
switch (_that) {
case _FileUploadRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileUploadRequest value)?  $default,){
final _that = this;
switch (_that) {
case _FileUploadRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( http.MultipartFile file,  int? folderId,  bool? encrypt,  String? encryptionPassword)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileUploadRequest() when $default != null:
return $default(_that.file,_that.folderId,_that.encrypt,_that.encryptionPassword);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( http.MultipartFile file,  int? folderId,  bool? encrypt,  String? encryptionPassword)  $default,) {final _that = this;
switch (_that) {
case _FileUploadRequest():
return $default(_that.file,_that.folderId,_that.encrypt,_that.encryptionPassword);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( http.MultipartFile file,  int? folderId,  bool? encrypt,  String? encryptionPassword)?  $default,) {final _that = this;
switch (_that) {
case _FileUploadRequest() when $default != null:
return $default(_that.file,_that.folderId,_that.encrypt,_that.encryptionPassword);case _:
  return null;

}
}

}

/// @nodoc


class _FileUploadRequest implements FileUploadRequest {
  const _FileUploadRequest({required this.file, this.folderId, this.encrypt, this.encryptionPassword});
  

@override final  http.MultipartFile file;
@override final  int? folderId;
@override final  bool? encrypt;
@override final  String? encryptionPassword;

/// Create a copy of FileUploadRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileUploadRequestCopyWith<_FileUploadRequest> get copyWith => __$FileUploadRequestCopyWithImpl<_FileUploadRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileUploadRequest&&(identical(other.file, file) || other.file == file)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.encrypt, encrypt) || other.encrypt == encrypt)&&(identical(other.encryptionPassword, encryptionPassword) || other.encryptionPassword == encryptionPassword));
}


@override
int get hashCode => Object.hash(runtimeType,file,folderId,encrypt,encryptionPassword);

@override
String toString() {
  return 'FileUploadRequest(file: $file, folderId: $folderId, encrypt: $encrypt, encryptionPassword: $encryptionPassword)';
}


}

/// @nodoc
abstract mixin class _$FileUploadRequestCopyWith<$Res> implements $FileUploadRequestCopyWith<$Res> {
  factory _$FileUploadRequestCopyWith(_FileUploadRequest value, $Res Function(_FileUploadRequest) _then) = __$FileUploadRequestCopyWithImpl;
@override @useResult
$Res call({
 http.MultipartFile file, int? folderId, bool? encrypt, String? encryptionPassword
});




}
/// @nodoc
class __$FileUploadRequestCopyWithImpl<$Res>
    implements _$FileUploadRequestCopyWith<$Res> {
  __$FileUploadRequestCopyWithImpl(this._self, this._then);

  final _FileUploadRequest _self;
  final $Res Function(_FileUploadRequest) _then;

/// Create a copy of FileUploadRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? file = null,Object? folderId = freezed,Object? encrypt = freezed,Object? encryptionPassword = freezed,}) {
  return _then(_FileUploadRequest(
file: null == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as http.MultipartFile,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as int?,encrypt: freezed == encrypt ? _self.encrypt : encrypt // ignore: cast_nullable_to_non_nullable
as bool?,encryptionPassword: freezed == encryptionPassword ? _self.encryptionPassword : encryptionPassword // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

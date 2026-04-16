// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FolderState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FolderState()';
}


}

/// @nodoc
class $FolderStateCopyWith<$Res>  {
$FolderStateCopyWith(FolderState _, $Res Function(FolderState) __);
}


/// Adds pattern-matching-related methods to [FolderState].
extension FolderStatePatterns on FolderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Loaded value)?  loaded,TResult Function( _PasswordRequired value)?  passwordRequired,TResult Function( _Error value)?  error,TResult Function( _Deleted value)?  deleted,TResult Function( _Unauthorized value)?  unauthorized,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _PasswordRequired() when passwordRequired != null:
return passwordRequired(_that);case _Error() when error != null:
return error(_that);case _Deleted() when deleted != null:
return deleted(_that);case _Unauthorized() when unauthorized != null:
return unauthorized(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Loaded value)  loaded,required TResult Function( _PasswordRequired value)  passwordRequired,required TResult Function( _Error value)  error,required TResult Function( _Deleted value)  deleted,required TResult Function( _Unauthorized value)  unauthorized,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Loaded():
return loaded(_that);case _PasswordRequired():
return passwordRequired(_that);case _Error():
return error(_that);case _Deleted():
return deleted(_that);case _Unauthorized():
return unauthorized(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Loaded value)?  loaded,TResult? Function( _PasswordRequired value)?  passwordRequired,TResult? Function( _Error value)?  error,TResult? Function( _Deleted value)?  deleted,TResult? Function( _Unauthorized value)?  unauthorized,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _PasswordRequired() when passwordRequired != null:
return passwordRequired(_that);case _Error() when error != null:
return error(_that);case _Deleted() when deleted != null:
return deleted(_that);case _Unauthorized() when unauthorized != null:
return unauthorized(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( String folderId,  List<FileDto> files,  FolderDto? folder)?  loaded,TResult Function( String folderId,  FolderDto? folder,  String? errorMessage)?  passwordRequired,TResult Function( String message)?  error,TResult Function()?  deleted,TResult Function()?  unauthorized,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.folderId,_that.files,_that.folder);case _PasswordRequired() when passwordRequired != null:
return passwordRequired(_that.folderId,_that.folder,_that.errorMessage);case _Error() when error != null:
return error(_that.message);case _Deleted() when deleted != null:
return deleted();case _Unauthorized() when unauthorized != null:
return unauthorized();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( String folderId,  List<FileDto> files,  FolderDto? folder)  loaded,required TResult Function( String folderId,  FolderDto? folder,  String? errorMessage)  passwordRequired,required TResult Function( String message)  error,required TResult Function()  deleted,required TResult Function()  unauthorized,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.folderId,_that.files,_that.folder);case _PasswordRequired():
return passwordRequired(_that.folderId,_that.folder,_that.errorMessage);case _Error():
return error(_that.message);case _Deleted():
return deleted();case _Unauthorized():
return unauthorized();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( String folderId,  List<FileDto> files,  FolderDto? folder)?  loaded,TResult? Function( String folderId,  FolderDto? folder,  String? errorMessage)?  passwordRequired,TResult? Function( String message)?  error,TResult? Function()?  deleted,TResult? Function()?  unauthorized,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.folderId,_that.files,_that.folder);case _PasswordRequired() when passwordRequired != null:
return passwordRequired(_that.folderId,_that.folder,_that.errorMessage);case _Error() when error != null:
return error(_that.message);case _Deleted() when deleted != null:
return deleted();case _Unauthorized() when unauthorized != null:
return unauthorized();case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements FolderState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FolderState.initial()';
}


}




/// @nodoc


class _Loading implements FolderState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FolderState.loading()';
}


}




/// @nodoc


class _Loaded implements FolderState {
  const _Loaded({required this.folderId, required final  List<FileDto> files, this.folder}): _files = files;
  

 final  String folderId;
 final  List<FileDto> _files;
 List<FileDto> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}

 final  FolderDto? folder;

/// Create a copy of FolderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&(identical(other.folderId, folderId) || other.folderId == folderId)&&const DeepCollectionEquality().equals(other._files, _files)&&(identical(other.folder, folder) || other.folder == folder));
}


@override
int get hashCode => Object.hash(runtimeType,folderId,const DeepCollectionEquality().hash(_files),folder);

@override
String toString() {
  return 'FolderState.loaded(folderId: $folderId, files: $files, folder: $folder)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $FolderStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 String folderId, List<FileDto> files, FolderDto? folder
});


$FolderDtoCopyWith<$Res>? get folder;

}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of FolderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? folderId = null,Object? files = null,Object? folder = freezed,}) {
  return _then(_Loaded(
folderId: null == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<FileDto>,folder: freezed == folder ? _self.folder : folder // ignore: cast_nullable_to_non_nullable
as FolderDto?,
  ));
}

/// Create a copy of FolderState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FolderDtoCopyWith<$Res>? get folder {
    if (_self.folder == null) {
    return null;
  }

  return $FolderDtoCopyWith<$Res>(_self.folder!, (value) {
    return _then(_self.copyWith(folder: value));
  });
}
}

/// @nodoc


class _PasswordRequired implements FolderState {
  const _PasswordRequired({required this.folderId, this.folder, this.errorMessage});
  

 final  String folderId;
 final  FolderDto? folder;
 final  String? errorMessage;

/// Create a copy of FolderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PasswordRequiredCopyWith<_PasswordRequired> get copyWith => __$PasswordRequiredCopyWithImpl<_PasswordRequired>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PasswordRequired&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.folder, folder) || other.folder == folder)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,folderId,folder,errorMessage);

@override
String toString() {
  return 'FolderState.passwordRequired(folderId: $folderId, folder: $folder, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$PasswordRequiredCopyWith<$Res> implements $FolderStateCopyWith<$Res> {
  factory _$PasswordRequiredCopyWith(_PasswordRequired value, $Res Function(_PasswordRequired) _then) = __$PasswordRequiredCopyWithImpl;
@useResult
$Res call({
 String folderId, FolderDto? folder, String? errorMessage
});


$FolderDtoCopyWith<$Res>? get folder;

}
/// @nodoc
class __$PasswordRequiredCopyWithImpl<$Res>
    implements _$PasswordRequiredCopyWith<$Res> {
  __$PasswordRequiredCopyWithImpl(this._self, this._then);

  final _PasswordRequired _self;
  final $Res Function(_PasswordRequired) _then;

/// Create a copy of FolderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? folderId = null,Object? folder = freezed,Object? errorMessage = freezed,}) {
  return _then(_PasswordRequired(
folderId: null == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String,folder: freezed == folder ? _self.folder : folder // ignore: cast_nullable_to_non_nullable
as FolderDto?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of FolderState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FolderDtoCopyWith<$Res>? get folder {
    if (_self.folder == null) {
    return null;
  }

  return $FolderDtoCopyWith<$Res>(_self.folder!, (value) {
    return _then(_self.copyWith(folder: value));
  });
}
}

/// @nodoc


class _Error implements FolderState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of FolderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'FolderState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $FolderStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of FolderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Deleted implements FolderState {
  const _Deleted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Deleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FolderState.deleted()';
}


}




/// @nodoc


class _Unauthorized implements FolderState {
  const _Unauthorized();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Unauthorized);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FolderState.unauthorized()';
}


}




// dart format on

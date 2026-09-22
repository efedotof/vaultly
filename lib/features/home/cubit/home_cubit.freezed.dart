// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState()';
}


}

/// @nodoc
class $HomeStateCopyWith<$Res>  {
$HomeStateCopyWith(HomeState _, $Res Function(HomeState) __);
}


/// Adds pattern-matching-related methods to [HomeState].
extension HomeStatePatterns on HomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Loaded value)?  loaded,TResult Function( _Error value)?  error,TResult Function( _CreatingFolder value)?  creatingFolder,TResult Function( _UpdatingFolder value)?  updatingFolder,TResult Function( _DeletingFolder value)?  deletingFolder,TResult Function( _FolderError value)?  folderError,TResult Function( _DeletingFile value)?  deletingFile,TResult Function( _FileDeleteError value)?  fileDeleteError,TResult Function( _AddingFileToFolder value)?  addingFileToFolder,TResult Function( _AddFileError value)?  addFileError,TResult Function( _Unauthorized value)?  unauthorized,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _CreatingFolder() when creatingFolder != null:
return creatingFolder(_that);case _UpdatingFolder() when updatingFolder != null:
return updatingFolder(_that);case _DeletingFolder() when deletingFolder != null:
return deletingFolder(_that);case _FolderError() when folderError != null:
return folderError(_that);case _DeletingFile() when deletingFile != null:
return deletingFile(_that);case _FileDeleteError() when fileDeleteError != null:
return fileDeleteError(_that);case _AddingFileToFolder() when addingFileToFolder != null:
return addingFileToFolder(_that);case _AddFileError() when addFileError != null:
return addFileError(_that);case _Unauthorized() when unauthorized != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Loaded value)  loaded,required TResult Function( _Error value)  error,required TResult Function( _CreatingFolder value)  creatingFolder,required TResult Function( _UpdatingFolder value)  updatingFolder,required TResult Function( _DeletingFolder value)  deletingFolder,required TResult Function( _FolderError value)  folderError,required TResult Function( _DeletingFile value)  deletingFile,required TResult Function( _FileDeleteError value)  fileDeleteError,required TResult Function( _AddingFileToFolder value)  addingFileToFolder,required TResult Function( _AddFileError value)  addFileError,required TResult Function( _Unauthorized value)  unauthorized,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Loaded():
return loaded(_that);case _Error():
return error(_that);case _CreatingFolder():
return creatingFolder(_that);case _UpdatingFolder():
return updatingFolder(_that);case _DeletingFolder():
return deletingFolder(_that);case _FolderError():
return folderError(_that);case _DeletingFile():
return deletingFile(_that);case _FileDeleteError():
return fileDeleteError(_that);case _AddingFileToFolder():
return addingFileToFolder(_that);case _AddFileError():
return addFileError(_that);case _Unauthorized():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Loaded value)?  loaded,TResult? Function( _Error value)?  error,TResult? Function( _CreatingFolder value)?  creatingFolder,TResult? Function( _UpdatingFolder value)?  updatingFolder,TResult? Function( _DeletingFolder value)?  deletingFolder,TResult? Function( _FolderError value)?  folderError,TResult? Function( _DeletingFile value)?  deletingFile,TResult? Function( _FileDeleteError value)?  fileDeleteError,TResult? Function( _AddingFileToFolder value)?  addingFileToFolder,TResult? Function( _AddFileError value)?  addFileError,TResult? Function( _Unauthorized value)?  unauthorized,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _CreatingFolder() when creatingFolder != null:
return creatingFolder(_that);case _UpdatingFolder() when updatingFolder != null:
return updatingFolder(_that);case _DeletingFolder() when deletingFolder != null:
return deletingFolder(_that);case _FolderError() when folderError != null:
return folderError(_that);case _DeletingFile() when deletingFile != null:
return deletingFile(_that);case _FileDeleteError() when fileDeleteError != null:
return fileDeleteError(_that);case _AddingFileToFolder() when addingFileToFolder != null:
return addingFileToFolder(_that);case _AddFileError() when addFileError != null:
return addFileError(_that);case _Unauthorized() when unauthorized != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<FolderDto> folders,  List<FileDto> recentFiles,  List<FileDto> allFiles,  List<FileDto>? cachedFiles)?  loaded,TResult Function( String message)?  error,TResult Function()?  creatingFolder,TResult Function()?  updatingFolder,TResult Function()?  deletingFolder,TResult Function( String message)?  folderError,TResult Function()?  deletingFile,TResult Function( String message)?  fileDeleteError,TResult Function()?  addingFileToFolder,TResult Function( String message)?  addFileError,TResult Function()?  unauthorized,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.folders,_that.recentFiles,_that.allFiles,_that.cachedFiles);case _Error() when error != null:
return error(_that.message);case _CreatingFolder() when creatingFolder != null:
return creatingFolder();case _UpdatingFolder() when updatingFolder != null:
return updatingFolder();case _DeletingFolder() when deletingFolder != null:
return deletingFolder();case _FolderError() when folderError != null:
return folderError(_that.message);case _DeletingFile() when deletingFile != null:
return deletingFile();case _FileDeleteError() when fileDeleteError != null:
return fileDeleteError(_that.message);case _AddingFileToFolder() when addingFileToFolder != null:
return addingFileToFolder();case _AddFileError() when addFileError != null:
return addFileError(_that.message);case _Unauthorized() when unauthorized != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<FolderDto> folders,  List<FileDto> recentFiles,  List<FileDto> allFiles,  List<FileDto>? cachedFiles)  loaded,required TResult Function( String message)  error,required TResult Function()  creatingFolder,required TResult Function()  updatingFolder,required TResult Function()  deletingFolder,required TResult Function( String message)  folderError,required TResult Function()  deletingFile,required TResult Function( String message)  fileDeleteError,required TResult Function()  addingFileToFolder,required TResult Function( String message)  addFileError,required TResult Function()  unauthorized,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.folders,_that.recentFiles,_that.allFiles,_that.cachedFiles);case _Error():
return error(_that.message);case _CreatingFolder():
return creatingFolder();case _UpdatingFolder():
return updatingFolder();case _DeletingFolder():
return deletingFolder();case _FolderError():
return folderError(_that.message);case _DeletingFile():
return deletingFile();case _FileDeleteError():
return fileDeleteError(_that.message);case _AddingFileToFolder():
return addingFileToFolder();case _AddFileError():
return addFileError(_that.message);case _Unauthorized():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<FolderDto> folders,  List<FileDto> recentFiles,  List<FileDto> allFiles,  List<FileDto>? cachedFiles)?  loaded,TResult? Function( String message)?  error,TResult? Function()?  creatingFolder,TResult? Function()?  updatingFolder,TResult? Function()?  deletingFolder,TResult? Function( String message)?  folderError,TResult? Function()?  deletingFile,TResult? Function( String message)?  fileDeleteError,TResult? Function()?  addingFileToFolder,TResult? Function( String message)?  addFileError,TResult? Function()?  unauthorized,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.folders,_that.recentFiles,_that.allFiles,_that.cachedFiles);case _Error() when error != null:
return error(_that.message);case _CreatingFolder() when creatingFolder != null:
return creatingFolder();case _UpdatingFolder() when updatingFolder != null:
return updatingFolder();case _DeletingFolder() when deletingFolder != null:
return deletingFolder();case _FolderError() when folderError != null:
return folderError(_that.message);case _DeletingFile() when deletingFile != null:
return deletingFile();case _FileDeleteError() when fileDeleteError != null:
return fileDeleteError(_that.message);case _AddingFileToFolder() when addingFileToFolder != null:
return addingFileToFolder();case _AddFileError() when addFileError != null:
return addFileError(_that.message);case _Unauthorized() when unauthorized != null:
return unauthorized();case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements HomeState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState.initial()';
}


}




/// @nodoc


class _Loading implements HomeState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState.loading()';
}


}




/// @nodoc


class _Loaded implements HomeState {
  const _Loaded({required final  List<FolderDto> folders, required final  List<FileDto> recentFiles, required final  List<FileDto> allFiles, final  List<FileDto>? cachedFiles}): _folders = folders,_recentFiles = recentFiles,_allFiles = allFiles,_cachedFiles = cachedFiles;
  

 final  List<FolderDto> _folders;
 List<FolderDto> get folders {
  if (_folders is EqualUnmodifiableListView) return _folders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_folders);
}

 final  List<FileDto> _recentFiles;
 List<FileDto> get recentFiles {
  if (_recentFiles is EqualUnmodifiableListView) return _recentFiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentFiles);
}

 final  List<FileDto> _allFiles;
 List<FileDto> get allFiles {
  if (_allFiles is EqualUnmodifiableListView) return _allFiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allFiles);
}

 final  List<FileDto>? _cachedFiles;
 List<FileDto>? get cachedFiles {
  final value = _cachedFiles;
  if (value == null) return null;
  if (_cachedFiles is EqualUnmodifiableListView) return _cachedFiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other._folders, _folders)&&const DeepCollectionEquality().equals(other._recentFiles, _recentFiles)&&const DeepCollectionEquality().equals(other._allFiles, _allFiles)&&const DeepCollectionEquality().equals(other._cachedFiles, _cachedFiles));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_folders),const DeepCollectionEquality().hash(_recentFiles),const DeepCollectionEquality().hash(_allFiles),const DeepCollectionEquality().hash(_cachedFiles));

@override
String toString() {
  return 'HomeState.loaded(folders: $folders, recentFiles: $recentFiles, allFiles: $allFiles, cachedFiles: $cachedFiles)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<FolderDto> folders, List<FileDto> recentFiles, List<FileDto> allFiles, List<FileDto>? cachedFiles
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? folders = null,Object? recentFiles = null,Object? allFiles = null,Object? cachedFiles = freezed,}) {
  return _then(_Loaded(
folders: null == folders ? _self._folders : folders // ignore: cast_nullable_to_non_nullable
as List<FolderDto>,recentFiles: null == recentFiles ? _self._recentFiles : recentFiles // ignore: cast_nullable_to_non_nullable
as List<FileDto>,allFiles: null == allFiles ? _self._allFiles : allFiles // ignore: cast_nullable_to_non_nullable
as List<FileDto>,cachedFiles: freezed == cachedFiles ? _self._cachedFiles : cachedFiles // ignore: cast_nullable_to_non_nullable
as List<FileDto>?,
  ));
}


}

/// @nodoc


class _Error implements HomeState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of HomeState
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
  return 'HomeState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
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

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _CreatingFolder implements HomeState {
  const _CreatingFolder();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatingFolder);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState.creatingFolder()';
}


}




/// @nodoc


class _UpdatingFolder implements HomeState {
  const _UpdatingFolder();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdatingFolder);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState.updatingFolder()';
}


}




/// @nodoc


class _DeletingFolder implements HomeState {
  const _DeletingFolder();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeletingFolder);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState.deletingFolder()';
}


}




/// @nodoc


class _FolderError implements HomeState {
  const _FolderError(this.message);
  

 final  String message;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FolderErrorCopyWith<_FolderError> get copyWith => __$FolderErrorCopyWithImpl<_FolderError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FolderError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'HomeState.folderError(message: $message)';
}


}

/// @nodoc
abstract mixin class _$FolderErrorCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory _$FolderErrorCopyWith(_FolderError value, $Res Function(_FolderError) _then) = __$FolderErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$FolderErrorCopyWithImpl<$Res>
    implements _$FolderErrorCopyWith<$Res> {
  __$FolderErrorCopyWithImpl(this._self, this._then);

  final _FolderError _self;
  final $Res Function(_FolderError) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_FolderError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _DeletingFile implements HomeState {
  const _DeletingFile();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeletingFile);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState.deletingFile()';
}


}




/// @nodoc


class _FileDeleteError implements HomeState {
  const _FileDeleteError(this.message);
  

 final  String message;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileDeleteErrorCopyWith<_FileDeleteError> get copyWith => __$FileDeleteErrorCopyWithImpl<_FileDeleteError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileDeleteError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'HomeState.fileDeleteError(message: $message)';
}


}

/// @nodoc
abstract mixin class _$FileDeleteErrorCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory _$FileDeleteErrorCopyWith(_FileDeleteError value, $Res Function(_FileDeleteError) _then) = __$FileDeleteErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$FileDeleteErrorCopyWithImpl<$Res>
    implements _$FileDeleteErrorCopyWith<$Res> {
  __$FileDeleteErrorCopyWithImpl(this._self, this._then);

  final _FileDeleteError _self;
  final $Res Function(_FileDeleteError) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_FileDeleteError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _AddingFileToFolder implements HomeState {
  const _AddingFileToFolder();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddingFileToFolder);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState.addingFileToFolder()';
}


}




/// @nodoc


class _AddFileError implements HomeState {
  const _AddFileError(this.message);
  

 final  String message;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddFileErrorCopyWith<_AddFileError> get copyWith => __$AddFileErrorCopyWithImpl<_AddFileError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddFileError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'HomeState.addFileError(message: $message)';
}


}

/// @nodoc
abstract mixin class _$AddFileErrorCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory _$AddFileErrorCopyWith(_AddFileError value, $Res Function(_AddFileError) _then) = __$AddFileErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$AddFileErrorCopyWithImpl<$Res>
    implements _$AddFileErrorCopyWith<$Res> {
  __$AddFileErrorCopyWithImpl(this._self, this._then);

  final _AddFileError _self;
  final $Res Function(_AddFileError) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_AddFileError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Unauthorized implements HomeState {
  const _Unauthorized();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Unauthorized);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState.unauthorized()';
}


}




// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_upload_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FileUploadState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileUploadState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FileUploadState()';
}


}

/// @nodoc
class $FileUploadStateCopyWith<$Res>  {
$FileUploadStateCopyWith(FileUploadState _, $Res Function(FileUploadState) __);
}


/// Adds pattern-matching-related methods to [FileUploadState].
extension FileUploadStatePatterns on FileUploadState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Uploading value)?  uploading,TResult Function( _UploadError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Uploading() when uploading != null:
return uploading(_that);case _UploadError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Uploading value)  uploading,required TResult Function( _UploadError value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Uploading():
return uploading(_that);case _UploadError():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Uploading value)?  uploading,TResult? Function( _UploadError value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Uploading() when uploading != null:
return uploading(_that);case _UploadError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( List<UploadTask> tasks)?  uploading,TResult Function( String message,  List<UploadTask> tasks)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Uploading() when uploading != null:
return uploading(_that.tasks);case _UploadError() when error != null:
return error(_that.message,_that.tasks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( List<UploadTask> tasks)  uploading,required TResult Function( String message,  List<UploadTask> tasks)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Uploading():
return uploading(_that.tasks);case _UploadError():
return error(_that.message,_that.tasks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( List<UploadTask> tasks)?  uploading,TResult? Function( String message,  List<UploadTask> tasks)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Uploading() when uploading != null:
return uploading(_that.tasks);case _UploadError() when error != null:
return error(_that.message,_that.tasks);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements FileUploadState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FileUploadState.initial()';
}


}




/// @nodoc


class _Uploading implements FileUploadState {
  const _Uploading({final  List<UploadTask> tasks = const []}): _tasks = tasks;
  

 final  List<UploadTask> _tasks;
@JsonKey() List<UploadTask> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}


/// Create a copy of FileUploadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadingCopyWith<_Uploading> get copyWith => __$UploadingCopyWithImpl<_Uploading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Uploading&&const DeepCollectionEquality().equals(other._tasks, _tasks));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tasks));

@override
String toString() {
  return 'FileUploadState.uploading(tasks: $tasks)';
}


}

/// @nodoc
abstract mixin class _$UploadingCopyWith<$Res> implements $FileUploadStateCopyWith<$Res> {
  factory _$UploadingCopyWith(_Uploading value, $Res Function(_Uploading) _then) = __$UploadingCopyWithImpl;
@useResult
$Res call({
 List<UploadTask> tasks
});




}
/// @nodoc
class __$UploadingCopyWithImpl<$Res>
    implements _$UploadingCopyWith<$Res> {
  __$UploadingCopyWithImpl(this._self, this._then);

  final _Uploading _self;
  final $Res Function(_Uploading) _then;

/// Create a copy of FileUploadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tasks = null,}) {
  return _then(_Uploading(
tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<UploadTask>,
  ));
}


}

/// @nodoc


class _UploadError implements FileUploadState {
  const _UploadError({required this.message, final  List<UploadTask> tasks = const []}): _tasks = tasks;
  

 final  String message;
 final  List<UploadTask> _tasks;
@JsonKey() List<UploadTask> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}


/// Create a copy of FileUploadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadErrorCopyWith<_UploadError> get copyWith => __$UploadErrorCopyWithImpl<_UploadError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadError&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._tasks, _tasks));
}


@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(_tasks));

@override
String toString() {
  return 'FileUploadState.error(message: $message, tasks: $tasks)';
}


}

/// @nodoc
abstract mixin class _$UploadErrorCopyWith<$Res> implements $FileUploadStateCopyWith<$Res> {
  factory _$UploadErrorCopyWith(_UploadError value, $Res Function(_UploadError) _then) = __$UploadErrorCopyWithImpl;
@useResult
$Res call({
 String message, List<UploadTask> tasks
});




}
/// @nodoc
class __$UploadErrorCopyWithImpl<$Res>
    implements _$UploadErrorCopyWith<$Res> {
  __$UploadErrorCopyWithImpl(this._self, this._then);

  final _UploadError _self;
  final $Res Function(_UploadError) _then;

/// Create a copy of FileUploadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? tasks = null,}) {
  return _then(_UploadError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<UploadTask>,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'upload_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UploadTask {

 String get id;// уникальный идентификатор задачи
 String get fileName; UploadStatus get status; double get progress;// от 0.0 до 1.0
 String? get errorMessage; String? get folderId;
/// Create a copy of UploadTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UploadTaskCopyWith<UploadTask> get copyWith => _$UploadTaskCopyWithImpl<UploadTask>(this as UploadTask, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UploadTask&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.folderId, folderId) || other.folderId == folderId));
}


@override
int get hashCode => Object.hash(runtimeType,id,fileName,status,progress,errorMessage,folderId);

@override
String toString() {
  return 'UploadTask(id: $id, fileName: $fileName, status: $status, progress: $progress, errorMessage: $errorMessage, folderId: $folderId)';
}


}

/// @nodoc
abstract mixin class $UploadTaskCopyWith<$Res>  {
  factory $UploadTaskCopyWith(UploadTask value, $Res Function(UploadTask) _then) = _$UploadTaskCopyWithImpl;
@useResult
$Res call({
 String id, String fileName, UploadStatus status, double progress, String? errorMessage, String? folderId
});




}
/// @nodoc
class _$UploadTaskCopyWithImpl<$Res>
    implements $UploadTaskCopyWith<$Res> {
  _$UploadTaskCopyWithImpl(this._self, this._then);

  final UploadTask _self;
  final $Res Function(UploadTask) _then;

/// Create a copy of UploadTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fileName = null,Object? status = null,Object? progress = null,Object? errorMessage = freezed,Object? folderId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UploadStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UploadTask].
extension UploadTaskPatterns on UploadTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UploadTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UploadTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UploadTask value)  $default,){
final _that = this;
switch (_that) {
case _UploadTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UploadTask value)?  $default,){
final _that = this;
switch (_that) {
case _UploadTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fileName,  UploadStatus status,  double progress,  String? errorMessage,  String? folderId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UploadTask() when $default != null:
return $default(_that.id,_that.fileName,_that.status,_that.progress,_that.errorMessage,_that.folderId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fileName,  UploadStatus status,  double progress,  String? errorMessage,  String? folderId)  $default,) {final _that = this;
switch (_that) {
case _UploadTask():
return $default(_that.id,_that.fileName,_that.status,_that.progress,_that.errorMessage,_that.folderId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fileName,  UploadStatus status,  double progress,  String? errorMessage,  String? folderId)?  $default,) {final _that = this;
switch (_that) {
case _UploadTask() when $default != null:
return $default(_that.id,_that.fileName,_that.status,_that.progress,_that.errorMessage,_that.folderId);case _:
  return null;

}
}

}

/// @nodoc


class _UploadTask implements UploadTask {
  const _UploadTask({required this.id, required this.fileName, this.status = UploadStatus.idle, this.progress = 0.0, this.errorMessage, this.folderId});
  

@override final  String id;
// уникальный идентификатор задачи
@override final  String fileName;
@override@JsonKey() final  UploadStatus status;
@override@JsonKey() final  double progress;
// от 0.0 до 1.0
@override final  String? errorMessage;
@override final  String? folderId;

/// Create a copy of UploadTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadTaskCopyWith<_UploadTask> get copyWith => __$UploadTaskCopyWithImpl<_UploadTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadTask&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.folderId, folderId) || other.folderId == folderId));
}


@override
int get hashCode => Object.hash(runtimeType,id,fileName,status,progress,errorMessage,folderId);

@override
String toString() {
  return 'UploadTask(id: $id, fileName: $fileName, status: $status, progress: $progress, errorMessage: $errorMessage, folderId: $folderId)';
}


}

/// @nodoc
abstract mixin class _$UploadTaskCopyWith<$Res> implements $UploadTaskCopyWith<$Res> {
  factory _$UploadTaskCopyWith(_UploadTask value, $Res Function(_UploadTask) _then) = __$UploadTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String fileName, UploadStatus status, double progress, String? errorMessage, String? folderId
});




}
/// @nodoc
class __$UploadTaskCopyWithImpl<$Res>
    implements _$UploadTaskCopyWith<$Res> {
  __$UploadTaskCopyWithImpl(this._self, this._then);

  final _UploadTask _self;
  final $Res Function(_UploadTask) _then;

/// Create a copy of UploadTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fileName = null,Object? status = null,Object? progress = null,Object? errorMessage = freezed,Object? folderId = freezed,}) {
  return _then(_UploadTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UploadStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

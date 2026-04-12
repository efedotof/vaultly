// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_file_to_folder_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AddFileToFolderRequest {

 String get fileId;
/// Create a copy of AddFileToFolderRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddFileToFolderRequestCopyWith<AddFileToFolderRequest> get copyWith => _$AddFileToFolderRequestCopyWithImpl<AddFileToFolderRequest>(this as AddFileToFolderRequest, _$identity);

  /// Serializes this AddFileToFolderRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddFileToFolderRequest&&(identical(other.fileId, fileId) || other.fileId == fileId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileId);

@override
String toString() {
  return 'AddFileToFolderRequest(fileId: $fileId)';
}


}

/// @nodoc
abstract mixin class $AddFileToFolderRequestCopyWith<$Res>  {
  factory $AddFileToFolderRequestCopyWith(AddFileToFolderRequest value, $Res Function(AddFileToFolderRequest) _then) = _$AddFileToFolderRequestCopyWithImpl;
@useResult
$Res call({
 String fileId
});




}
/// @nodoc
class _$AddFileToFolderRequestCopyWithImpl<$Res>
    implements $AddFileToFolderRequestCopyWith<$Res> {
  _$AddFileToFolderRequestCopyWithImpl(this._self, this._then);

  final AddFileToFolderRequest _self;
  final $Res Function(AddFileToFolderRequest) _then;

/// Create a copy of AddFileToFolderRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileId = null,}) {
  return _then(_self.copyWith(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AddFileToFolderRequest].
extension AddFileToFolderRequestPatterns on AddFileToFolderRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddFileToFolderRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddFileToFolderRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddFileToFolderRequest value)  $default,){
final _that = this;
switch (_that) {
case _AddFileToFolderRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddFileToFolderRequest value)?  $default,){
final _that = this;
switch (_that) {
case _AddFileToFolderRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddFileToFolderRequest() when $default != null:
return $default(_that.fileId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileId)  $default,) {final _that = this;
switch (_that) {
case _AddFileToFolderRequest():
return $default(_that.fileId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileId)?  $default,) {final _that = this;
switch (_that) {
case _AddFileToFolderRequest() when $default != null:
return $default(_that.fileId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AddFileToFolderRequest implements AddFileToFolderRequest {
  const _AddFileToFolderRequest({required this.fileId});
  factory _AddFileToFolderRequest.fromJson(Map<String, dynamic> json) => _$AddFileToFolderRequestFromJson(json);

@override final  String fileId;

/// Create a copy of AddFileToFolderRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddFileToFolderRequestCopyWith<_AddFileToFolderRequest> get copyWith => __$AddFileToFolderRequestCopyWithImpl<_AddFileToFolderRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AddFileToFolderRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddFileToFolderRequest&&(identical(other.fileId, fileId) || other.fileId == fileId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileId);

@override
String toString() {
  return 'AddFileToFolderRequest(fileId: $fileId)';
}


}

/// @nodoc
abstract mixin class _$AddFileToFolderRequestCopyWith<$Res> implements $AddFileToFolderRequestCopyWith<$Res> {
  factory _$AddFileToFolderRequestCopyWith(_AddFileToFolderRequest value, $Res Function(_AddFileToFolderRequest) _then) = __$AddFileToFolderRequestCopyWithImpl;
@override @useResult
$Res call({
 String fileId
});




}
/// @nodoc
class __$AddFileToFolderRequestCopyWithImpl<$Res>
    implements _$AddFileToFolderRequestCopyWith<$Res> {
  __$AddFileToFolderRequestCopyWithImpl(this._self, this._then);

  final _AddFileToFolderRequest _self;
  final $Res Function(_AddFileToFolderRequest) _then;

/// Create a copy of AddFileToFolderRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileId = null,}) {
  return _then(_AddFileToFolderRequest(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

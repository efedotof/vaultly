// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_access_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileAccessRequest {

 bool? get isPublic;
/// Create a copy of FileAccessRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileAccessRequestCopyWith<FileAccessRequest> get copyWith => _$FileAccessRequestCopyWithImpl<FileAccessRequest>(this as FileAccessRequest, _$identity);

  /// Serializes this FileAccessRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileAccessRequest&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isPublic);

@override
String toString() {
  return 'FileAccessRequest(isPublic: $isPublic)';
}


}

/// @nodoc
abstract mixin class $FileAccessRequestCopyWith<$Res>  {
  factory $FileAccessRequestCopyWith(FileAccessRequest value, $Res Function(FileAccessRequest) _then) = _$FileAccessRequestCopyWithImpl;
@useResult
$Res call({
 bool? isPublic
});




}
/// @nodoc
class _$FileAccessRequestCopyWithImpl<$Res>
    implements $FileAccessRequestCopyWith<$Res> {
  _$FileAccessRequestCopyWithImpl(this._self, this._then);

  final FileAccessRequest _self;
  final $Res Function(FileAccessRequest) _then;

/// Create a copy of FileAccessRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isPublic = freezed,}) {
  return _then(_self.copyWith(
isPublic: freezed == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [FileAccessRequest].
extension FileAccessRequestPatterns on FileAccessRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileAccessRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileAccessRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileAccessRequest value)  $default,){
final _that = this;
switch (_that) {
case _FileAccessRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileAccessRequest value)?  $default,){
final _that = this;
switch (_that) {
case _FileAccessRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? isPublic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileAccessRequest() when $default != null:
return $default(_that.isPublic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? isPublic)  $default,) {final _that = this;
switch (_that) {
case _FileAccessRequest():
return $default(_that.isPublic);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? isPublic)?  $default,) {final _that = this;
switch (_that) {
case _FileAccessRequest() when $default != null:
return $default(_that.isPublic);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileAccessRequest implements FileAccessRequest {
  const _FileAccessRequest({this.isPublic});
  factory _FileAccessRequest.fromJson(Map<String, dynamic> json) => _$FileAccessRequestFromJson(json);

@override final  bool? isPublic;

/// Create a copy of FileAccessRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileAccessRequestCopyWith<_FileAccessRequest> get copyWith => __$FileAccessRequestCopyWithImpl<_FileAccessRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileAccessRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileAccessRequest&&(identical(other.isPublic, isPublic) || other.isPublic == isPublic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isPublic);

@override
String toString() {
  return 'FileAccessRequest(isPublic: $isPublic)';
}


}

/// @nodoc
abstract mixin class _$FileAccessRequestCopyWith<$Res> implements $FileAccessRequestCopyWith<$Res> {
  factory _$FileAccessRequestCopyWith(_FileAccessRequest value, $Res Function(_FileAccessRequest) _then) = __$FileAccessRequestCopyWithImpl;
@override @useResult
$Res call({
 bool? isPublic
});




}
/// @nodoc
class __$FileAccessRequestCopyWithImpl<$Res>
    implements _$FileAccessRequestCopyWith<$Res> {
  __$FileAccessRequestCopyWithImpl(this._self, this._then);

  final _FileAccessRequest _self;
  final $Res Function(_FileAccessRequest) _then;

/// Create a copy of FileAccessRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isPublic = freezed,}) {
  return _then(_FileAccessRequest(
isPublic: freezed == isPublic ? _self.isPublic : isPublic // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on

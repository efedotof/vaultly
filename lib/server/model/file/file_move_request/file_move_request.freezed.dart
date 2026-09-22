// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_move_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileMoveRequest {

 int? get targetFolderId;
/// Create a copy of FileMoveRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileMoveRequestCopyWith<FileMoveRequest> get copyWith => _$FileMoveRequestCopyWithImpl<FileMoveRequest>(this as FileMoveRequest, _$identity);

  /// Serializes this FileMoveRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileMoveRequest&&(identical(other.targetFolderId, targetFolderId) || other.targetFolderId == targetFolderId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetFolderId);

@override
String toString() {
  return 'FileMoveRequest(targetFolderId: $targetFolderId)';
}


}

/// @nodoc
abstract mixin class $FileMoveRequestCopyWith<$Res>  {
  factory $FileMoveRequestCopyWith(FileMoveRequest value, $Res Function(FileMoveRequest) _then) = _$FileMoveRequestCopyWithImpl;
@useResult
$Res call({
 int? targetFolderId
});




}
/// @nodoc
class _$FileMoveRequestCopyWithImpl<$Res>
    implements $FileMoveRequestCopyWith<$Res> {
  _$FileMoveRequestCopyWithImpl(this._self, this._then);

  final FileMoveRequest _self;
  final $Res Function(FileMoveRequest) _then;

/// Create a copy of FileMoveRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? targetFolderId = freezed,}) {
  return _then(_self.copyWith(
targetFolderId: freezed == targetFolderId ? _self.targetFolderId : targetFolderId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [FileMoveRequest].
extension FileMoveRequestPatterns on FileMoveRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileMoveRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileMoveRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileMoveRequest value)  $default,){
final _that = this;
switch (_that) {
case _FileMoveRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileMoveRequest value)?  $default,){
final _that = this;
switch (_that) {
case _FileMoveRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? targetFolderId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileMoveRequest() when $default != null:
return $default(_that.targetFolderId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? targetFolderId)  $default,) {final _that = this;
switch (_that) {
case _FileMoveRequest():
return $default(_that.targetFolderId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? targetFolderId)?  $default,) {final _that = this;
switch (_that) {
case _FileMoveRequest() when $default != null:
return $default(_that.targetFolderId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileMoveRequest implements FileMoveRequest {
  const _FileMoveRequest({this.targetFolderId});
  factory _FileMoveRequest.fromJson(Map<String, dynamic> json) => _$FileMoveRequestFromJson(json);

@override final  int? targetFolderId;

/// Create a copy of FileMoveRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileMoveRequestCopyWith<_FileMoveRequest> get copyWith => __$FileMoveRequestCopyWithImpl<_FileMoveRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileMoveRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileMoveRequest&&(identical(other.targetFolderId, targetFolderId) || other.targetFolderId == targetFolderId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetFolderId);

@override
String toString() {
  return 'FileMoveRequest(targetFolderId: $targetFolderId)';
}


}

/// @nodoc
abstract mixin class _$FileMoveRequestCopyWith<$Res> implements $FileMoveRequestCopyWith<$Res> {
  factory _$FileMoveRequestCopyWith(_FileMoveRequest value, $Res Function(_FileMoveRequest) _then) = __$FileMoveRequestCopyWithImpl;
@override @useResult
$Res call({
 int? targetFolderId
});




}
/// @nodoc
class __$FileMoveRequestCopyWithImpl<$Res>
    implements _$FileMoveRequestCopyWith<$Res> {
  __$FileMoveRequestCopyWithImpl(this._self, this._then);

  final _FileMoveRequest _self;
  final $Res Function(_FileMoveRequest) _then;

/// Create a copy of FileMoveRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetFolderId = freezed,}) {
  return _then(_FileMoveRequest(
targetFolderId: freezed == targetFolderId ? _self.targetFolderId : targetFolderId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

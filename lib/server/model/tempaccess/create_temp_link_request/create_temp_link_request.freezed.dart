// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_temp_link_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateTempLinkRequest {

 String get fileId; DateTime get expiresAt; int? get maxDownloads; String? get password;
/// Create a copy of CreateTempLinkRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTempLinkRequestCopyWith<CreateTempLinkRequest> get copyWith => _$CreateTempLinkRequestCopyWithImpl<CreateTempLinkRequest>(this as CreateTempLinkRequest, _$identity);

  /// Serializes this CreateTempLinkRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTempLinkRequest&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.maxDownloads, maxDownloads) || other.maxDownloads == maxDownloads)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileId,expiresAt,maxDownloads,password);

@override
String toString() {
  return 'CreateTempLinkRequest(fileId: $fileId, expiresAt: $expiresAt, maxDownloads: $maxDownloads, password: $password)';
}


}

/// @nodoc
abstract mixin class $CreateTempLinkRequestCopyWith<$Res>  {
  factory $CreateTempLinkRequestCopyWith(CreateTempLinkRequest value, $Res Function(CreateTempLinkRequest) _then) = _$CreateTempLinkRequestCopyWithImpl;
@useResult
$Res call({
 String fileId, DateTime expiresAt, int? maxDownloads, String? password
});




}
/// @nodoc
class _$CreateTempLinkRequestCopyWithImpl<$Res>
    implements $CreateTempLinkRequestCopyWith<$Res> {
  _$CreateTempLinkRequestCopyWithImpl(this._self, this._then);

  final CreateTempLinkRequest _self;
  final $Res Function(CreateTempLinkRequest) _then;

/// Create a copy of CreateTempLinkRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileId = null,Object? expiresAt = null,Object? maxDownloads = freezed,Object? password = freezed,}) {
  return _then(_self.copyWith(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,maxDownloads: freezed == maxDownloads ? _self.maxDownloads : maxDownloads // ignore: cast_nullable_to_non_nullable
as int?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateTempLinkRequest].
extension CreateTempLinkRequestPatterns on CreateTempLinkRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateTempLinkRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateTempLinkRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateTempLinkRequest value)  $default,){
final _that = this;
switch (_that) {
case _CreateTempLinkRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateTempLinkRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CreateTempLinkRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileId,  DateTime expiresAt,  int? maxDownloads,  String? password)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateTempLinkRequest() when $default != null:
return $default(_that.fileId,_that.expiresAt,_that.maxDownloads,_that.password);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileId,  DateTime expiresAt,  int? maxDownloads,  String? password)  $default,) {final _that = this;
switch (_that) {
case _CreateTempLinkRequest():
return $default(_that.fileId,_that.expiresAt,_that.maxDownloads,_that.password);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileId,  DateTime expiresAt,  int? maxDownloads,  String? password)?  $default,) {final _that = this;
switch (_that) {
case _CreateTempLinkRequest() when $default != null:
return $default(_that.fileId,_that.expiresAt,_that.maxDownloads,_that.password);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateTempLinkRequest implements CreateTempLinkRequest {
  const _CreateTempLinkRequest({required this.fileId, required this.expiresAt, this.maxDownloads, this.password});
  factory _CreateTempLinkRequest.fromJson(Map<String, dynamic> json) => _$CreateTempLinkRequestFromJson(json);

@override final  String fileId;
@override final  DateTime expiresAt;
@override final  int? maxDownloads;
@override final  String? password;

/// Create a copy of CreateTempLinkRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateTempLinkRequestCopyWith<_CreateTempLinkRequest> get copyWith => __$CreateTempLinkRequestCopyWithImpl<_CreateTempLinkRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateTempLinkRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateTempLinkRequest&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.maxDownloads, maxDownloads) || other.maxDownloads == maxDownloads)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileId,expiresAt,maxDownloads,password);

@override
String toString() {
  return 'CreateTempLinkRequest(fileId: $fileId, expiresAt: $expiresAt, maxDownloads: $maxDownloads, password: $password)';
}


}

/// @nodoc
abstract mixin class _$CreateTempLinkRequestCopyWith<$Res> implements $CreateTempLinkRequestCopyWith<$Res> {
  factory _$CreateTempLinkRequestCopyWith(_CreateTempLinkRequest value, $Res Function(_CreateTempLinkRequest) _then) = __$CreateTempLinkRequestCopyWithImpl;
@override @useResult
$Res call({
 String fileId, DateTime expiresAt, int? maxDownloads, String? password
});




}
/// @nodoc
class __$CreateTempLinkRequestCopyWithImpl<$Res>
    implements _$CreateTempLinkRequestCopyWith<$Res> {
  __$CreateTempLinkRequestCopyWithImpl(this._self, this._then);

  final _CreateTempLinkRequest _self;
  final $Res Function(_CreateTempLinkRequest) _then;

/// Create a copy of CreateTempLinkRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileId = null,Object? expiresAt = null,Object? maxDownloads = freezed,Object? password = freezed,}) {
  return _then(_CreateTempLinkRequest(
fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,maxDownloads: freezed == maxDownloads ? _self.maxDownloads : maxDownloads // ignore: cast_nullable_to_non_nullable
as int?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

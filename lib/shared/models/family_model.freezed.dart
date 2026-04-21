// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FamilyMember {

 String get userId; String get displayName; String get role; DateTime get joinedAt;
/// Create a copy of FamilyMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilyMemberCopyWith<FamilyMember> get copyWith => _$FamilyMemberCopyWithImpl<FamilyMember>(this as FamilyMember, _$identity);

  /// Serializes this FamilyMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FamilyMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,role,joinedAt);

@override
String toString() {
  return 'FamilyMember(userId: $userId, displayName: $displayName, role: $role, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class $FamilyMemberCopyWith<$Res>  {
  factory $FamilyMemberCopyWith(FamilyMember value, $Res Function(FamilyMember) _then) = _$FamilyMemberCopyWithImpl;
@useResult
$Res call({
 String userId, String displayName, String role, DateTime joinedAt
});




}
/// @nodoc
class _$FamilyMemberCopyWithImpl<$Res>
    implements $FamilyMemberCopyWith<$Res> {
  _$FamilyMemberCopyWithImpl(this._self, this._then);

  final FamilyMember _self;
  final $Res Function(FamilyMember) _then;

/// Create a copy of FamilyMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = null,Object? role = null,Object? joinedAt = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [FamilyMember].
extension FamilyMemberPatterns on FamilyMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FamilyMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FamilyMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FamilyMember value)  $default,){
final _that = this;
switch (_that) {
case _FamilyMember():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FamilyMember value)?  $default,){
final _that = this;
switch (_that) {
case _FamilyMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String displayName,  String role,  DateTime joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FamilyMember() when $default != null:
return $default(_that.userId,_that.displayName,_that.role,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String displayName,  String role,  DateTime joinedAt)  $default,) {final _that = this;
switch (_that) {
case _FamilyMember():
return $default(_that.userId,_that.displayName,_that.role,_that.joinedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String displayName,  String role,  DateTime joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _FamilyMember() when $default != null:
return $default(_that.userId,_that.displayName,_that.role,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FamilyMember implements FamilyMember {
  const _FamilyMember({required this.userId, required this.displayName, required this.role, required this.joinedAt});
  factory _FamilyMember.fromJson(Map<String, dynamic> json) => _$FamilyMemberFromJson(json);

@override final  String userId;
@override final  String displayName;
@override final  String role;
@override final  DateTime joinedAt;

/// Create a copy of FamilyMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilyMemberCopyWith<_FamilyMember> get copyWith => __$FamilyMemberCopyWithImpl<_FamilyMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FamilyMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FamilyMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,role,joinedAt);

@override
String toString() {
  return 'FamilyMember(userId: $userId, displayName: $displayName, role: $role, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$FamilyMemberCopyWith<$Res> implements $FamilyMemberCopyWith<$Res> {
  factory _$FamilyMemberCopyWith(_FamilyMember value, $Res Function(_FamilyMember) _then) = __$FamilyMemberCopyWithImpl;
@override @useResult
$Res call({
 String userId, String displayName, String role, DateTime joinedAt
});




}
/// @nodoc
class __$FamilyMemberCopyWithImpl<$Res>
    implements _$FamilyMemberCopyWith<$Res> {
  __$FamilyMemberCopyWithImpl(this._self, this._then);

  final _FamilyMember _self;
  final $Res Function(_FamilyMember) _then;

/// Create a copy of FamilyMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = null,Object? role = null,Object? joinedAt = null,}) {
  return _then(_FamilyMember(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$Family {

 String get familyId; String get name; String get ownerUid; int get maxMembers; List<FamilyMember> get members; DateTime get createdAt;
/// Create a copy of Family
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilyCopyWith<Family> get copyWith => _$FamilyCopyWithImpl<Family>(this as Family, _$identity);

  /// Serializes this Family to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Family&&(identical(other.familyId, familyId) || other.familyId == familyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.ownerUid, ownerUid) || other.ownerUid == ownerUid)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&const DeepCollectionEquality().equals(other.members, members)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,familyId,name,ownerUid,maxMembers,const DeepCollectionEquality().hash(members),createdAt);

@override
String toString() {
  return 'Family(familyId: $familyId, name: $name, ownerUid: $ownerUid, maxMembers: $maxMembers, members: $members, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $FamilyCopyWith<$Res>  {
  factory $FamilyCopyWith(Family value, $Res Function(Family) _then) = _$FamilyCopyWithImpl;
@useResult
$Res call({
 String familyId, String name, String ownerUid, int maxMembers, List<FamilyMember> members, DateTime createdAt
});




}
/// @nodoc
class _$FamilyCopyWithImpl<$Res>
    implements $FamilyCopyWith<$Res> {
  _$FamilyCopyWithImpl(this._self, this._then);

  final Family _self;
  final $Res Function(Family) _then;

/// Create a copy of Family
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? familyId = null,Object? name = null,Object? ownerUid = null,Object? maxMembers = null,Object? members = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
familyId: null == familyId ? _self.familyId : familyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownerUid: null == ownerUid ? _self.ownerUid : ownerUid // ignore: cast_nullable_to_non_nullable
as String,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<FamilyMember>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Family].
extension FamilyPatterns on Family {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Family value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Family() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Family value)  $default,){
final _that = this;
switch (_that) {
case _Family():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Family value)?  $default,){
final _that = this;
switch (_that) {
case _Family() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String familyId,  String name,  String ownerUid,  int maxMembers,  List<FamilyMember> members,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Family() when $default != null:
return $default(_that.familyId,_that.name,_that.ownerUid,_that.maxMembers,_that.members,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String familyId,  String name,  String ownerUid,  int maxMembers,  List<FamilyMember> members,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Family():
return $default(_that.familyId,_that.name,_that.ownerUid,_that.maxMembers,_that.members,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String familyId,  String name,  String ownerUid,  int maxMembers,  List<FamilyMember> members,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Family() when $default != null:
return $default(_that.familyId,_that.name,_that.ownerUid,_that.maxMembers,_that.members,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Family implements Family {
  const _Family({required this.familyId, required this.name, required this.ownerUid, required this.maxMembers, required final  List<FamilyMember> members, required this.createdAt}): _members = members;
  factory _Family.fromJson(Map<String, dynamic> json) => _$FamilyFromJson(json);

@override final  String familyId;
@override final  String name;
@override final  String ownerUid;
@override final  int maxMembers;
 final  List<FamilyMember> _members;
@override List<FamilyMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

@override final  DateTime createdAt;

/// Create a copy of Family
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilyCopyWith<_Family> get copyWith => __$FamilyCopyWithImpl<_Family>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FamilyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Family&&(identical(other.familyId, familyId) || other.familyId == familyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.ownerUid, ownerUid) || other.ownerUid == ownerUid)&&(identical(other.maxMembers, maxMembers) || other.maxMembers == maxMembers)&&const DeepCollectionEquality().equals(other._members, _members)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,familyId,name,ownerUid,maxMembers,const DeepCollectionEquality().hash(_members),createdAt);

@override
String toString() {
  return 'Family(familyId: $familyId, name: $name, ownerUid: $ownerUid, maxMembers: $maxMembers, members: $members, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$FamilyCopyWith<$Res> implements $FamilyCopyWith<$Res> {
  factory _$FamilyCopyWith(_Family value, $Res Function(_Family) _then) = __$FamilyCopyWithImpl;
@override @useResult
$Res call({
 String familyId, String name, String ownerUid, int maxMembers, List<FamilyMember> members, DateTime createdAt
});




}
/// @nodoc
class __$FamilyCopyWithImpl<$Res>
    implements _$FamilyCopyWith<$Res> {
  __$FamilyCopyWithImpl(this._self, this._then);

  final _Family _self;
  final $Res Function(_Family) _then;

/// Create a copy of Family
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? familyId = null,Object? name = null,Object? ownerUid = null,Object? maxMembers = null,Object? members = null,Object? createdAt = null,}) {
  return _then(_Family(
familyId: null == familyId ? _self.familyId : familyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownerUid: null == ownerUid ? _self.ownerUid : ownerUid // ignore: cast_nullable_to_non_nullable
as String,maxMembers: null == maxMembers ? _self.maxMembers : maxMembers // ignore: cast_nullable_to_non_nullable
as int,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<FamilyMember>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$FamilyInvite {

 String get token; DateTime get expiresAt; String get role;
/// Create a copy of FamilyInvite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilyInviteCopyWith<FamilyInvite> get copyWith => _$FamilyInviteCopyWithImpl<FamilyInvite>(this as FamilyInvite, _$identity);

  /// Serializes this FamilyInvite to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FamilyInvite&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,expiresAt,role);

@override
String toString() {
  return 'FamilyInvite(token: $token, expiresAt: $expiresAt, role: $role)';
}


}

/// @nodoc
abstract mixin class $FamilyInviteCopyWith<$Res>  {
  factory $FamilyInviteCopyWith(FamilyInvite value, $Res Function(FamilyInvite) _then) = _$FamilyInviteCopyWithImpl;
@useResult
$Res call({
 String token, DateTime expiresAt, String role
});




}
/// @nodoc
class _$FamilyInviteCopyWithImpl<$Res>
    implements $FamilyInviteCopyWith<$Res> {
  _$FamilyInviteCopyWithImpl(this._self, this._then);

  final FamilyInvite _self;
  final $Res Function(FamilyInvite) _then;

/// Create a copy of FamilyInvite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? expiresAt = null,Object? role = null,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FamilyInvite].
extension FamilyInvitePatterns on FamilyInvite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FamilyInvite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FamilyInvite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FamilyInvite value)  $default,){
final _that = this;
switch (_that) {
case _FamilyInvite():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FamilyInvite value)?  $default,){
final _that = this;
switch (_that) {
case _FamilyInvite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  DateTime expiresAt,  String role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FamilyInvite() when $default != null:
return $default(_that.token,_that.expiresAt,_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  DateTime expiresAt,  String role)  $default,) {final _that = this;
switch (_that) {
case _FamilyInvite():
return $default(_that.token,_that.expiresAt,_that.role);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  DateTime expiresAt,  String role)?  $default,) {final _that = this;
switch (_that) {
case _FamilyInvite() when $default != null:
return $default(_that.token,_that.expiresAt,_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FamilyInvite implements FamilyInvite {
  const _FamilyInvite({required this.token, required this.expiresAt, required this.role});
  factory _FamilyInvite.fromJson(Map<String, dynamic> json) => _$FamilyInviteFromJson(json);

@override final  String token;
@override final  DateTime expiresAt;
@override final  String role;

/// Create a copy of FamilyInvite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilyInviteCopyWith<_FamilyInvite> get copyWith => __$FamilyInviteCopyWithImpl<_FamilyInvite>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FamilyInviteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FamilyInvite&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,token,expiresAt,role);

@override
String toString() {
  return 'FamilyInvite(token: $token, expiresAt: $expiresAt, role: $role)';
}


}

/// @nodoc
abstract mixin class _$FamilyInviteCopyWith<$Res> implements $FamilyInviteCopyWith<$Res> {
  factory _$FamilyInviteCopyWith(_FamilyInvite value, $Res Function(_FamilyInvite) _then) = __$FamilyInviteCopyWithImpl;
@override @useResult
$Res call({
 String token, DateTime expiresAt, String role
});




}
/// @nodoc
class __$FamilyInviteCopyWithImpl<$Res>
    implements _$FamilyInviteCopyWith<$Res> {
  __$FamilyInviteCopyWithImpl(this._self, this._then);

  final _FamilyInvite _self;
  final $Res Function(_FamilyInvite) _then;

/// Create a copy of FamilyInvite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? expiresAt = null,Object? role = null,}) {
  return _then(_FamilyInvite(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FamilyPermission {

 String get permissionId; String get fromUserId; String get toUserId; String get viewLevel; DateTime get createdAt;
/// Create a copy of FamilyPermission
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilyPermissionCopyWith<FamilyPermission> get copyWith => _$FamilyPermissionCopyWithImpl<FamilyPermission>(this as FamilyPermission, _$identity);

  /// Serializes this FamilyPermission to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FamilyPermission&&(identical(other.permissionId, permissionId) || other.permissionId == permissionId)&&(identical(other.fromUserId, fromUserId) || other.fromUserId == fromUserId)&&(identical(other.toUserId, toUserId) || other.toUserId == toUserId)&&(identical(other.viewLevel, viewLevel) || other.viewLevel == viewLevel)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,permissionId,fromUserId,toUserId,viewLevel,createdAt);

@override
String toString() {
  return 'FamilyPermission(permissionId: $permissionId, fromUserId: $fromUserId, toUserId: $toUserId, viewLevel: $viewLevel, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $FamilyPermissionCopyWith<$Res>  {
  factory $FamilyPermissionCopyWith(FamilyPermission value, $Res Function(FamilyPermission) _then) = _$FamilyPermissionCopyWithImpl;
@useResult
$Res call({
 String permissionId, String fromUserId, String toUserId, String viewLevel, DateTime createdAt
});




}
/// @nodoc
class _$FamilyPermissionCopyWithImpl<$Res>
    implements $FamilyPermissionCopyWith<$Res> {
  _$FamilyPermissionCopyWithImpl(this._self, this._then);

  final FamilyPermission _self;
  final $Res Function(FamilyPermission) _then;

/// Create a copy of FamilyPermission
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? permissionId = null,Object? fromUserId = null,Object? toUserId = null,Object? viewLevel = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
permissionId: null == permissionId ? _self.permissionId : permissionId // ignore: cast_nullable_to_non_nullable
as String,fromUserId: null == fromUserId ? _self.fromUserId : fromUserId // ignore: cast_nullable_to_non_nullable
as String,toUserId: null == toUserId ? _self.toUserId : toUserId // ignore: cast_nullable_to_non_nullable
as String,viewLevel: null == viewLevel ? _self.viewLevel : viewLevel // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [FamilyPermission].
extension FamilyPermissionPatterns on FamilyPermission {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FamilyPermission value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FamilyPermission() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FamilyPermission value)  $default,){
final _that = this;
switch (_that) {
case _FamilyPermission():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FamilyPermission value)?  $default,){
final _that = this;
switch (_that) {
case _FamilyPermission() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String permissionId,  String fromUserId,  String toUserId,  String viewLevel,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FamilyPermission() when $default != null:
return $default(_that.permissionId,_that.fromUserId,_that.toUserId,_that.viewLevel,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String permissionId,  String fromUserId,  String toUserId,  String viewLevel,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _FamilyPermission():
return $default(_that.permissionId,_that.fromUserId,_that.toUserId,_that.viewLevel,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String permissionId,  String fromUserId,  String toUserId,  String viewLevel,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _FamilyPermission() when $default != null:
return $default(_that.permissionId,_that.fromUserId,_that.toUserId,_that.viewLevel,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FamilyPermission implements FamilyPermission {
  const _FamilyPermission({required this.permissionId, required this.fromUserId, required this.toUserId, required this.viewLevel, required this.createdAt});
  factory _FamilyPermission.fromJson(Map<String, dynamic> json) => _$FamilyPermissionFromJson(json);

@override final  String permissionId;
@override final  String fromUserId;
@override final  String toUserId;
@override final  String viewLevel;
@override final  DateTime createdAt;

/// Create a copy of FamilyPermission
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilyPermissionCopyWith<_FamilyPermission> get copyWith => __$FamilyPermissionCopyWithImpl<_FamilyPermission>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FamilyPermissionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FamilyPermission&&(identical(other.permissionId, permissionId) || other.permissionId == permissionId)&&(identical(other.fromUserId, fromUserId) || other.fromUserId == fromUserId)&&(identical(other.toUserId, toUserId) || other.toUserId == toUserId)&&(identical(other.viewLevel, viewLevel) || other.viewLevel == viewLevel)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,permissionId,fromUserId,toUserId,viewLevel,createdAt);

@override
String toString() {
  return 'FamilyPermission(permissionId: $permissionId, fromUserId: $fromUserId, toUserId: $toUserId, viewLevel: $viewLevel, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$FamilyPermissionCopyWith<$Res> implements $FamilyPermissionCopyWith<$Res> {
  factory _$FamilyPermissionCopyWith(_FamilyPermission value, $Res Function(_FamilyPermission) _then) = __$FamilyPermissionCopyWithImpl;
@override @useResult
$Res call({
 String permissionId, String fromUserId, String toUserId, String viewLevel, DateTime createdAt
});




}
/// @nodoc
class __$FamilyPermissionCopyWithImpl<$Res>
    implements _$FamilyPermissionCopyWith<$Res> {
  __$FamilyPermissionCopyWithImpl(this._self, this._then);

  final _FamilyPermission _self;
  final $Res Function(_FamilyPermission) _then;

/// Create a copy of FamilyPermission
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? permissionId = null,Object? fromUserId = null,Object? toUserId = null,Object? viewLevel = null,Object? createdAt = null,}) {
  return _then(_FamilyPermission(
permissionId: null == permissionId ? _self.permissionId : permissionId // ignore: cast_nullable_to_non_nullable
as String,fromUserId: null == fromUserId ? _self.fromUserId : fromUserId // ignore: cast_nullable_to_non_nullable
as String,toUserId: null == toUserId ? _self.toUserId : toUserId // ignore: cast_nullable_to_non_nullable
as String,viewLevel: null == viewLevel ? _self.viewLevel : viewLevel // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

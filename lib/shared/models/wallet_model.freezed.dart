// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Wallet {

 String get walletId; String get ownerUid; String? get guardianUid; String get walletType; String get name; DateTime get createdAt;
/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletCopyWith<Wallet> get copyWith => _$WalletCopyWithImpl<Wallet>(this as Wallet, _$identity);

  /// Serializes this Wallet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Wallet&&(identical(other.walletId, walletId) || other.walletId == walletId)&&(identical(other.ownerUid, ownerUid) || other.ownerUid == ownerUid)&&(identical(other.guardianUid, guardianUid) || other.guardianUid == guardianUid)&&(identical(other.walletType, walletType) || other.walletType == walletType)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,walletId,ownerUid,guardianUid,walletType,name,createdAt);

@override
String toString() {
  return 'Wallet(walletId: $walletId, ownerUid: $ownerUid, guardianUid: $guardianUid, walletType: $walletType, name: $name, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $WalletCopyWith<$Res>  {
  factory $WalletCopyWith(Wallet value, $Res Function(Wallet) _then) = _$WalletCopyWithImpl;
@useResult
$Res call({
 String walletId, String ownerUid, String? guardianUid, String walletType, String name, DateTime createdAt
});




}
/// @nodoc
class _$WalletCopyWithImpl<$Res>
    implements $WalletCopyWith<$Res> {
  _$WalletCopyWithImpl(this._self, this._then);

  final Wallet _self;
  final $Res Function(Wallet) _then;

/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? walletId = null,Object? ownerUid = null,Object? guardianUid = freezed,Object? walletType = null,Object? name = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
walletId: null == walletId ? _self.walletId : walletId // ignore: cast_nullable_to_non_nullable
as String,ownerUid: null == ownerUid ? _self.ownerUid : ownerUid // ignore: cast_nullable_to_non_nullable
as String,guardianUid: freezed == guardianUid ? _self.guardianUid : guardianUid // ignore: cast_nullable_to_non_nullable
as String?,walletType: null == walletType ? _self.walletType : walletType // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Wallet].
extension WalletPatterns on Wallet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Wallet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Wallet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Wallet value)  $default,){
final _that = this;
switch (_that) {
case _Wallet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Wallet value)?  $default,){
final _that = this;
switch (_that) {
case _Wallet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String walletId,  String ownerUid,  String? guardianUid,  String walletType,  String name,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Wallet() when $default != null:
return $default(_that.walletId,_that.ownerUid,_that.guardianUid,_that.walletType,_that.name,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String walletId,  String ownerUid,  String? guardianUid,  String walletType,  String name,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Wallet():
return $default(_that.walletId,_that.ownerUid,_that.guardianUid,_that.walletType,_that.name,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String walletId,  String ownerUid,  String? guardianUid,  String walletType,  String name,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Wallet() when $default != null:
return $default(_that.walletId,_that.ownerUid,_that.guardianUid,_that.walletType,_that.name,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Wallet implements Wallet {
  const _Wallet({required this.walletId, required this.ownerUid, this.guardianUid, required this.walletType, required this.name, required this.createdAt});
  factory _Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);

@override final  String walletId;
@override final  String ownerUid;
@override final  String? guardianUid;
@override final  String walletType;
@override final  String name;
@override final  DateTime createdAt;

/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletCopyWith<_Wallet> get copyWith => __$WalletCopyWithImpl<_Wallet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Wallet&&(identical(other.walletId, walletId) || other.walletId == walletId)&&(identical(other.ownerUid, ownerUid) || other.ownerUid == ownerUid)&&(identical(other.guardianUid, guardianUid) || other.guardianUid == guardianUid)&&(identical(other.walletType, walletType) || other.walletType == walletType)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,walletId,ownerUid,guardianUid,walletType,name,createdAt);

@override
String toString() {
  return 'Wallet(walletId: $walletId, ownerUid: $ownerUid, guardianUid: $guardianUid, walletType: $walletType, name: $name, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$WalletCopyWith<$Res> implements $WalletCopyWith<$Res> {
  factory _$WalletCopyWith(_Wallet value, $Res Function(_Wallet) _then) = __$WalletCopyWithImpl;
@override @useResult
$Res call({
 String walletId, String ownerUid, String? guardianUid, String walletType, String name, DateTime createdAt
});




}
/// @nodoc
class __$WalletCopyWithImpl<$Res>
    implements _$WalletCopyWith<$Res> {
  __$WalletCopyWithImpl(this._self, this._then);

  final _Wallet _self;
  final $Res Function(_Wallet) _then;

/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? walletId = null,Object? ownerUid = null,Object? guardianUid = freezed,Object? walletType = null,Object? name = null,Object? createdAt = null,}) {
  return _then(_Wallet(
walletId: null == walletId ? _self.walletId : walletId // ignore: cast_nullable_to_non_nullable
as String,ownerUid: null == ownerUid ? _self.ownerUid : ownerUid // ignore: cast_nullable_to_non_nullable
as String,guardianUid: freezed == guardianUid ? _self.guardianUid : guardianUid // ignore: cast_nullable_to_non_nullable
as String?,walletType: null == walletType ? _self.walletType : walletType // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$WalletRule {

 String get ruleId; String get matchType; String get matchValue; String get walletId; DateTime get createdAt;
/// Create a copy of WalletRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletRuleCopyWith<WalletRule> get copyWith => _$WalletRuleCopyWithImpl<WalletRule>(this as WalletRule, _$identity);

  /// Serializes this WalletRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletRule&&(identical(other.ruleId, ruleId) || other.ruleId == ruleId)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.matchValue, matchValue) || other.matchValue == matchValue)&&(identical(other.walletId, walletId) || other.walletId == walletId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ruleId,matchType,matchValue,walletId,createdAt);

@override
String toString() {
  return 'WalletRule(ruleId: $ruleId, matchType: $matchType, matchValue: $matchValue, walletId: $walletId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $WalletRuleCopyWith<$Res>  {
  factory $WalletRuleCopyWith(WalletRule value, $Res Function(WalletRule) _then) = _$WalletRuleCopyWithImpl;
@useResult
$Res call({
 String ruleId, String matchType, String matchValue, String walletId, DateTime createdAt
});




}
/// @nodoc
class _$WalletRuleCopyWithImpl<$Res>
    implements $WalletRuleCopyWith<$Res> {
  _$WalletRuleCopyWithImpl(this._self, this._then);

  final WalletRule _self;
  final $Res Function(WalletRule) _then;

/// Create a copy of WalletRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ruleId = null,Object? matchType = null,Object? matchValue = null,Object? walletId = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
ruleId: null == ruleId ? _self.ruleId : ruleId // ignore: cast_nullable_to_non_nullable
as String,matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,matchValue: null == matchValue ? _self.matchValue : matchValue // ignore: cast_nullable_to_non_nullable
as String,walletId: null == walletId ? _self.walletId : walletId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletRule].
extension WalletRulePatterns on WalletRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletRule value)  $default,){
final _that = this;
switch (_that) {
case _WalletRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletRule value)?  $default,){
final _that = this;
switch (_that) {
case _WalletRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ruleId,  String matchType,  String matchValue,  String walletId,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletRule() when $default != null:
return $default(_that.ruleId,_that.matchType,_that.matchValue,_that.walletId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ruleId,  String matchType,  String matchValue,  String walletId,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _WalletRule():
return $default(_that.ruleId,_that.matchType,_that.matchValue,_that.walletId,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ruleId,  String matchType,  String matchValue,  String walletId,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _WalletRule() when $default != null:
return $default(_that.ruleId,_that.matchType,_that.matchValue,_that.walletId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletRule implements WalletRule {
  const _WalletRule({required this.ruleId, required this.matchType, required this.matchValue, required this.walletId, required this.createdAt});
  factory _WalletRule.fromJson(Map<String, dynamic> json) => _$WalletRuleFromJson(json);

@override final  String ruleId;
@override final  String matchType;
@override final  String matchValue;
@override final  String walletId;
@override final  DateTime createdAt;

/// Create a copy of WalletRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletRuleCopyWith<_WalletRule> get copyWith => __$WalletRuleCopyWithImpl<_WalletRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletRuleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletRule&&(identical(other.ruleId, ruleId) || other.ruleId == ruleId)&&(identical(other.matchType, matchType) || other.matchType == matchType)&&(identical(other.matchValue, matchValue) || other.matchValue == matchValue)&&(identical(other.walletId, walletId) || other.walletId == walletId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ruleId,matchType,matchValue,walletId,createdAt);

@override
String toString() {
  return 'WalletRule(ruleId: $ruleId, matchType: $matchType, matchValue: $matchValue, walletId: $walletId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$WalletRuleCopyWith<$Res> implements $WalletRuleCopyWith<$Res> {
  factory _$WalletRuleCopyWith(_WalletRule value, $Res Function(_WalletRule) _then) = __$WalletRuleCopyWithImpl;
@override @useResult
$Res call({
 String ruleId, String matchType, String matchValue, String walletId, DateTime createdAt
});




}
/// @nodoc
class __$WalletRuleCopyWithImpl<$Res>
    implements _$WalletRuleCopyWith<$Res> {
  __$WalletRuleCopyWithImpl(this._self, this._then);

  final _WalletRule _self;
  final $Res Function(_WalletRule) _then;

/// Create a copy of WalletRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ruleId = null,Object? matchType = null,Object? matchValue = null,Object? walletId = null,Object? createdAt = null,}) {
  return _then(_WalletRule(
ruleId: null == ruleId ? _self.ruleId : ruleId // ignore: cast_nullable_to_non_nullable
as String,matchType: null == matchType ? _self.matchType : matchType // ignore: cast_nullable_to_non_nullable
as String,matchValue: null == matchValue ? _self.matchValue : matchValue // ignore: cast_nullable_to_non_nullable
as String,walletId: null == walletId ? _self.walletId : walletId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

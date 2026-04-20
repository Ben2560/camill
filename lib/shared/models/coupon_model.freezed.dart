// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coupon_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Coupon {

 String get couponId; String get storeName; String get description; int get discountAmount; DateTime? get validFrom; DateTime? get validUntil; bool get isUsed; bool get isFromOcr; DateTime get createdAt;// 0=月, 1=火, 2=水, 3=木, 4=金, 5=土, 6=日 (null = 毎日)
 List<int>? get availableDays; bool get requiresSurvey; String? get surveyUrl; bool get surveyAnswered; bool get isCommunityShared;
/// Create a copy of Coupon
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CouponCopyWith<Coupon> get copyWith => _$CouponCopyWithImpl<Coupon>(this as Coupon, _$identity);

  /// Serializes this Coupon to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Coupon&&(identical(other.couponId, couponId) || other.couponId == couponId)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.description, description) || other.description == description)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.isUsed, isUsed) || other.isUsed == isUsed)&&(identical(other.isFromOcr, isFromOcr) || other.isFromOcr == isFromOcr)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.availableDays, availableDays)&&(identical(other.requiresSurvey, requiresSurvey) || other.requiresSurvey == requiresSurvey)&&(identical(other.surveyUrl, surveyUrl) || other.surveyUrl == surveyUrl)&&(identical(other.surveyAnswered, surveyAnswered) || other.surveyAnswered == surveyAnswered)&&(identical(other.isCommunityShared, isCommunityShared) || other.isCommunityShared == isCommunityShared));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,couponId,storeName,description,discountAmount,validFrom,validUntil,isUsed,isFromOcr,createdAt,const DeepCollectionEquality().hash(availableDays),requiresSurvey,surveyUrl,surveyAnswered,isCommunityShared);

@override
String toString() {
  return 'Coupon(couponId: $couponId, storeName: $storeName, description: $description, discountAmount: $discountAmount, validFrom: $validFrom, validUntil: $validUntil, isUsed: $isUsed, isFromOcr: $isFromOcr, createdAt: $createdAt, availableDays: $availableDays, requiresSurvey: $requiresSurvey, surveyUrl: $surveyUrl, surveyAnswered: $surveyAnswered, isCommunityShared: $isCommunityShared)';
}


}

/// @nodoc
abstract mixin class $CouponCopyWith<$Res>  {
  factory $CouponCopyWith(Coupon value, $Res Function(Coupon) _then) = _$CouponCopyWithImpl;
@useResult
$Res call({
 String couponId, String storeName, String description, int discountAmount, DateTime? validFrom, DateTime? validUntil, bool isUsed, bool isFromOcr, DateTime createdAt, List<int>? availableDays, bool requiresSurvey, String? surveyUrl, bool surveyAnswered, bool isCommunityShared
});




}
/// @nodoc
class _$CouponCopyWithImpl<$Res>
    implements $CouponCopyWith<$Res> {
  _$CouponCopyWithImpl(this._self, this._then);

  final Coupon _self;
  final $Res Function(Coupon) _then;

/// Create a copy of Coupon
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? couponId = null,Object? storeName = null,Object? description = null,Object? discountAmount = null,Object? validFrom = freezed,Object? validUntil = freezed,Object? isUsed = null,Object? isFromOcr = null,Object? createdAt = null,Object? availableDays = freezed,Object? requiresSurvey = null,Object? surveyUrl = freezed,Object? surveyAnswered = null,Object? isCommunityShared = null,}) {
  return _then(_self.copyWith(
couponId: null == couponId ? _self.couponId : couponId // ignore: cast_nullable_to_non_nullable
as String,storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as int,validFrom: freezed == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,isUsed: null == isUsed ? _self.isUsed : isUsed // ignore: cast_nullable_to_non_nullable
as bool,isFromOcr: null == isFromOcr ? _self.isFromOcr : isFromOcr // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,availableDays: freezed == availableDays ? _self.availableDays : availableDays // ignore: cast_nullable_to_non_nullable
as List<int>?,requiresSurvey: null == requiresSurvey ? _self.requiresSurvey : requiresSurvey // ignore: cast_nullable_to_non_nullable
as bool,surveyUrl: freezed == surveyUrl ? _self.surveyUrl : surveyUrl // ignore: cast_nullable_to_non_nullable
as String?,surveyAnswered: null == surveyAnswered ? _self.surveyAnswered : surveyAnswered // ignore: cast_nullable_to_non_nullable
as bool,isCommunityShared: null == isCommunityShared ? _self.isCommunityShared : isCommunityShared // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Coupon].
extension CouponPatterns on Coupon {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Coupon value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Coupon() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Coupon value)  $default,){
final _that = this;
switch (_that) {
case _Coupon():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Coupon value)?  $default,){
final _that = this;
switch (_that) {
case _Coupon() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String couponId,  String storeName,  String description,  int discountAmount,  DateTime? validFrom,  DateTime? validUntil,  bool isUsed,  bool isFromOcr,  DateTime createdAt,  List<int>? availableDays,  bool requiresSurvey,  String? surveyUrl,  bool surveyAnswered,  bool isCommunityShared)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Coupon() when $default != null:
return $default(_that.couponId,_that.storeName,_that.description,_that.discountAmount,_that.validFrom,_that.validUntil,_that.isUsed,_that.isFromOcr,_that.createdAt,_that.availableDays,_that.requiresSurvey,_that.surveyUrl,_that.surveyAnswered,_that.isCommunityShared);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String couponId,  String storeName,  String description,  int discountAmount,  DateTime? validFrom,  DateTime? validUntil,  bool isUsed,  bool isFromOcr,  DateTime createdAt,  List<int>? availableDays,  bool requiresSurvey,  String? surveyUrl,  bool surveyAnswered,  bool isCommunityShared)  $default,) {final _that = this;
switch (_that) {
case _Coupon():
return $default(_that.couponId,_that.storeName,_that.description,_that.discountAmount,_that.validFrom,_that.validUntil,_that.isUsed,_that.isFromOcr,_that.createdAt,_that.availableDays,_that.requiresSurvey,_that.surveyUrl,_that.surveyAnswered,_that.isCommunityShared);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String couponId,  String storeName,  String description,  int discountAmount,  DateTime? validFrom,  DateTime? validUntil,  bool isUsed,  bool isFromOcr,  DateTime createdAt,  List<int>? availableDays,  bool requiresSurvey,  String? surveyUrl,  bool surveyAnswered,  bool isCommunityShared)?  $default,) {final _that = this;
switch (_that) {
case _Coupon() when $default != null:
return $default(_that.couponId,_that.storeName,_that.description,_that.discountAmount,_that.validFrom,_that.validUntil,_that.isUsed,_that.isFromOcr,_that.createdAt,_that.availableDays,_that.requiresSurvey,_that.surveyUrl,_that.surveyAnswered,_that.isCommunityShared);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Coupon extends Coupon {
  const _Coupon({required this.couponId, required this.storeName, required this.description, required this.discountAmount, this.validFrom, this.validUntil, required this.isUsed, required this.isFromOcr, required this.createdAt, final  List<int>? availableDays, this.requiresSurvey = false, this.surveyUrl, this.surveyAnswered = false, this.isCommunityShared = false}): _availableDays = availableDays,super._();
  factory _Coupon.fromJson(Map<String, dynamic> json) => _$CouponFromJson(json);

@override final  String couponId;
@override final  String storeName;
@override final  String description;
@override final  int discountAmount;
@override final  DateTime? validFrom;
@override final  DateTime? validUntil;
@override final  bool isUsed;
@override final  bool isFromOcr;
@override final  DateTime createdAt;
// 0=月, 1=火, 2=水, 3=木, 4=金, 5=土, 6=日 (null = 毎日)
 final  List<int>? _availableDays;
// 0=月, 1=火, 2=水, 3=木, 4=金, 5=土, 6=日 (null = 毎日)
@override List<int>? get availableDays {
  final value = _availableDays;
  if (value == null) return null;
  if (_availableDays is EqualUnmodifiableListView) return _availableDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey() final  bool requiresSurvey;
@override final  String? surveyUrl;
@override@JsonKey() final  bool surveyAnswered;
@override@JsonKey() final  bool isCommunityShared;

/// Create a copy of Coupon
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CouponCopyWith<_Coupon> get copyWith => __$CouponCopyWithImpl<_Coupon>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CouponToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Coupon&&(identical(other.couponId, couponId) || other.couponId == couponId)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.description, description) || other.description == description)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.isUsed, isUsed) || other.isUsed == isUsed)&&(identical(other.isFromOcr, isFromOcr) || other.isFromOcr == isFromOcr)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._availableDays, _availableDays)&&(identical(other.requiresSurvey, requiresSurvey) || other.requiresSurvey == requiresSurvey)&&(identical(other.surveyUrl, surveyUrl) || other.surveyUrl == surveyUrl)&&(identical(other.surveyAnswered, surveyAnswered) || other.surveyAnswered == surveyAnswered)&&(identical(other.isCommunityShared, isCommunityShared) || other.isCommunityShared == isCommunityShared));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,couponId,storeName,description,discountAmount,validFrom,validUntil,isUsed,isFromOcr,createdAt,const DeepCollectionEquality().hash(_availableDays),requiresSurvey,surveyUrl,surveyAnswered,isCommunityShared);

@override
String toString() {
  return 'Coupon(couponId: $couponId, storeName: $storeName, description: $description, discountAmount: $discountAmount, validFrom: $validFrom, validUntil: $validUntil, isUsed: $isUsed, isFromOcr: $isFromOcr, createdAt: $createdAt, availableDays: $availableDays, requiresSurvey: $requiresSurvey, surveyUrl: $surveyUrl, surveyAnswered: $surveyAnswered, isCommunityShared: $isCommunityShared)';
}


}

/// @nodoc
abstract mixin class _$CouponCopyWith<$Res> implements $CouponCopyWith<$Res> {
  factory _$CouponCopyWith(_Coupon value, $Res Function(_Coupon) _then) = __$CouponCopyWithImpl;
@override @useResult
$Res call({
 String couponId, String storeName, String description, int discountAmount, DateTime? validFrom, DateTime? validUntil, bool isUsed, bool isFromOcr, DateTime createdAt, List<int>? availableDays, bool requiresSurvey, String? surveyUrl, bool surveyAnswered, bool isCommunityShared
});




}
/// @nodoc
class __$CouponCopyWithImpl<$Res>
    implements _$CouponCopyWith<$Res> {
  __$CouponCopyWithImpl(this._self, this._then);

  final _Coupon _self;
  final $Res Function(_Coupon) _then;

/// Create a copy of Coupon
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? couponId = null,Object? storeName = null,Object? description = null,Object? discountAmount = null,Object? validFrom = freezed,Object? validUntil = freezed,Object? isUsed = null,Object? isFromOcr = null,Object? createdAt = null,Object? availableDays = freezed,Object? requiresSurvey = null,Object? surveyUrl = freezed,Object? surveyAnswered = null,Object? isCommunityShared = null,}) {
  return _then(_Coupon(
couponId: null == couponId ? _self.couponId : couponId // ignore: cast_nullable_to_non_nullable
as String,storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as int,validFrom: freezed == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,isUsed: null == isUsed ? _self.isUsed : isUsed // ignore: cast_nullable_to_non_nullable
as bool,isFromOcr: null == isFromOcr ? _self.isFromOcr : isFromOcr // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,availableDays: freezed == availableDays ? _self._availableDays : availableDays // ignore: cast_nullable_to_non_nullable
as List<int>?,requiresSurvey: null == requiresSurvey ? _self.requiresSurvey : requiresSurvey // ignore: cast_nullable_to_non_nullable
as bool,surveyUrl: freezed == surveyUrl ? _self.surveyUrl : surveyUrl // ignore: cast_nullable_to_non_nullable
as String?,surveyAnswered: null == surveyAnswered ? _self.surveyAnswered : surveyAnswered // ignore: cast_nullable_to_non_nullable
as bool,isCommunityShared: null == isCommunityShared ? _self.isCommunityShared : isCommunityShared // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

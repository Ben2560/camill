// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'community_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommunityStore {

 String get storeId; String get storeName; double get latitude; double get longitude; String? get storeAddress; String? get storePhone; int get couponCount; bool get isFeatured; bool get isLocked; List<SharedCoupon> get coupons;
/// Create a copy of CommunityStore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommunityStoreCopyWith<CommunityStore> get copyWith => _$CommunityStoreCopyWithImpl<CommunityStore>(this as CommunityStore, _$identity);

  /// Serializes this CommunityStore to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommunityStore&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.storeAddress, storeAddress) || other.storeAddress == storeAddress)&&(identical(other.storePhone, storePhone) || other.storePhone == storePhone)&&(identical(other.couponCount, couponCount) || other.couponCount == couponCount)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&const DeepCollectionEquality().equals(other.coupons, coupons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,storeId,storeName,latitude,longitude,storeAddress,storePhone,couponCount,isFeatured,isLocked,const DeepCollectionEquality().hash(coupons));

@override
String toString() {
  return 'CommunityStore(storeId: $storeId, storeName: $storeName, latitude: $latitude, longitude: $longitude, storeAddress: $storeAddress, storePhone: $storePhone, couponCount: $couponCount, isFeatured: $isFeatured, isLocked: $isLocked, coupons: $coupons)';
}


}

/// @nodoc
abstract mixin class $CommunityStoreCopyWith<$Res>  {
  factory $CommunityStoreCopyWith(CommunityStore value, $Res Function(CommunityStore) _then) = _$CommunityStoreCopyWithImpl;
@useResult
$Res call({
 String storeId, String storeName, double latitude, double longitude, String? storeAddress, String? storePhone, int couponCount, bool isFeatured, bool isLocked, List<SharedCoupon> coupons
});




}
/// @nodoc
class _$CommunityStoreCopyWithImpl<$Res>
    implements $CommunityStoreCopyWith<$Res> {
  _$CommunityStoreCopyWithImpl(this._self, this._then);

  final CommunityStore _self;
  final $Res Function(CommunityStore) _then;

/// Create a copy of CommunityStore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? storeId = null,Object? storeName = null,Object? latitude = null,Object? longitude = null,Object? storeAddress = freezed,Object? storePhone = freezed,Object? couponCount = null,Object? isFeatured = null,Object? isLocked = null,Object? coupons = null,}) {
  return _then(_self.copyWith(
storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,storeAddress: freezed == storeAddress ? _self.storeAddress : storeAddress // ignore: cast_nullable_to_non_nullable
as String?,storePhone: freezed == storePhone ? _self.storePhone : storePhone // ignore: cast_nullable_to_non_nullable
as String?,couponCount: null == couponCount ? _self.couponCount : couponCount // ignore: cast_nullable_to_non_nullable
as int,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,coupons: null == coupons ? _self.coupons : coupons // ignore: cast_nullable_to_non_nullable
as List<SharedCoupon>,
  ));
}

}


/// Adds pattern-matching-related methods to [CommunityStore].
extension CommunityStorePatterns on CommunityStore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommunityStore value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommunityStore() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommunityStore value)  $default,){
final _that = this;
switch (_that) {
case _CommunityStore():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommunityStore value)?  $default,){
final _that = this;
switch (_that) {
case _CommunityStore() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String storeId,  String storeName,  double latitude,  double longitude,  String? storeAddress,  String? storePhone,  int couponCount,  bool isFeatured,  bool isLocked,  List<SharedCoupon> coupons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommunityStore() when $default != null:
return $default(_that.storeId,_that.storeName,_that.latitude,_that.longitude,_that.storeAddress,_that.storePhone,_that.couponCount,_that.isFeatured,_that.isLocked,_that.coupons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String storeId,  String storeName,  double latitude,  double longitude,  String? storeAddress,  String? storePhone,  int couponCount,  bool isFeatured,  bool isLocked,  List<SharedCoupon> coupons)  $default,) {final _that = this;
switch (_that) {
case _CommunityStore():
return $default(_that.storeId,_that.storeName,_that.latitude,_that.longitude,_that.storeAddress,_that.storePhone,_that.couponCount,_that.isFeatured,_that.isLocked,_that.coupons);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String storeId,  String storeName,  double latitude,  double longitude,  String? storeAddress,  String? storePhone,  int couponCount,  bool isFeatured,  bool isLocked,  List<SharedCoupon> coupons)?  $default,) {final _that = this;
switch (_that) {
case _CommunityStore() when $default != null:
return $default(_that.storeId,_that.storeName,_that.latitude,_that.longitude,_that.storeAddress,_that.storePhone,_that.couponCount,_that.isFeatured,_that.isLocked,_that.coupons);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommunityStore extends CommunityStore {
  const _CommunityStore({required this.storeId, required this.storeName, required this.latitude, required this.longitude, this.storeAddress, this.storePhone, this.couponCount = 0, this.isFeatured = false, this.isLocked = false, final  List<SharedCoupon> coupons = const []}): _coupons = coupons,super._();
  factory _CommunityStore.fromJson(Map<String, dynamic> json) => _$CommunityStoreFromJson(json);

@override final  String storeId;
@override final  String storeName;
@override final  double latitude;
@override final  double longitude;
@override final  String? storeAddress;
@override final  String? storePhone;
@override@JsonKey() final  int couponCount;
@override@JsonKey() final  bool isFeatured;
@override@JsonKey() final  bool isLocked;
 final  List<SharedCoupon> _coupons;
@override@JsonKey() List<SharedCoupon> get coupons {
  if (_coupons is EqualUnmodifiableListView) return _coupons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_coupons);
}


/// Create a copy of CommunityStore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommunityStoreCopyWith<_CommunityStore> get copyWith => __$CommunityStoreCopyWithImpl<_CommunityStore>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommunityStoreToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommunityStore&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.storeAddress, storeAddress) || other.storeAddress == storeAddress)&&(identical(other.storePhone, storePhone) || other.storePhone == storePhone)&&(identical(other.couponCount, couponCount) || other.couponCount == couponCount)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&const DeepCollectionEquality().equals(other._coupons, _coupons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,storeId,storeName,latitude,longitude,storeAddress,storePhone,couponCount,isFeatured,isLocked,const DeepCollectionEquality().hash(_coupons));

@override
String toString() {
  return 'CommunityStore(storeId: $storeId, storeName: $storeName, latitude: $latitude, longitude: $longitude, storeAddress: $storeAddress, storePhone: $storePhone, couponCount: $couponCount, isFeatured: $isFeatured, isLocked: $isLocked, coupons: $coupons)';
}


}

/// @nodoc
abstract mixin class _$CommunityStoreCopyWith<$Res> implements $CommunityStoreCopyWith<$Res> {
  factory _$CommunityStoreCopyWith(_CommunityStore value, $Res Function(_CommunityStore) _then) = __$CommunityStoreCopyWithImpl;
@override @useResult
$Res call({
 String storeId, String storeName, double latitude, double longitude, String? storeAddress, String? storePhone, int couponCount, bool isFeatured, bool isLocked, List<SharedCoupon> coupons
});




}
/// @nodoc
class __$CommunityStoreCopyWithImpl<$Res>
    implements _$CommunityStoreCopyWith<$Res> {
  __$CommunityStoreCopyWithImpl(this._self, this._then);

  final _CommunityStore _self;
  final $Res Function(_CommunityStore) _then;

/// Create a copy of CommunityStore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? storeId = null,Object? storeName = null,Object? latitude = null,Object? longitude = null,Object? storeAddress = freezed,Object? storePhone = freezed,Object? couponCount = null,Object? isFeatured = null,Object? isLocked = null,Object? coupons = null,}) {
  return _then(_CommunityStore(
storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,storeAddress: freezed == storeAddress ? _self.storeAddress : storeAddress // ignore: cast_nullable_to_non_nullable
as String?,storePhone: freezed == storePhone ? _self.storePhone : storePhone // ignore: cast_nullable_to_non_nullable
as String?,couponCount: null == couponCount ? _self.couponCount : couponCount // ignore: cast_nullable_to_non_nullable
as int,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,coupons: null == coupons ? _self._coupons : coupons // ignore: cast_nullable_to_non_nullable
as List<SharedCoupon>,
  ));
}


}


/// @nodoc
mixin _$SharedCoupon {

 String get couponId; String get storeName; String get description; int get discountAmount; int? get discountPercent; DateTime? get validFrom; DateTime? get validUntil; DateTime? get sharedAt; bool get isExpired;
/// Create a copy of SharedCoupon
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SharedCouponCopyWith<SharedCoupon> get copyWith => _$SharedCouponCopyWithImpl<SharedCoupon>(this as SharedCoupon, _$identity);

  /// Serializes this SharedCoupon to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedCoupon&&(identical(other.couponId, couponId) || other.couponId == couponId)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.description, description) || other.description == description)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountPercent, discountPercent) || other.discountPercent == discountPercent)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.sharedAt, sharedAt) || other.sharedAt == sharedAt)&&(identical(other.isExpired, isExpired) || other.isExpired == isExpired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,couponId,storeName,description,discountAmount,discountPercent,validFrom,validUntil,sharedAt,isExpired);

@override
String toString() {
  return 'SharedCoupon(couponId: $couponId, storeName: $storeName, description: $description, discountAmount: $discountAmount, discountPercent: $discountPercent, validFrom: $validFrom, validUntil: $validUntil, sharedAt: $sharedAt, isExpired: $isExpired)';
}


}

/// @nodoc
abstract mixin class $SharedCouponCopyWith<$Res>  {
  factory $SharedCouponCopyWith(SharedCoupon value, $Res Function(SharedCoupon) _then) = _$SharedCouponCopyWithImpl;
@useResult
$Res call({
 String couponId, String storeName, String description, int discountAmount, int? discountPercent, DateTime? validFrom, DateTime? validUntil, DateTime? sharedAt, bool isExpired
});




}
/// @nodoc
class _$SharedCouponCopyWithImpl<$Res>
    implements $SharedCouponCopyWith<$Res> {
  _$SharedCouponCopyWithImpl(this._self, this._then);

  final SharedCoupon _self;
  final $Res Function(SharedCoupon) _then;

/// Create a copy of SharedCoupon
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? couponId = null,Object? storeName = null,Object? description = null,Object? discountAmount = null,Object? discountPercent = freezed,Object? validFrom = freezed,Object? validUntil = freezed,Object? sharedAt = freezed,Object? isExpired = null,}) {
  return _then(_self.copyWith(
couponId: null == couponId ? _self.couponId : couponId // ignore: cast_nullable_to_non_nullable
as String,storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as int,discountPercent: freezed == discountPercent ? _self.discountPercent : discountPercent // ignore: cast_nullable_to_non_nullable
as int?,validFrom: freezed == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,sharedAt: freezed == sharedAt ? _self.sharedAt : sharedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isExpired: null == isExpired ? _self.isExpired : isExpired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SharedCoupon].
extension SharedCouponPatterns on SharedCoupon {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SharedCoupon value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SharedCoupon() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SharedCoupon value)  $default,){
final _that = this;
switch (_that) {
case _SharedCoupon():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SharedCoupon value)?  $default,){
final _that = this;
switch (_that) {
case _SharedCoupon() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String couponId,  String storeName,  String description,  int discountAmount,  int? discountPercent,  DateTime? validFrom,  DateTime? validUntil,  DateTime? sharedAt,  bool isExpired)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SharedCoupon() when $default != null:
return $default(_that.couponId,_that.storeName,_that.description,_that.discountAmount,_that.discountPercent,_that.validFrom,_that.validUntil,_that.sharedAt,_that.isExpired);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String couponId,  String storeName,  String description,  int discountAmount,  int? discountPercent,  DateTime? validFrom,  DateTime? validUntil,  DateTime? sharedAt,  bool isExpired)  $default,) {final _that = this;
switch (_that) {
case _SharedCoupon():
return $default(_that.couponId,_that.storeName,_that.description,_that.discountAmount,_that.discountPercent,_that.validFrom,_that.validUntil,_that.sharedAt,_that.isExpired);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String couponId,  String storeName,  String description,  int discountAmount,  int? discountPercent,  DateTime? validFrom,  DateTime? validUntil,  DateTime? sharedAt,  bool isExpired)?  $default,) {final _that = this;
switch (_that) {
case _SharedCoupon() when $default != null:
return $default(_that.couponId,_that.storeName,_that.description,_that.discountAmount,_that.discountPercent,_that.validFrom,_that.validUntil,_that.sharedAt,_that.isExpired);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SharedCoupon extends SharedCoupon {
  const _SharedCoupon({required this.couponId, required this.storeName, required this.description, required this.discountAmount, this.discountPercent, this.validFrom, this.validUntil, this.sharedAt, this.isExpired = false}): super._();
  factory _SharedCoupon.fromJson(Map<String, dynamic> json) => _$SharedCouponFromJson(json);

@override final  String couponId;
@override final  String storeName;
@override final  String description;
@override final  int discountAmount;
@override final  int? discountPercent;
@override final  DateTime? validFrom;
@override final  DateTime? validUntil;
@override final  DateTime? sharedAt;
@override@JsonKey() final  bool isExpired;

/// Create a copy of SharedCoupon
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SharedCouponCopyWith<_SharedCoupon> get copyWith => __$SharedCouponCopyWithImpl<_SharedCoupon>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SharedCouponToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SharedCoupon&&(identical(other.couponId, couponId) || other.couponId == couponId)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.description, description) || other.description == description)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountPercent, discountPercent) || other.discountPercent == discountPercent)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.sharedAt, sharedAt) || other.sharedAt == sharedAt)&&(identical(other.isExpired, isExpired) || other.isExpired == isExpired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,couponId,storeName,description,discountAmount,discountPercent,validFrom,validUntil,sharedAt,isExpired);

@override
String toString() {
  return 'SharedCoupon(couponId: $couponId, storeName: $storeName, description: $description, discountAmount: $discountAmount, discountPercent: $discountPercent, validFrom: $validFrom, validUntil: $validUntil, sharedAt: $sharedAt, isExpired: $isExpired)';
}


}

/// @nodoc
abstract mixin class _$SharedCouponCopyWith<$Res> implements $SharedCouponCopyWith<$Res> {
  factory _$SharedCouponCopyWith(_SharedCoupon value, $Res Function(_SharedCoupon) _then) = __$SharedCouponCopyWithImpl;
@override @useResult
$Res call({
 String couponId, String storeName, String description, int discountAmount, int? discountPercent, DateTime? validFrom, DateTime? validUntil, DateTime? sharedAt, bool isExpired
});




}
/// @nodoc
class __$SharedCouponCopyWithImpl<$Res>
    implements _$SharedCouponCopyWith<$Res> {
  __$SharedCouponCopyWithImpl(this._self, this._then);

  final _SharedCoupon _self;
  final $Res Function(_SharedCoupon) _then;

/// Create a copy of SharedCoupon
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? couponId = null,Object? storeName = null,Object? description = null,Object? discountAmount = null,Object? discountPercent = freezed,Object? validFrom = freezed,Object? validUntil = freezed,Object? sharedAt = freezed,Object? isExpired = null,}) {
  return _then(_SharedCoupon(
couponId: null == couponId ? _self.couponId : couponId // ignore: cast_nullable_to_non_nullable
as String,storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as int,discountPercent: freezed == discountPercent ? _self.discountPercent : discountPercent // ignore: cast_nullable_to_non_nullable
as int?,validFrom: freezed == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,sharedAt: freezed == sharedAt ? _self.sharedAt : sharedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isExpired: null == isExpired ? _self.isExpired : isExpired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$CommunitySettings {

 bool get shareEnabled; bool get notifyAll; List<String> get selectedStoreIds; List<String> get notifiedStoreIds;@JsonKey(includeToJson: false) int get remainingChanges;@JsonKey(includeToJson: false) DateTime? get nextResetDate;@JsonKey(includeToJson: false) bool get isPremium;
/// Create a copy of CommunitySettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommunitySettingsCopyWith<CommunitySettings> get copyWith => _$CommunitySettingsCopyWithImpl<CommunitySettings>(this as CommunitySettings, _$identity);

  /// Serializes this CommunitySettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommunitySettings&&(identical(other.shareEnabled, shareEnabled) || other.shareEnabled == shareEnabled)&&(identical(other.notifyAll, notifyAll) || other.notifyAll == notifyAll)&&const DeepCollectionEquality().equals(other.selectedStoreIds, selectedStoreIds)&&const DeepCollectionEquality().equals(other.notifiedStoreIds, notifiedStoreIds)&&(identical(other.remainingChanges, remainingChanges) || other.remainingChanges == remainingChanges)&&(identical(other.nextResetDate, nextResetDate) || other.nextResetDate == nextResetDate)&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,shareEnabled,notifyAll,const DeepCollectionEquality().hash(selectedStoreIds),const DeepCollectionEquality().hash(notifiedStoreIds),remainingChanges,nextResetDate,isPremium);

@override
String toString() {
  return 'CommunitySettings(shareEnabled: $shareEnabled, notifyAll: $notifyAll, selectedStoreIds: $selectedStoreIds, notifiedStoreIds: $notifiedStoreIds, remainingChanges: $remainingChanges, nextResetDate: $nextResetDate, isPremium: $isPremium)';
}


}

/// @nodoc
abstract mixin class $CommunitySettingsCopyWith<$Res>  {
  factory $CommunitySettingsCopyWith(CommunitySettings value, $Res Function(CommunitySettings) _then) = _$CommunitySettingsCopyWithImpl;
@useResult
$Res call({
 bool shareEnabled, bool notifyAll, List<String> selectedStoreIds, List<String> notifiedStoreIds,@JsonKey(includeToJson: false) int remainingChanges,@JsonKey(includeToJson: false) DateTime? nextResetDate,@JsonKey(includeToJson: false) bool isPremium
});




}
/// @nodoc
class _$CommunitySettingsCopyWithImpl<$Res>
    implements $CommunitySettingsCopyWith<$Res> {
  _$CommunitySettingsCopyWithImpl(this._self, this._then);

  final CommunitySettings _self;
  final $Res Function(CommunitySettings) _then;

/// Create a copy of CommunitySettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shareEnabled = null,Object? notifyAll = null,Object? selectedStoreIds = null,Object? notifiedStoreIds = null,Object? remainingChanges = null,Object? nextResetDate = freezed,Object? isPremium = null,}) {
  return _then(_self.copyWith(
shareEnabled: null == shareEnabled ? _self.shareEnabled : shareEnabled // ignore: cast_nullable_to_non_nullable
as bool,notifyAll: null == notifyAll ? _self.notifyAll : notifyAll // ignore: cast_nullable_to_non_nullable
as bool,selectedStoreIds: null == selectedStoreIds ? _self.selectedStoreIds : selectedStoreIds // ignore: cast_nullable_to_non_nullable
as List<String>,notifiedStoreIds: null == notifiedStoreIds ? _self.notifiedStoreIds : notifiedStoreIds // ignore: cast_nullable_to_non_nullable
as List<String>,remainingChanges: null == remainingChanges ? _self.remainingChanges : remainingChanges // ignore: cast_nullable_to_non_nullable
as int,nextResetDate: freezed == nextResetDate ? _self.nextResetDate : nextResetDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CommunitySettings].
extension CommunitySettingsPatterns on CommunitySettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommunitySettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommunitySettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommunitySettings value)  $default,){
final _that = this;
switch (_that) {
case _CommunitySettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommunitySettings value)?  $default,){
final _that = this;
switch (_that) {
case _CommunitySettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool shareEnabled,  bool notifyAll,  List<String> selectedStoreIds,  List<String> notifiedStoreIds, @JsonKey(includeToJson: false)  int remainingChanges, @JsonKey(includeToJson: false)  DateTime? nextResetDate, @JsonKey(includeToJson: false)  bool isPremium)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommunitySettings() when $default != null:
return $default(_that.shareEnabled,_that.notifyAll,_that.selectedStoreIds,_that.notifiedStoreIds,_that.remainingChanges,_that.nextResetDate,_that.isPremium);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool shareEnabled,  bool notifyAll,  List<String> selectedStoreIds,  List<String> notifiedStoreIds, @JsonKey(includeToJson: false)  int remainingChanges, @JsonKey(includeToJson: false)  DateTime? nextResetDate, @JsonKey(includeToJson: false)  bool isPremium)  $default,) {final _that = this;
switch (_that) {
case _CommunitySettings():
return $default(_that.shareEnabled,_that.notifyAll,_that.selectedStoreIds,_that.notifiedStoreIds,_that.remainingChanges,_that.nextResetDate,_that.isPremium);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool shareEnabled,  bool notifyAll,  List<String> selectedStoreIds,  List<String> notifiedStoreIds, @JsonKey(includeToJson: false)  int remainingChanges, @JsonKey(includeToJson: false)  DateTime? nextResetDate, @JsonKey(includeToJson: false)  bool isPremium)?  $default,) {final _that = this;
switch (_that) {
case _CommunitySettings() when $default != null:
return $default(_that.shareEnabled,_that.notifyAll,_that.selectedStoreIds,_that.notifiedStoreIds,_that.remainingChanges,_that.nextResetDate,_that.isPremium);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommunitySettings implements CommunitySettings {
  const _CommunitySettings({this.shareEnabled = true, this.notifyAll = true, final  List<String> selectedStoreIds = const [], final  List<String> notifiedStoreIds = const [], @JsonKey(includeToJson: false) this.remainingChanges = 3, @JsonKey(includeToJson: false) this.nextResetDate, @JsonKey(includeToJson: false) this.isPremium = false}): _selectedStoreIds = selectedStoreIds,_notifiedStoreIds = notifiedStoreIds;
  factory _CommunitySettings.fromJson(Map<String, dynamic> json) => _$CommunitySettingsFromJson(json);

@override@JsonKey() final  bool shareEnabled;
@override@JsonKey() final  bool notifyAll;
 final  List<String> _selectedStoreIds;
@override@JsonKey() List<String> get selectedStoreIds {
  if (_selectedStoreIds is EqualUnmodifiableListView) return _selectedStoreIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedStoreIds);
}

 final  List<String> _notifiedStoreIds;
@override@JsonKey() List<String> get notifiedStoreIds {
  if (_notifiedStoreIds is EqualUnmodifiableListView) return _notifiedStoreIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notifiedStoreIds);
}

@override@JsonKey(includeToJson: false) final  int remainingChanges;
@override@JsonKey(includeToJson: false) final  DateTime? nextResetDate;
@override@JsonKey(includeToJson: false) final  bool isPremium;

/// Create a copy of CommunitySettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommunitySettingsCopyWith<_CommunitySettings> get copyWith => __$CommunitySettingsCopyWithImpl<_CommunitySettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommunitySettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommunitySettings&&(identical(other.shareEnabled, shareEnabled) || other.shareEnabled == shareEnabled)&&(identical(other.notifyAll, notifyAll) || other.notifyAll == notifyAll)&&const DeepCollectionEquality().equals(other._selectedStoreIds, _selectedStoreIds)&&const DeepCollectionEquality().equals(other._notifiedStoreIds, _notifiedStoreIds)&&(identical(other.remainingChanges, remainingChanges) || other.remainingChanges == remainingChanges)&&(identical(other.nextResetDate, nextResetDate) || other.nextResetDate == nextResetDate)&&(identical(other.isPremium, isPremium) || other.isPremium == isPremium));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,shareEnabled,notifyAll,const DeepCollectionEquality().hash(_selectedStoreIds),const DeepCollectionEquality().hash(_notifiedStoreIds),remainingChanges,nextResetDate,isPremium);

@override
String toString() {
  return 'CommunitySettings(shareEnabled: $shareEnabled, notifyAll: $notifyAll, selectedStoreIds: $selectedStoreIds, notifiedStoreIds: $notifiedStoreIds, remainingChanges: $remainingChanges, nextResetDate: $nextResetDate, isPremium: $isPremium)';
}


}

/// @nodoc
abstract mixin class _$CommunitySettingsCopyWith<$Res> implements $CommunitySettingsCopyWith<$Res> {
  factory _$CommunitySettingsCopyWith(_CommunitySettings value, $Res Function(_CommunitySettings) _then) = __$CommunitySettingsCopyWithImpl;
@override @useResult
$Res call({
 bool shareEnabled, bool notifyAll, List<String> selectedStoreIds, List<String> notifiedStoreIds,@JsonKey(includeToJson: false) int remainingChanges,@JsonKey(includeToJson: false) DateTime? nextResetDate,@JsonKey(includeToJson: false) bool isPremium
});




}
/// @nodoc
class __$CommunitySettingsCopyWithImpl<$Res>
    implements _$CommunitySettingsCopyWith<$Res> {
  __$CommunitySettingsCopyWithImpl(this._self, this._then);

  final _CommunitySettings _self;
  final $Res Function(_CommunitySettings) _then;

/// Create a copy of CommunitySettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shareEnabled = null,Object? notifyAll = null,Object? selectedStoreIds = null,Object? notifiedStoreIds = null,Object? remainingChanges = null,Object? nextResetDate = freezed,Object? isPremium = null,}) {
  return _then(_CommunitySettings(
shareEnabled: null == shareEnabled ? _self.shareEnabled : shareEnabled // ignore: cast_nullable_to_non_nullable
as bool,notifyAll: null == notifyAll ? _self.notifyAll : notifyAll // ignore: cast_nullable_to_non_nullable
as bool,selectedStoreIds: null == selectedStoreIds ? _self._selectedStoreIds : selectedStoreIds // ignore: cast_nullable_to_non_nullable
as List<String>,notifiedStoreIds: null == notifiedStoreIds ? _self._notifiedStoreIds : notifiedStoreIds // ignore: cast_nullable_to_non_nullable
as List<String>,remainingChanges: null == remainingChanges ? _self.remainingChanges : remainingChanges // ignore: cast_nullable_to_non_nullable
as int,nextResetDate: freezed == nextResetDate ? _self.nextResetDate : nextResetDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isPremium: null == isPremium ? _self.isPremium : isPremium // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

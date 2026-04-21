// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReceiptItem {

 String get itemName; String get itemNameRaw; String get category; int get unitPrice; int get quantity; int get amount; int get points;
/// Create a copy of ReceiptItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptItemCopyWith<ReceiptItem> get copyWith => _$ReceiptItemCopyWithImpl<ReceiptItem>(this as ReceiptItem, _$identity);

  /// Serializes this ReceiptItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptItem&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.itemNameRaw, itemNameRaw) || other.itemNameRaw == itemNameRaw)&&(identical(other.category, category) || other.category == category)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.points, points) || other.points == points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemName,itemNameRaw,category,unitPrice,quantity,amount,points);

@override
String toString() {
  return 'ReceiptItem(itemName: $itemName, itemNameRaw: $itemNameRaw, category: $category, unitPrice: $unitPrice, quantity: $quantity, amount: $amount, points: $points)';
}


}

/// @nodoc
abstract mixin class $ReceiptItemCopyWith<$Res>  {
  factory $ReceiptItemCopyWith(ReceiptItem value, $Res Function(ReceiptItem) _then) = _$ReceiptItemCopyWithImpl;
@useResult
$Res call({
 String itemName, String itemNameRaw, String category, int unitPrice, int quantity, int amount, int points
});




}
/// @nodoc
class _$ReceiptItemCopyWithImpl<$Res>
    implements $ReceiptItemCopyWith<$Res> {
  _$ReceiptItemCopyWithImpl(this._self, this._then);

  final ReceiptItem _self;
  final $Res Function(ReceiptItem) _then;

/// Create a copy of ReceiptItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemName = null,Object? itemNameRaw = null,Object? category = null,Object? unitPrice = null,Object? quantity = null,Object? amount = null,Object? points = null,}) {
  return _then(_self.copyWith(
itemName: null == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String,itemNameRaw: null == itemNameRaw ? _self.itemNameRaw : itemNameRaw // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceiptItem].
extension ReceiptItemPatterns on ReceiptItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptItem value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptItem value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemName,  String itemNameRaw,  String category,  int unitPrice,  int quantity,  int amount,  int points)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptItem() when $default != null:
return $default(_that.itemName,_that.itemNameRaw,_that.category,_that.unitPrice,_that.quantity,_that.amount,_that.points);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemName,  String itemNameRaw,  String category,  int unitPrice,  int quantity,  int amount,  int points)  $default,) {final _that = this;
switch (_that) {
case _ReceiptItem():
return $default(_that.itemName,_that.itemNameRaw,_that.category,_that.unitPrice,_that.quantity,_that.amount,_that.points);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemName,  String itemNameRaw,  String category,  int unitPrice,  int quantity,  int amount,  int points)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptItem() when $default != null:
return $default(_that.itemName,_that.itemNameRaw,_that.category,_that.unitPrice,_that.quantity,_that.amount,_that.points);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReceiptItem implements ReceiptItem {
  const _ReceiptItem({required this.itemName, this.itemNameRaw = '', this.category = 'other', required this.unitPrice, required this.quantity, required this.amount, this.points = 0});
  factory _ReceiptItem.fromJson(Map<String, dynamic> json) => _$ReceiptItemFromJson(json);

@override final  String itemName;
@override@JsonKey() final  String itemNameRaw;
@override@JsonKey() final  String category;
@override final  int unitPrice;
@override final  int quantity;
@override final  int amount;
@override@JsonKey() final  int points;

/// Create a copy of ReceiptItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptItemCopyWith<_ReceiptItem> get copyWith => __$ReceiptItemCopyWithImpl<_ReceiptItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptItem&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.itemNameRaw, itemNameRaw) || other.itemNameRaw == itemNameRaw)&&(identical(other.category, category) || other.category == category)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.points, points) || other.points == points));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemName,itemNameRaw,category,unitPrice,quantity,amount,points);

@override
String toString() {
  return 'ReceiptItem(itemName: $itemName, itemNameRaw: $itemNameRaw, category: $category, unitPrice: $unitPrice, quantity: $quantity, amount: $amount, points: $points)';
}


}

/// @nodoc
abstract mixin class _$ReceiptItemCopyWith<$Res> implements $ReceiptItemCopyWith<$Res> {
  factory _$ReceiptItemCopyWith(_ReceiptItem value, $Res Function(_ReceiptItem) _then) = __$ReceiptItemCopyWithImpl;
@override @useResult
$Res call({
 String itemName, String itemNameRaw, String category, int unitPrice, int quantity, int amount, int points
});




}
/// @nodoc
class __$ReceiptItemCopyWithImpl<$Res>
    implements _$ReceiptItemCopyWith<$Res> {
  __$ReceiptItemCopyWithImpl(this._self, this._then);

  final _ReceiptItem _self;
  final $Res Function(_ReceiptItem) _then;

/// Create a copy of ReceiptItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemName = null,Object? itemNameRaw = null,Object? category = null,Object? unitPrice = null,Object? quantity = null,Object? amount = null,Object? points = null,}) {
  return _then(_ReceiptItem(
itemName: null == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String,itemNameRaw: null == itemNameRaw ? _self.itemNameRaw : itemNameRaw // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CouponDetected {

 String get description; int get discountAmount; String? get discountUnit; String? get validFrom; String? get validUntil; String? get storageLocation; bool get requiresSurvey; String? get surveyUrl;
/// Create a copy of CouponDetected
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CouponDetectedCopyWith<CouponDetected> get copyWith => _$CouponDetectedCopyWithImpl<CouponDetected>(this as CouponDetected, _$identity);

  /// Serializes this CouponDetected to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CouponDetected&&(identical(other.description, description) || other.description == description)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountUnit, discountUnit) || other.discountUnit == discountUnit)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.storageLocation, storageLocation) || other.storageLocation == storageLocation)&&(identical(other.requiresSurvey, requiresSurvey) || other.requiresSurvey == requiresSurvey)&&(identical(other.surveyUrl, surveyUrl) || other.surveyUrl == surveyUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,discountAmount,discountUnit,validFrom,validUntil,storageLocation,requiresSurvey,surveyUrl);

@override
String toString() {
  return 'CouponDetected(description: $description, discountAmount: $discountAmount, discountUnit: $discountUnit, validFrom: $validFrom, validUntil: $validUntil, storageLocation: $storageLocation, requiresSurvey: $requiresSurvey, surveyUrl: $surveyUrl)';
}


}

/// @nodoc
abstract mixin class $CouponDetectedCopyWith<$Res>  {
  factory $CouponDetectedCopyWith(CouponDetected value, $Res Function(CouponDetected) _then) = _$CouponDetectedCopyWithImpl;
@useResult
$Res call({
 String description, int discountAmount, String? discountUnit, String? validFrom, String? validUntil, String? storageLocation, bool requiresSurvey, String? surveyUrl
});




}
/// @nodoc
class _$CouponDetectedCopyWithImpl<$Res>
    implements $CouponDetectedCopyWith<$Res> {
  _$CouponDetectedCopyWithImpl(this._self, this._then);

  final CouponDetected _self;
  final $Res Function(CouponDetected) _then;

/// Create a copy of CouponDetected
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? description = null,Object? discountAmount = null,Object? discountUnit = freezed,Object? validFrom = freezed,Object? validUntil = freezed,Object? storageLocation = freezed,Object? requiresSurvey = null,Object? surveyUrl = freezed,}) {
  return _then(_self.copyWith(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as int,discountUnit: freezed == discountUnit ? _self.discountUnit : discountUnit // ignore: cast_nullable_to_non_nullable
as String?,validFrom: freezed == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as String?,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as String?,storageLocation: freezed == storageLocation ? _self.storageLocation : storageLocation // ignore: cast_nullable_to_non_nullable
as String?,requiresSurvey: null == requiresSurvey ? _self.requiresSurvey : requiresSurvey // ignore: cast_nullable_to_non_nullable
as bool,surveyUrl: freezed == surveyUrl ? _self.surveyUrl : surveyUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CouponDetected].
extension CouponDetectedPatterns on CouponDetected {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CouponDetected value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CouponDetected() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CouponDetected value)  $default,){
final _that = this;
switch (_that) {
case _CouponDetected():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CouponDetected value)?  $default,){
final _that = this;
switch (_that) {
case _CouponDetected() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String description,  int discountAmount,  String? discountUnit,  String? validFrom,  String? validUntil,  String? storageLocation,  bool requiresSurvey,  String? surveyUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CouponDetected() when $default != null:
return $default(_that.description,_that.discountAmount,_that.discountUnit,_that.validFrom,_that.validUntil,_that.storageLocation,_that.requiresSurvey,_that.surveyUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String description,  int discountAmount,  String? discountUnit,  String? validFrom,  String? validUntil,  String? storageLocation,  bool requiresSurvey,  String? surveyUrl)  $default,) {final _that = this;
switch (_that) {
case _CouponDetected():
return $default(_that.description,_that.discountAmount,_that.discountUnit,_that.validFrom,_that.validUntil,_that.storageLocation,_that.requiresSurvey,_that.surveyUrl);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String description,  int discountAmount,  String? discountUnit,  String? validFrom,  String? validUntil,  String? storageLocation,  bool requiresSurvey,  String? surveyUrl)?  $default,) {final _that = this;
switch (_that) {
case _CouponDetected() when $default != null:
return $default(_that.description,_that.discountAmount,_that.discountUnit,_that.validFrom,_that.validUntil,_that.storageLocation,_that.requiresSurvey,_that.surveyUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CouponDetected implements CouponDetected {
  const _CouponDetected({required this.description, required this.discountAmount, this.discountUnit = 'yen', this.validFrom, this.validUntil, this.storageLocation, this.requiresSurvey = false, this.surveyUrl});
  factory _CouponDetected.fromJson(Map<String, dynamic> json) => _$CouponDetectedFromJson(json);

@override final  String description;
@override final  int discountAmount;
@override@JsonKey() final  String? discountUnit;
@override final  String? validFrom;
@override final  String? validUntil;
@override final  String? storageLocation;
@override@JsonKey() final  bool requiresSurvey;
@override final  String? surveyUrl;

/// Create a copy of CouponDetected
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CouponDetectedCopyWith<_CouponDetected> get copyWith => __$CouponDetectedCopyWithImpl<_CouponDetected>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CouponDetectedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CouponDetected&&(identical(other.description, description) || other.description == description)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountUnit, discountUnit) || other.discountUnit == discountUnit)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.storageLocation, storageLocation) || other.storageLocation == storageLocation)&&(identical(other.requiresSurvey, requiresSurvey) || other.requiresSurvey == requiresSurvey)&&(identical(other.surveyUrl, surveyUrl) || other.surveyUrl == surveyUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,discountAmount,discountUnit,validFrom,validUntil,storageLocation,requiresSurvey,surveyUrl);

@override
String toString() {
  return 'CouponDetected(description: $description, discountAmount: $discountAmount, discountUnit: $discountUnit, validFrom: $validFrom, validUntil: $validUntil, storageLocation: $storageLocation, requiresSurvey: $requiresSurvey, surveyUrl: $surveyUrl)';
}


}

/// @nodoc
abstract mixin class _$CouponDetectedCopyWith<$Res> implements $CouponDetectedCopyWith<$Res> {
  factory _$CouponDetectedCopyWith(_CouponDetected value, $Res Function(_CouponDetected) _then) = __$CouponDetectedCopyWithImpl;
@override @useResult
$Res call({
 String description, int discountAmount, String? discountUnit, String? validFrom, String? validUntil, String? storageLocation, bool requiresSurvey, String? surveyUrl
});




}
/// @nodoc
class __$CouponDetectedCopyWithImpl<$Res>
    implements _$CouponDetectedCopyWith<$Res> {
  __$CouponDetectedCopyWithImpl(this._self, this._then);

  final _CouponDetected _self;
  final $Res Function(_CouponDetected) _then;

/// Create a copy of CouponDetected
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? description = null,Object? discountAmount = null,Object? discountUnit = freezed,Object? validFrom = freezed,Object? validUntil = freezed,Object? storageLocation = freezed,Object? requiresSurvey = null,Object? surveyUrl = freezed,}) {
  return _then(_CouponDetected(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as int,discountUnit: freezed == discountUnit ? _self.discountUnit : discountUnit // ignore: cast_nullable_to_non_nullable
as String?,validFrom: freezed == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as String?,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as String?,storageLocation: freezed == storageLocation ? _self.storageLocation : storageLocation // ignore: cast_nullable_to_non_nullable
as String?,requiresSurvey: null == requiresSurvey ? _self.requiresSurvey : requiresSurvey // ignore: cast_nullable_to_non_nullable
as bool,surveyUrl: freezed == surveyUrl ? _self.surveyUrl : surveyUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$LinePromotion {

 String get description; String? get lineUrl;
/// Create a copy of LinePromotion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinePromotionCopyWith<LinePromotion> get copyWith => _$LinePromotionCopyWithImpl<LinePromotion>(this as LinePromotion, _$identity);

  /// Serializes this LinePromotion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinePromotion&&(identical(other.description, description) || other.description == description)&&(identical(other.lineUrl, lineUrl) || other.lineUrl == lineUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,lineUrl);

@override
String toString() {
  return 'LinePromotion(description: $description, lineUrl: $lineUrl)';
}


}

/// @nodoc
abstract mixin class $LinePromotionCopyWith<$Res>  {
  factory $LinePromotionCopyWith(LinePromotion value, $Res Function(LinePromotion) _then) = _$LinePromotionCopyWithImpl;
@useResult
$Res call({
 String description, String? lineUrl
});




}
/// @nodoc
class _$LinePromotionCopyWithImpl<$Res>
    implements $LinePromotionCopyWith<$Res> {
  _$LinePromotionCopyWithImpl(this._self, this._then);

  final LinePromotion _self;
  final $Res Function(LinePromotion) _then;

/// Create a copy of LinePromotion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? description = null,Object? lineUrl = freezed,}) {
  return _then(_self.copyWith(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,lineUrl: freezed == lineUrl ? _self.lineUrl : lineUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LinePromotion].
extension LinePromotionPatterns on LinePromotion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinePromotion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinePromotion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinePromotion value)  $default,){
final _that = this;
switch (_that) {
case _LinePromotion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinePromotion value)?  $default,){
final _that = this;
switch (_that) {
case _LinePromotion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String description,  String? lineUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinePromotion() when $default != null:
return $default(_that.description,_that.lineUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String description,  String? lineUrl)  $default,) {final _that = this;
switch (_that) {
case _LinePromotion():
return $default(_that.description,_that.lineUrl);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String description,  String? lineUrl)?  $default,) {final _that = this;
switch (_that) {
case _LinePromotion() when $default != null:
return $default(_that.description,_that.lineUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LinePromotion implements LinePromotion {
  const _LinePromotion({required this.description, this.lineUrl});
  factory _LinePromotion.fromJson(Map<String, dynamic> json) => _$LinePromotionFromJson(json);

@override final  String description;
@override final  String? lineUrl;

/// Create a copy of LinePromotion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinePromotionCopyWith<_LinePromotion> get copyWith => __$LinePromotionCopyWithImpl<_LinePromotion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LinePromotionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinePromotion&&(identical(other.description, description) || other.description == description)&&(identical(other.lineUrl, lineUrl) || other.lineUrl == lineUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,lineUrl);

@override
String toString() {
  return 'LinePromotion(description: $description, lineUrl: $lineUrl)';
}


}

/// @nodoc
abstract mixin class _$LinePromotionCopyWith<$Res> implements $LinePromotionCopyWith<$Res> {
  factory _$LinePromotionCopyWith(_LinePromotion value, $Res Function(_LinePromotion) _then) = __$LinePromotionCopyWithImpl;
@override @useResult
$Res call({
 String description, String? lineUrl
});




}
/// @nodoc
class __$LinePromotionCopyWithImpl<$Res>
    implements _$LinePromotionCopyWith<$Res> {
  __$LinePromotionCopyWithImpl(this._self, this._then);

  final _LinePromotion _self;
  final $Res Function(_LinePromotion) _then;

/// Create a copy of LinePromotion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? description = null,Object? lineUrl = freezed,}) {
  return _then(_LinePromotion(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,lineUrl: freezed == lineUrl ? _self.lineUrl : lineUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ReceiptDiscount {

 String get description; int get discountAmount;
/// Create a copy of ReceiptDiscount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptDiscountCopyWith<ReceiptDiscount> get copyWith => _$ReceiptDiscountCopyWithImpl<ReceiptDiscount>(this as ReceiptDiscount, _$identity);

  /// Serializes this ReceiptDiscount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptDiscount&&(identical(other.description, description) || other.description == description)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,discountAmount);

@override
String toString() {
  return 'ReceiptDiscount(description: $description, discountAmount: $discountAmount)';
}


}

/// @nodoc
abstract mixin class $ReceiptDiscountCopyWith<$Res>  {
  factory $ReceiptDiscountCopyWith(ReceiptDiscount value, $Res Function(ReceiptDiscount) _then) = _$ReceiptDiscountCopyWithImpl;
@useResult
$Res call({
 String description, int discountAmount
});




}
/// @nodoc
class _$ReceiptDiscountCopyWithImpl<$Res>
    implements $ReceiptDiscountCopyWith<$Res> {
  _$ReceiptDiscountCopyWithImpl(this._self, this._then);

  final ReceiptDiscount _self;
  final $Res Function(ReceiptDiscount) _then;

/// Create a copy of ReceiptDiscount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? description = null,Object? discountAmount = null,}) {
  return _then(_self.copyWith(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceiptDiscount].
extension ReceiptDiscountPatterns on ReceiptDiscount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptDiscount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptDiscount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptDiscount value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptDiscount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptDiscount value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptDiscount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String description,  int discountAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptDiscount() when $default != null:
return $default(_that.description,_that.discountAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String description,  int discountAmount)  $default,) {final _that = this;
switch (_that) {
case _ReceiptDiscount():
return $default(_that.description,_that.discountAmount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String description,  int discountAmount)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptDiscount() when $default != null:
return $default(_that.description,_that.discountAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReceiptDiscount implements ReceiptDiscount {
  const _ReceiptDiscount({required this.description, required this.discountAmount});
  factory _ReceiptDiscount.fromJson(Map<String, dynamic> json) => _$ReceiptDiscountFromJson(json);

@override final  String description;
@override final  int discountAmount;

/// Create a copy of ReceiptDiscount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptDiscountCopyWith<_ReceiptDiscount> get copyWith => __$ReceiptDiscountCopyWithImpl<_ReceiptDiscount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptDiscountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptDiscount&&(identical(other.description, description) || other.description == description)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,discountAmount);

@override
String toString() {
  return 'ReceiptDiscount(description: $description, discountAmount: $discountAmount)';
}


}

/// @nodoc
abstract mixin class _$ReceiptDiscountCopyWith<$Res> implements $ReceiptDiscountCopyWith<$Res> {
  factory _$ReceiptDiscountCopyWith(_ReceiptDiscount value, $Res Function(_ReceiptDiscount) _then) = __$ReceiptDiscountCopyWithImpl;
@override @useResult
$Res call({
 String description, int discountAmount
});




}
/// @nodoc
class __$ReceiptDiscountCopyWithImpl<$Res>
    implements _$ReceiptDiscountCopyWith<$Res> {
  __$ReceiptDiscountCopyWithImpl(this._self, this._then);

  final _ReceiptDiscount _self;
  final $Res Function(_ReceiptDiscount) _then;

/// Create a copy of ReceiptDiscount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? description = null,Object? discountAmount = null,}) {
  return _then(_ReceiptDiscount(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ReceiptAnalysis {

 String get storeName; String get purchasedAt; int get totalAmount;@JsonKey(includeIfNull: false) int? get taxAmount; String get paymentMethod;@JsonKey(includeIfNull: false) String? get category; List<ReceiptItem> get items; List<CouponDetected> get couponsDetected; List<LinePromotion> get linePromotions; String get duplicateCheckHash; bool get isMedical; bool get isUncovered;@JsonKey(includeIfNull: false) int? get totalPoints;@JsonKey(includeIfNull: false) double? get burdenRate;@JsonKey(includeIfNull: false) String? get memo; bool get isBill;@JsonKey(includeIfNull: false) DateTime? get billDueDate; String get billStatus;@JsonKey(includeIfNull: false) DateTime? get billPaidDate; bool get billIsTaxExempt; int get savingsAmount;
/// Create a copy of ReceiptAnalysis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptAnalysisCopyWith<ReceiptAnalysis> get copyWith => _$ReceiptAnalysisCopyWithImpl<ReceiptAnalysis>(this as ReceiptAnalysis, _$identity);

  /// Serializes this ReceiptAnalysis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptAnalysis&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.taxAmount, taxAmount) || other.taxAmount == taxAmount)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.couponsDetected, couponsDetected)&&const DeepCollectionEquality().equals(other.linePromotions, linePromotions)&&(identical(other.duplicateCheckHash, duplicateCheckHash) || other.duplicateCheckHash == duplicateCheckHash)&&(identical(other.isMedical, isMedical) || other.isMedical == isMedical)&&(identical(other.isUncovered, isUncovered) || other.isUncovered == isUncovered)&&(identical(other.totalPoints, totalPoints) || other.totalPoints == totalPoints)&&(identical(other.burdenRate, burdenRate) || other.burdenRate == burdenRate)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.isBill, isBill) || other.isBill == isBill)&&(identical(other.billDueDate, billDueDate) || other.billDueDate == billDueDate)&&(identical(other.billStatus, billStatus) || other.billStatus == billStatus)&&(identical(other.billPaidDate, billPaidDate) || other.billPaidDate == billPaidDate)&&(identical(other.billIsTaxExempt, billIsTaxExempt) || other.billIsTaxExempt == billIsTaxExempt)&&(identical(other.savingsAmount, savingsAmount) || other.savingsAmount == savingsAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,storeName,purchasedAt,totalAmount,taxAmount,paymentMethod,category,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(couponsDetected),const DeepCollectionEquality().hash(linePromotions),duplicateCheckHash,isMedical,isUncovered,totalPoints,burdenRate,memo,isBill,billDueDate,billStatus,billPaidDate,billIsTaxExempt,savingsAmount]);

@override
String toString() {
  return 'ReceiptAnalysis(storeName: $storeName, purchasedAt: $purchasedAt, totalAmount: $totalAmount, taxAmount: $taxAmount, paymentMethod: $paymentMethod, category: $category, items: $items, couponsDetected: $couponsDetected, linePromotions: $linePromotions, duplicateCheckHash: $duplicateCheckHash, isMedical: $isMedical, isUncovered: $isUncovered, totalPoints: $totalPoints, burdenRate: $burdenRate, memo: $memo, isBill: $isBill, billDueDate: $billDueDate, billStatus: $billStatus, billPaidDate: $billPaidDate, billIsTaxExempt: $billIsTaxExempt, savingsAmount: $savingsAmount)';
}


}

/// @nodoc
abstract mixin class $ReceiptAnalysisCopyWith<$Res>  {
  factory $ReceiptAnalysisCopyWith(ReceiptAnalysis value, $Res Function(ReceiptAnalysis) _then) = _$ReceiptAnalysisCopyWithImpl;
@useResult
$Res call({
 String storeName, String purchasedAt, int totalAmount,@JsonKey(includeIfNull: false) int? taxAmount, String paymentMethod,@JsonKey(includeIfNull: false) String? category, List<ReceiptItem> items, List<CouponDetected> couponsDetected, List<LinePromotion> linePromotions, String duplicateCheckHash, bool isMedical, bool isUncovered,@JsonKey(includeIfNull: false) int? totalPoints,@JsonKey(includeIfNull: false) double? burdenRate,@JsonKey(includeIfNull: false) String? memo, bool isBill,@JsonKey(includeIfNull: false) DateTime? billDueDate, String billStatus,@JsonKey(includeIfNull: false) DateTime? billPaidDate, bool billIsTaxExempt, int savingsAmount
});




}
/// @nodoc
class _$ReceiptAnalysisCopyWithImpl<$Res>
    implements $ReceiptAnalysisCopyWith<$Res> {
  _$ReceiptAnalysisCopyWithImpl(this._self, this._then);

  final ReceiptAnalysis _self;
  final $Res Function(ReceiptAnalysis) _then;

/// Create a copy of ReceiptAnalysis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? storeName = null,Object? purchasedAt = null,Object? totalAmount = null,Object? taxAmount = freezed,Object? paymentMethod = null,Object? category = freezed,Object? items = null,Object? couponsDetected = null,Object? linePromotions = null,Object? duplicateCheckHash = null,Object? isMedical = null,Object? isUncovered = null,Object? totalPoints = freezed,Object? burdenRate = freezed,Object? memo = freezed,Object? isBill = null,Object? billDueDate = freezed,Object? billStatus = null,Object? billPaidDate = freezed,Object? billIsTaxExempt = null,Object? savingsAmount = null,}) {
  return _then(_self.copyWith(
storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,purchasedAt: null == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,taxAmount: freezed == taxAmount ? _self.taxAmount : taxAmount // ignore: cast_nullable_to_non_nullable
as int?,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ReceiptItem>,couponsDetected: null == couponsDetected ? _self.couponsDetected : couponsDetected // ignore: cast_nullable_to_non_nullable
as List<CouponDetected>,linePromotions: null == linePromotions ? _self.linePromotions : linePromotions // ignore: cast_nullable_to_non_nullable
as List<LinePromotion>,duplicateCheckHash: null == duplicateCheckHash ? _self.duplicateCheckHash : duplicateCheckHash // ignore: cast_nullable_to_non_nullable
as String,isMedical: null == isMedical ? _self.isMedical : isMedical // ignore: cast_nullable_to_non_nullable
as bool,isUncovered: null == isUncovered ? _self.isUncovered : isUncovered // ignore: cast_nullable_to_non_nullable
as bool,totalPoints: freezed == totalPoints ? _self.totalPoints : totalPoints // ignore: cast_nullable_to_non_nullable
as int?,burdenRate: freezed == burdenRate ? _self.burdenRate : burdenRate // ignore: cast_nullable_to_non_nullable
as double?,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,isBill: null == isBill ? _self.isBill : isBill // ignore: cast_nullable_to_non_nullable
as bool,billDueDate: freezed == billDueDate ? _self.billDueDate : billDueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,billStatus: null == billStatus ? _self.billStatus : billStatus // ignore: cast_nullable_to_non_nullable
as String,billPaidDate: freezed == billPaidDate ? _self.billPaidDate : billPaidDate // ignore: cast_nullable_to_non_nullable
as DateTime?,billIsTaxExempt: null == billIsTaxExempt ? _self.billIsTaxExempt : billIsTaxExempt // ignore: cast_nullable_to_non_nullable
as bool,savingsAmount: null == savingsAmount ? _self.savingsAmount : savingsAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceiptAnalysis].
extension ReceiptAnalysisPatterns on ReceiptAnalysis {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptAnalysis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptAnalysis() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptAnalysis value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptAnalysis():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptAnalysis value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptAnalysis() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String storeName,  String purchasedAt,  int totalAmount, @JsonKey(includeIfNull: false)  int? taxAmount,  String paymentMethod, @JsonKey(includeIfNull: false)  String? category,  List<ReceiptItem> items,  List<CouponDetected> couponsDetected,  List<LinePromotion> linePromotions,  String duplicateCheckHash,  bool isMedical,  bool isUncovered, @JsonKey(includeIfNull: false)  int? totalPoints, @JsonKey(includeIfNull: false)  double? burdenRate, @JsonKey(includeIfNull: false)  String? memo,  bool isBill, @JsonKey(includeIfNull: false)  DateTime? billDueDate,  String billStatus, @JsonKey(includeIfNull: false)  DateTime? billPaidDate,  bool billIsTaxExempt,  int savingsAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptAnalysis() when $default != null:
return $default(_that.storeName,_that.purchasedAt,_that.totalAmount,_that.taxAmount,_that.paymentMethod,_that.category,_that.items,_that.couponsDetected,_that.linePromotions,_that.duplicateCheckHash,_that.isMedical,_that.isUncovered,_that.totalPoints,_that.burdenRate,_that.memo,_that.isBill,_that.billDueDate,_that.billStatus,_that.billPaidDate,_that.billIsTaxExempt,_that.savingsAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String storeName,  String purchasedAt,  int totalAmount, @JsonKey(includeIfNull: false)  int? taxAmount,  String paymentMethod, @JsonKey(includeIfNull: false)  String? category,  List<ReceiptItem> items,  List<CouponDetected> couponsDetected,  List<LinePromotion> linePromotions,  String duplicateCheckHash,  bool isMedical,  bool isUncovered, @JsonKey(includeIfNull: false)  int? totalPoints, @JsonKey(includeIfNull: false)  double? burdenRate, @JsonKey(includeIfNull: false)  String? memo,  bool isBill, @JsonKey(includeIfNull: false)  DateTime? billDueDate,  String billStatus, @JsonKey(includeIfNull: false)  DateTime? billPaidDate,  bool billIsTaxExempt,  int savingsAmount)  $default,) {final _that = this;
switch (_that) {
case _ReceiptAnalysis():
return $default(_that.storeName,_that.purchasedAt,_that.totalAmount,_that.taxAmount,_that.paymentMethod,_that.category,_that.items,_that.couponsDetected,_that.linePromotions,_that.duplicateCheckHash,_that.isMedical,_that.isUncovered,_that.totalPoints,_that.burdenRate,_that.memo,_that.isBill,_that.billDueDate,_that.billStatus,_that.billPaidDate,_that.billIsTaxExempt,_that.savingsAmount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String storeName,  String purchasedAt,  int totalAmount, @JsonKey(includeIfNull: false)  int? taxAmount,  String paymentMethod, @JsonKey(includeIfNull: false)  String? category,  List<ReceiptItem> items,  List<CouponDetected> couponsDetected,  List<LinePromotion> linePromotions,  String duplicateCheckHash,  bool isMedical,  bool isUncovered, @JsonKey(includeIfNull: false)  int? totalPoints, @JsonKey(includeIfNull: false)  double? burdenRate, @JsonKey(includeIfNull: false)  String? memo,  bool isBill, @JsonKey(includeIfNull: false)  DateTime? billDueDate,  String billStatus, @JsonKey(includeIfNull: false)  DateTime? billPaidDate,  bool billIsTaxExempt,  int savingsAmount)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptAnalysis() when $default != null:
return $default(_that.storeName,_that.purchasedAt,_that.totalAmount,_that.taxAmount,_that.paymentMethod,_that.category,_that.items,_that.couponsDetected,_that.linePromotions,_that.duplicateCheckHash,_that.isMedical,_that.isUncovered,_that.totalPoints,_that.burdenRate,_that.memo,_that.isBill,_that.billDueDate,_that.billStatus,_that.billPaidDate,_that.billIsTaxExempt,_that.savingsAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReceiptAnalysis implements ReceiptAnalysis {
  const _ReceiptAnalysis({required this.storeName, required this.purchasedAt, required this.totalAmount, @JsonKey(includeIfNull: false) this.taxAmount, this.paymentMethod = 'cash', @JsonKey(includeIfNull: false) this.category, required final  List<ReceiptItem> items, required final  List<CouponDetected> couponsDetected, final  List<LinePromotion> linePromotions = const [], this.duplicateCheckHash = '', this.isMedical = false, this.isUncovered = false, @JsonKey(includeIfNull: false) this.totalPoints, @JsonKey(includeIfNull: false) this.burdenRate, @JsonKey(includeIfNull: false) this.memo, this.isBill = false, @JsonKey(includeIfNull: false) this.billDueDate, this.billStatus = 'unpaid', @JsonKey(includeIfNull: false) this.billPaidDate, this.billIsTaxExempt = false, this.savingsAmount = 0}): _items = items,_couponsDetected = couponsDetected,_linePromotions = linePromotions;
  factory _ReceiptAnalysis.fromJson(Map<String, dynamic> json) => _$ReceiptAnalysisFromJson(json);

@override final  String storeName;
@override final  String purchasedAt;
@override final  int totalAmount;
@override@JsonKey(includeIfNull: false) final  int? taxAmount;
@override@JsonKey() final  String paymentMethod;
@override@JsonKey(includeIfNull: false) final  String? category;
 final  List<ReceiptItem> _items;
@override List<ReceiptItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  List<CouponDetected> _couponsDetected;
@override List<CouponDetected> get couponsDetected {
  if (_couponsDetected is EqualUnmodifiableListView) return _couponsDetected;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_couponsDetected);
}

 final  List<LinePromotion> _linePromotions;
@override@JsonKey() List<LinePromotion> get linePromotions {
  if (_linePromotions is EqualUnmodifiableListView) return _linePromotions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_linePromotions);
}

@override@JsonKey() final  String duplicateCheckHash;
@override@JsonKey() final  bool isMedical;
@override@JsonKey() final  bool isUncovered;
@override@JsonKey(includeIfNull: false) final  int? totalPoints;
@override@JsonKey(includeIfNull: false) final  double? burdenRate;
@override@JsonKey(includeIfNull: false) final  String? memo;
@override@JsonKey() final  bool isBill;
@override@JsonKey(includeIfNull: false) final  DateTime? billDueDate;
@override@JsonKey() final  String billStatus;
@override@JsonKey(includeIfNull: false) final  DateTime? billPaidDate;
@override@JsonKey() final  bool billIsTaxExempt;
@override@JsonKey() final  int savingsAmount;

/// Create a copy of ReceiptAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptAnalysisCopyWith<_ReceiptAnalysis> get copyWith => __$ReceiptAnalysisCopyWithImpl<_ReceiptAnalysis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptAnalysisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptAnalysis&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.taxAmount, taxAmount) || other.taxAmount == taxAmount)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._couponsDetected, _couponsDetected)&&const DeepCollectionEquality().equals(other._linePromotions, _linePromotions)&&(identical(other.duplicateCheckHash, duplicateCheckHash) || other.duplicateCheckHash == duplicateCheckHash)&&(identical(other.isMedical, isMedical) || other.isMedical == isMedical)&&(identical(other.isUncovered, isUncovered) || other.isUncovered == isUncovered)&&(identical(other.totalPoints, totalPoints) || other.totalPoints == totalPoints)&&(identical(other.burdenRate, burdenRate) || other.burdenRate == burdenRate)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.isBill, isBill) || other.isBill == isBill)&&(identical(other.billDueDate, billDueDate) || other.billDueDate == billDueDate)&&(identical(other.billStatus, billStatus) || other.billStatus == billStatus)&&(identical(other.billPaidDate, billPaidDate) || other.billPaidDate == billPaidDate)&&(identical(other.billIsTaxExempt, billIsTaxExempt) || other.billIsTaxExempt == billIsTaxExempt)&&(identical(other.savingsAmount, savingsAmount) || other.savingsAmount == savingsAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,storeName,purchasedAt,totalAmount,taxAmount,paymentMethod,category,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_couponsDetected),const DeepCollectionEquality().hash(_linePromotions),duplicateCheckHash,isMedical,isUncovered,totalPoints,burdenRate,memo,isBill,billDueDate,billStatus,billPaidDate,billIsTaxExempt,savingsAmount]);

@override
String toString() {
  return 'ReceiptAnalysis(storeName: $storeName, purchasedAt: $purchasedAt, totalAmount: $totalAmount, taxAmount: $taxAmount, paymentMethod: $paymentMethod, category: $category, items: $items, couponsDetected: $couponsDetected, linePromotions: $linePromotions, duplicateCheckHash: $duplicateCheckHash, isMedical: $isMedical, isUncovered: $isUncovered, totalPoints: $totalPoints, burdenRate: $burdenRate, memo: $memo, isBill: $isBill, billDueDate: $billDueDate, billStatus: $billStatus, billPaidDate: $billPaidDate, billIsTaxExempt: $billIsTaxExempt, savingsAmount: $savingsAmount)';
}


}

/// @nodoc
abstract mixin class _$ReceiptAnalysisCopyWith<$Res> implements $ReceiptAnalysisCopyWith<$Res> {
  factory _$ReceiptAnalysisCopyWith(_ReceiptAnalysis value, $Res Function(_ReceiptAnalysis) _then) = __$ReceiptAnalysisCopyWithImpl;
@override @useResult
$Res call({
 String storeName, String purchasedAt, int totalAmount,@JsonKey(includeIfNull: false) int? taxAmount, String paymentMethod,@JsonKey(includeIfNull: false) String? category, List<ReceiptItem> items, List<CouponDetected> couponsDetected, List<LinePromotion> linePromotions, String duplicateCheckHash, bool isMedical, bool isUncovered,@JsonKey(includeIfNull: false) int? totalPoints,@JsonKey(includeIfNull: false) double? burdenRate,@JsonKey(includeIfNull: false) String? memo, bool isBill,@JsonKey(includeIfNull: false) DateTime? billDueDate, String billStatus,@JsonKey(includeIfNull: false) DateTime? billPaidDate, bool billIsTaxExempt, int savingsAmount
});




}
/// @nodoc
class __$ReceiptAnalysisCopyWithImpl<$Res>
    implements _$ReceiptAnalysisCopyWith<$Res> {
  __$ReceiptAnalysisCopyWithImpl(this._self, this._then);

  final _ReceiptAnalysis _self;
  final $Res Function(_ReceiptAnalysis) _then;

/// Create a copy of ReceiptAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? storeName = null,Object? purchasedAt = null,Object? totalAmount = null,Object? taxAmount = freezed,Object? paymentMethod = null,Object? category = freezed,Object? items = null,Object? couponsDetected = null,Object? linePromotions = null,Object? duplicateCheckHash = null,Object? isMedical = null,Object? isUncovered = null,Object? totalPoints = freezed,Object? burdenRate = freezed,Object? memo = freezed,Object? isBill = null,Object? billDueDate = freezed,Object? billStatus = null,Object? billPaidDate = freezed,Object? billIsTaxExempt = null,Object? savingsAmount = null,}) {
  return _then(_ReceiptAnalysis(
storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,purchasedAt: null == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,taxAmount: freezed == taxAmount ? _self.taxAmount : taxAmount // ignore: cast_nullable_to_non_nullable
as int?,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ReceiptItem>,couponsDetected: null == couponsDetected ? _self._couponsDetected : couponsDetected // ignore: cast_nullable_to_non_nullable
as List<CouponDetected>,linePromotions: null == linePromotions ? _self._linePromotions : linePromotions // ignore: cast_nullable_to_non_nullable
as List<LinePromotion>,duplicateCheckHash: null == duplicateCheckHash ? _self.duplicateCheckHash : duplicateCheckHash // ignore: cast_nullable_to_non_nullable
as String,isMedical: null == isMedical ? _self.isMedical : isMedical // ignore: cast_nullable_to_non_nullable
as bool,isUncovered: null == isUncovered ? _self.isUncovered : isUncovered // ignore: cast_nullable_to_non_nullable
as bool,totalPoints: freezed == totalPoints ? _self.totalPoints : totalPoints // ignore: cast_nullable_to_non_nullable
as int?,burdenRate: freezed == burdenRate ? _self.burdenRate : burdenRate // ignore: cast_nullable_to_non_nullable
as double?,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,isBill: null == isBill ? _self.isBill : isBill // ignore: cast_nullable_to_non_nullable
as bool,billDueDate: freezed == billDueDate ? _self.billDueDate : billDueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,billStatus: null == billStatus ? _self.billStatus : billStatus // ignore: cast_nullable_to_non_nullable
as String,billPaidDate: freezed == billPaidDate ? _self.billPaidDate : billPaidDate // ignore: cast_nullable_to_non_nullable
as DateTime?,billIsTaxExempt: null == billIsTaxExempt ? _self.billIsTaxExempt : billIsTaxExempt // ignore: cast_nullable_to_non_nullable
as bool,savingsAmount: null == savingsAmount ? _self.savingsAmount : savingsAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Receipt {

 String get receiptId; String get storeName; int get totalAmount; String get purchasedAt; String get paymentMethod; List<ReceiptItem> get items; List<ReceiptDiscount> get discounts; String? get memo; int get savingsAmount;
/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptCopyWith<Receipt> get copyWith => _$ReceiptCopyWithImpl<Receipt>(this as Receipt, _$identity);

  /// Serializes this Receipt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Receipt&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.discounts, discounts)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.savingsAmount, savingsAmount) || other.savingsAmount == savingsAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,receiptId,storeName,totalAmount,purchasedAt,paymentMethod,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(discounts),memo,savingsAmount);

@override
String toString() {
  return 'Receipt(receiptId: $receiptId, storeName: $storeName, totalAmount: $totalAmount, purchasedAt: $purchasedAt, paymentMethod: $paymentMethod, items: $items, discounts: $discounts, memo: $memo, savingsAmount: $savingsAmount)';
}


}

/// @nodoc
abstract mixin class $ReceiptCopyWith<$Res>  {
  factory $ReceiptCopyWith(Receipt value, $Res Function(Receipt) _then) = _$ReceiptCopyWithImpl;
@useResult
$Res call({
 String receiptId, String storeName, int totalAmount, String purchasedAt, String paymentMethod, List<ReceiptItem> items, List<ReceiptDiscount> discounts, String? memo, int savingsAmount
});




}
/// @nodoc
class _$ReceiptCopyWithImpl<$Res>
    implements $ReceiptCopyWith<$Res> {
  _$ReceiptCopyWithImpl(this._self, this._then);

  final Receipt _self;
  final $Res Function(Receipt) _then;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? receiptId = null,Object? storeName = null,Object? totalAmount = null,Object? purchasedAt = null,Object? paymentMethod = null,Object? items = null,Object? discounts = null,Object? memo = freezed,Object? savingsAmount = null,}) {
  return _then(_self.copyWith(
receiptId: null == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String,storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,purchasedAt: null == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as String,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ReceiptItem>,discounts: null == discounts ? _self.discounts : discounts // ignore: cast_nullable_to_non_nullable
as List<ReceiptDiscount>,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,savingsAmount: null == savingsAmount ? _self.savingsAmount : savingsAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Receipt].
extension ReceiptPatterns on Receipt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Receipt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Receipt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Receipt value)  $default,){
final _that = this;
switch (_that) {
case _Receipt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Receipt value)?  $default,){
final _that = this;
switch (_that) {
case _Receipt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String receiptId,  String storeName,  int totalAmount,  String purchasedAt,  String paymentMethod,  List<ReceiptItem> items,  List<ReceiptDiscount> discounts,  String? memo,  int savingsAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Receipt() when $default != null:
return $default(_that.receiptId,_that.storeName,_that.totalAmount,_that.purchasedAt,_that.paymentMethod,_that.items,_that.discounts,_that.memo,_that.savingsAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String receiptId,  String storeName,  int totalAmount,  String purchasedAt,  String paymentMethod,  List<ReceiptItem> items,  List<ReceiptDiscount> discounts,  String? memo,  int savingsAmount)  $default,) {final _that = this;
switch (_that) {
case _Receipt():
return $default(_that.receiptId,_that.storeName,_that.totalAmount,_that.purchasedAt,_that.paymentMethod,_that.items,_that.discounts,_that.memo,_that.savingsAmount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String receiptId,  String storeName,  int totalAmount,  String purchasedAt,  String paymentMethod,  List<ReceiptItem> items,  List<ReceiptDiscount> discounts,  String? memo,  int savingsAmount)?  $default,) {final _that = this;
switch (_that) {
case _Receipt() when $default != null:
return $default(_that.receiptId,_that.storeName,_that.totalAmount,_that.purchasedAt,_that.paymentMethod,_that.items,_that.discounts,_that.memo,_that.savingsAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Receipt implements Receipt {
  const _Receipt({required this.receiptId, required this.storeName, required this.totalAmount, required this.purchasedAt, this.paymentMethod = 'cash', required final  List<ReceiptItem> items, final  List<ReceiptDiscount> discounts = const [], this.memo, this.savingsAmount = 0}): _items = items,_discounts = discounts;
  factory _Receipt.fromJson(Map<String, dynamic> json) => _$ReceiptFromJson(json);

@override final  String receiptId;
@override final  String storeName;
@override final  int totalAmount;
@override final  String purchasedAt;
@override@JsonKey() final  String paymentMethod;
 final  List<ReceiptItem> _items;
@override List<ReceiptItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  List<ReceiptDiscount> _discounts;
@override@JsonKey() List<ReceiptDiscount> get discounts {
  if (_discounts is EqualUnmodifiableListView) return _discounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_discounts);
}

@override final  String? memo;
@override@JsonKey() final  int savingsAmount;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptCopyWith<_Receipt> get copyWith => __$ReceiptCopyWithImpl<_Receipt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Receipt&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._discounts, _discounts)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.savingsAmount, savingsAmount) || other.savingsAmount == savingsAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,receiptId,storeName,totalAmount,purchasedAt,paymentMethod,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_discounts),memo,savingsAmount);

@override
String toString() {
  return 'Receipt(receiptId: $receiptId, storeName: $storeName, totalAmount: $totalAmount, purchasedAt: $purchasedAt, paymentMethod: $paymentMethod, items: $items, discounts: $discounts, memo: $memo, savingsAmount: $savingsAmount)';
}


}

/// @nodoc
abstract mixin class _$ReceiptCopyWith<$Res> implements $ReceiptCopyWith<$Res> {
  factory _$ReceiptCopyWith(_Receipt value, $Res Function(_Receipt) _then) = __$ReceiptCopyWithImpl;
@override @useResult
$Res call({
 String receiptId, String storeName, int totalAmount, String purchasedAt, String paymentMethod, List<ReceiptItem> items, List<ReceiptDiscount> discounts, String? memo, int savingsAmount
});




}
/// @nodoc
class __$ReceiptCopyWithImpl<$Res>
    implements _$ReceiptCopyWith<$Res> {
  __$ReceiptCopyWithImpl(this._self, this._then);

  final _Receipt _self;
  final $Res Function(_Receipt) _then;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? receiptId = null,Object? storeName = null,Object? totalAmount = null,Object? purchasedAt = null,Object? paymentMethod = null,Object? items = null,Object? discounts = null,Object? memo = freezed,Object? savingsAmount = null,}) {
  return _then(_Receipt(
receiptId: null == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String,storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,purchasedAt: null == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as String,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ReceiptItem>,discounts: null == discounts ? _self._discounts : discounts // ignore: cast_nullable_to_non_nullable
as List<ReceiptDiscount>,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,savingsAmount: null == savingsAmount ? _self.savingsAmount : savingsAmount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

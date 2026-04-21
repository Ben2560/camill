// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bill_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Bill {

 String get billId; String get title; int get amount; DateTime? get dueDate;@JsonKey(unknownEnumValue: BillStatus.unpaid) BillStatus get status; DateTime get createdAt; String? get category; bool get isTaxExempt; DateTime? get paidAt; String? get memo;
/// Create a copy of Bill
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillCopyWith<Bill> get copyWith => _$BillCopyWithImpl<Bill>(this as Bill, _$identity);

  /// Serializes this Bill to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Bill&&(identical(other.billId, billId) || other.billId == billId)&&(identical(other.title, title) || other.title == title)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.category, category) || other.category == category)&&(identical(other.isTaxExempt, isTaxExempt) || other.isTaxExempt == isTaxExempt)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.memo, memo) || other.memo == memo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,billId,title,amount,dueDate,status,createdAt,category,isTaxExempt,paidAt,memo);

@override
String toString() {
  return 'Bill(billId: $billId, title: $title, amount: $amount, dueDate: $dueDate, status: $status, createdAt: $createdAt, category: $category, isTaxExempt: $isTaxExempt, paidAt: $paidAt, memo: $memo)';
}


}

/// @nodoc
abstract mixin class $BillCopyWith<$Res>  {
  factory $BillCopyWith(Bill value, $Res Function(Bill) _then) = _$BillCopyWithImpl;
@useResult
$Res call({
 String billId, String title, int amount, DateTime? dueDate,@JsonKey(unknownEnumValue: BillStatus.unpaid) BillStatus status, DateTime createdAt, String? category, bool isTaxExempt, DateTime? paidAt, String? memo
});




}
/// @nodoc
class _$BillCopyWithImpl<$Res>
    implements $BillCopyWith<$Res> {
  _$BillCopyWithImpl(this._self, this._then);

  final Bill _self;
  final $Res Function(Bill) _then;

/// Create a copy of Bill
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? billId = null,Object? title = null,Object? amount = null,Object? dueDate = freezed,Object? status = null,Object? createdAt = null,Object? category = freezed,Object? isTaxExempt = null,Object? paidAt = freezed,Object? memo = freezed,}) {
  return _then(_self.copyWith(
billId: null == billId ? _self.billId : billId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BillStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,isTaxExempt: null == isTaxExempt ? _self.isTaxExempt : isTaxExempt // ignore: cast_nullable_to_non_nullable
as bool,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Bill].
extension BillPatterns on Bill {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Bill value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Bill() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Bill value)  $default,){
final _that = this;
switch (_that) {
case _Bill():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Bill value)?  $default,){
final _that = this;
switch (_that) {
case _Bill() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String billId,  String title,  int amount,  DateTime? dueDate, @JsonKey(unknownEnumValue: BillStatus.unpaid)  BillStatus status,  DateTime createdAt,  String? category,  bool isTaxExempt,  DateTime? paidAt,  String? memo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Bill() when $default != null:
return $default(_that.billId,_that.title,_that.amount,_that.dueDate,_that.status,_that.createdAt,_that.category,_that.isTaxExempt,_that.paidAt,_that.memo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String billId,  String title,  int amount,  DateTime? dueDate, @JsonKey(unknownEnumValue: BillStatus.unpaid)  BillStatus status,  DateTime createdAt,  String? category,  bool isTaxExempt,  DateTime? paidAt,  String? memo)  $default,) {final _that = this;
switch (_that) {
case _Bill():
return $default(_that.billId,_that.title,_that.amount,_that.dueDate,_that.status,_that.createdAt,_that.category,_that.isTaxExempt,_that.paidAt,_that.memo);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String billId,  String title,  int amount,  DateTime? dueDate, @JsonKey(unknownEnumValue: BillStatus.unpaid)  BillStatus status,  DateTime createdAt,  String? category,  bool isTaxExempt,  DateTime? paidAt,  String? memo)?  $default,) {final _that = this;
switch (_that) {
case _Bill() when $default != null:
return $default(_that.billId,_that.title,_that.amount,_that.dueDate,_that.status,_that.createdAt,_that.category,_that.isTaxExempt,_that.paidAt,_that.memo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Bill extends Bill {
  const _Bill({required this.billId, required this.title, required this.amount, this.dueDate, @JsonKey(unknownEnumValue: BillStatus.unpaid) required this.status, required this.createdAt, this.category, this.isTaxExempt = false, this.paidAt, this.memo}): super._();
  factory _Bill.fromJson(Map<String, dynamic> json) => _$BillFromJson(json);

@override final  String billId;
@override final  String title;
@override final  int amount;
@override final  DateTime? dueDate;
@override@JsonKey(unknownEnumValue: BillStatus.unpaid) final  BillStatus status;
@override final  DateTime createdAt;
@override final  String? category;
@override@JsonKey() final  bool isTaxExempt;
@override final  DateTime? paidAt;
@override final  String? memo;

/// Create a copy of Bill
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillCopyWith<_Bill> get copyWith => __$BillCopyWithImpl<_Bill>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Bill&&(identical(other.billId, billId) || other.billId == billId)&&(identical(other.title, title) || other.title == title)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.category, category) || other.category == category)&&(identical(other.isTaxExempt, isTaxExempt) || other.isTaxExempt == isTaxExempt)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.memo, memo) || other.memo == memo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,billId,title,amount,dueDate,status,createdAt,category,isTaxExempt,paidAt,memo);

@override
String toString() {
  return 'Bill(billId: $billId, title: $title, amount: $amount, dueDate: $dueDate, status: $status, createdAt: $createdAt, category: $category, isTaxExempt: $isTaxExempt, paidAt: $paidAt, memo: $memo)';
}


}

/// @nodoc
abstract mixin class _$BillCopyWith<$Res> implements $BillCopyWith<$Res> {
  factory _$BillCopyWith(_Bill value, $Res Function(_Bill) _then) = __$BillCopyWithImpl;
@override @useResult
$Res call({
 String billId, String title, int amount, DateTime? dueDate,@JsonKey(unknownEnumValue: BillStatus.unpaid) BillStatus status, DateTime createdAt, String? category, bool isTaxExempt, DateTime? paidAt, String? memo
});




}
/// @nodoc
class __$BillCopyWithImpl<$Res>
    implements _$BillCopyWith<$Res> {
  __$BillCopyWithImpl(this._self, this._then);

  final _Bill _self;
  final $Res Function(_Bill) _then;

/// Create a copy of Bill
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? billId = null,Object? title = null,Object? amount = null,Object? dueDate = freezed,Object? status = null,Object? createdAt = null,Object? category = freezed,Object? isTaxExempt = null,Object? paidAt = freezed,Object? memo = freezed,}) {
  return _then(_Bill(
billId: null == billId ? _self.billId : billId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BillStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,isTaxExempt: null == isTaxExempt ? _self.isTaxExempt : isTaxExempt // ignore: cast_nullable_to_non_nullable
as bool,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

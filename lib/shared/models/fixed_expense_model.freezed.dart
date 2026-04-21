// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fixed_expense_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FixedExpenseSetting {

 String get category; int? get billingDay; String? get holidayRule;
/// Create a copy of FixedExpenseSetting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FixedExpenseSettingCopyWith<FixedExpenseSetting> get copyWith => _$FixedExpenseSettingCopyWithImpl<FixedExpenseSetting>(this as FixedExpenseSetting, _$identity);

  /// Serializes this FixedExpenseSetting to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FixedExpenseSetting&&(identical(other.category, category) || other.category == category)&&(identical(other.billingDay, billingDay) || other.billingDay == billingDay)&&(identical(other.holidayRule, holidayRule) || other.holidayRule == holidayRule));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,billingDay,holidayRule);

@override
String toString() {
  return 'FixedExpenseSetting(category: $category, billingDay: $billingDay, holidayRule: $holidayRule)';
}


}

/// @nodoc
abstract mixin class $FixedExpenseSettingCopyWith<$Res>  {
  factory $FixedExpenseSettingCopyWith(FixedExpenseSetting value, $Res Function(FixedExpenseSetting) _then) = _$FixedExpenseSettingCopyWithImpl;
@useResult
$Res call({
 String category, int? billingDay, String? holidayRule
});




}
/// @nodoc
class _$FixedExpenseSettingCopyWithImpl<$Res>
    implements $FixedExpenseSettingCopyWith<$Res> {
  _$FixedExpenseSettingCopyWithImpl(this._self, this._then);

  final FixedExpenseSetting _self;
  final $Res Function(FixedExpenseSetting) _then;

/// Create a copy of FixedExpenseSetting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? billingDay = freezed,Object? holidayRule = freezed,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,billingDay: freezed == billingDay ? _self.billingDay : billingDay // ignore: cast_nullable_to_non_nullable
as int?,holidayRule: freezed == holidayRule ? _self.holidayRule : holidayRule // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FixedExpenseSetting].
extension FixedExpenseSettingPatterns on FixedExpenseSetting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FixedExpenseSetting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FixedExpenseSetting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FixedExpenseSetting value)  $default,){
final _that = this;
switch (_that) {
case _FixedExpenseSetting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FixedExpenseSetting value)?  $default,){
final _that = this;
switch (_that) {
case _FixedExpenseSetting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String category,  int? billingDay,  String? holidayRule)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FixedExpenseSetting() when $default != null:
return $default(_that.category,_that.billingDay,_that.holidayRule);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String category,  int? billingDay,  String? holidayRule)  $default,) {final _that = this;
switch (_that) {
case _FixedExpenseSetting():
return $default(_that.category,_that.billingDay,_that.holidayRule);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String category,  int? billingDay,  String? holidayRule)?  $default,) {final _that = this;
switch (_that) {
case _FixedExpenseSetting() when $default != null:
return $default(_that.category,_that.billingDay,_that.holidayRule);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FixedExpenseSetting extends FixedExpenseSetting {
  const _FixedExpenseSetting({required this.category, this.billingDay, this.holidayRule}): super._();
  factory _FixedExpenseSetting.fromJson(Map<String, dynamic> json) => _$FixedExpenseSettingFromJson(json);

@override final  String category;
@override final  int? billingDay;
@override final  String? holidayRule;

/// Create a copy of FixedExpenseSetting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FixedExpenseSettingCopyWith<_FixedExpenseSetting> get copyWith => __$FixedExpenseSettingCopyWithImpl<_FixedExpenseSetting>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FixedExpenseSettingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FixedExpenseSetting&&(identical(other.category, category) || other.category == category)&&(identical(other.billingDay, billingDay) || other.billingDay == billingDay)&&(identical(other.holidayRule, holidayRule) || other.holidayRule == holidayRule));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,billingDay,holidayRule);

@override
String toString() {
  return 'FixedExpenseSetting(category: $category, billingDay: $billingDay, holidayRule: $holidayRule)';
}


}

/// @nodoc
abstract mixin class _$FixedExpenseSettingCopyWith<$Res> implements $FixedExpenseSettingCopyWith<$Res> {
  factory _$FixedExpenseSettingCopyWith(_FixedExpenseSetting value, $Res Function(_FixedExpenseSetting) _then) = __$FixedExpenseSettingCopyWithImpl;
@override @useResult
$Res call({
 String category, int? billingDay, String? holidayRule
});




}
/// @nodoc
class __$FixedExpenseSettingCopyWithImpl<$Res>
    implements _$FixedExpenseSettingCopyWith<$Res> {
  __$FixedExpenseSettingCopyWithImpl(this._self, this._then);

  final _FixedExpenseSetting _self;
  final $Res Function(_FixedExpenseSetting) _then;

/// Create a copy of FixedExpenseSetting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? billingDay = freezed,Object? holidayRule = freezed,}) {
  return _then(_FixedExpenseSetting(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,billingDay: freezed == billingDay ? _self.billingDay : billingDay // ignore: cast_nullable_to_non_nullable
as int?,holidayRule: freezed == holidayRule ? _self.holidayRule : holidayRule // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$FixedPayment {

 String get category; String get yearMonth; DateTime get paidAt; String get confirmedBy; int? get amount;
/// Create a copy of FixedPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FixedPaymentCopyWith<FixedPayment> get copyWith => _$FixedPaymentCopyWithImpl<FixedPayment>(this as FixedPayment, _$identity);

  /// Serializes this FixedPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FixedPayment&&(identical(other.category, category) || other.category == category)&&(identical(other.yearMonth, yearMonth) || other.yearMonth == yearMonth)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.confirmedBy, confirmedBy) || other.confirmedBy == confirmedBy)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,yearMonth,paidAt,confirmedBy,amount);

@override
String toString() {
  return 'FixedPayment(category: $category, yearMonth: $yearMonth, paidAt: $paidAt, confirmedBy: $confirmedBy, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $FixedPaymentCopyWith<$Res>  {
  factory $FixedPaymentCopyWith(FixedPayment value, $Res Function(FixedPayment) _then) = _$FixedPaymentCopyWithImpl;
@useResult
$Res call({
 String category, String yearMonth, DateTime paidAt, String confirmedBy, int? amount
});




}
/// @nodoc
class _$FixedPaymentCopyWithImpl<$Res>
    implements $FixedPaymentCopyWith<$Res> {
  _$FixedPaymentCopyWithImpl(this._self, this._then);

  final FixedPayment _self;
  final $Res Function(FixedPayment) _then;

/// Create a copy of FixedPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? yearMonth = null,Object? paidAt = null,Object? confirmedBy = null,Object? amount = freezed,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,yearMonth: null == yearMonth ? _self.yearMonth : yearMonth // ignore: cast_nullable_to_non_nullable
as String,paidAt: null == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime,confirmedBy: null == confirmedBy ? _self.confirmedBy : confirmedBy // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [FixedPayment].
extension FixedPaymentPatterns on FixedPayment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FixedPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FixedPayment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FixedPayment value)  $default,){
final _that = this;
switch (_that) {
case _FixedPayment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FixedPayment value)?  $default,){
final _that = this;
switch (_that) {
case _FixedPayment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String category,  String yearMonth,  DateTime paidAt,  String confirmedBy,  int? amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FixedPayment() when $default != null:
return $default(_that.category,_that.yearMonth,_that.paidAt,_that.confirmedBy,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String category,  String yearMonth,  DateTime paidAt,  String confirmedBy,  int? amount)  $default,) {final _that = this;
switch (_that) {
case _FixedPayment():
return $default(_that.category,_that.yearMonth,_that.paidAt,_that.confirmedBy,_that.amount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String category,  String yearMonth,  DateTime paidAt,  String confirmedBy,  int? amount)?  $default,) {final _that = this;
switch (_that) {
case _FixedPayment() when $default != null:
return $default(_that.category,_that.yearMonth,_that.paidAt,_that.confirmedBy,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FixedPayment extends FixedPayment {
  const _FixedPayment({required this.category, required this.yearMonth, required this.paidAt, required this.confirmedBy, this.amount}): super._();
  factory _FixedPayment.fromJson(Map<String, dynamic> json) => _$FixedPaymentFromJson(json);

@override final  String category;
@override final  String yearMonth;
@override final  DateTime paidAt;
@override final  String confirmedBy;
@override final  int? amount;

/// Create a copy of FixedPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FixedPaymentCopyWith<_FixedPayment> get copyWith => __$FixedPaymentCopyWithImpl<_FixedPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FixedPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FixedPayment&&(identical(other.category, category) || other.category == category)&&(identical(other.yearMonth, yearMonth) || other.yearMonth == yearMonth)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.confirmedBy, confirmedBy) || other.confirmedBy == confirmedBy)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,yearMonth,paidAt,confirmedBy,amount);

@override
String toString() {
  return 'FixedPayment(category: $category, yearMonth: $yearMonth, paidAt: $paidAt, confirmedBy: $confirmedBy, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$FixedPaymentCopyWith<$Res> implements $FixedPaymentCopyWith<$Res> {
  factory _$FixedPaymentCopyWith(_FixedPayment value, $Res Function(_FixedPayment) _then) = __$FixedPaymentCopyWithImpl;
@override @useResult
$Res call({
 String category, String yearMonth, DateTime paidAt, String confirmedBy, int? amount
});




}
/// @nodoc
class __$FixedPaymentCopyWithImpl<$Res>
    implements _$FixedPaymentCopyWith<$Res> {
  __$FixedPaymentCopyWithImpl(this._self, this._then);

  final _FixedPayment _self;
  final $Res Function(_FixedPayment) _then;

/// Create a copy of FixedPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? yearMonth = null,Object? paidAt = null,Object? confirmedBy = null,Object? amount = freezed,}) {
  return _then(_FixedPayment(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,yearMonth: null == yearMonth ? _self.yearMonth : yearMonth // ignore: cast_nullable_to_non_nullable
as String,paidAt: null == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime,confirmedBy: null == confirmedBy ? _self.confirmedBy : confirmedBy // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$BankTransaction {

 String get date; String get description;@JsonKey(fromJson: _amountToInt) int get amount; String? get matchedCategory;
/// Create a copy of BankTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BankTransactionCopyWith<BankTransaction> get copyWith => _$BankTransactionCopyWithImpl<BankTransaction>(this as BankTransaction, _$identity);

  /// Serializes this BankTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankTransaction&&(identical(other.date, date) || other.date == date)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.matchedCategory, matchedCategory) || other.matchedCategory == matchedCategory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,description,amount,matchedCategory);

@override
String toString() {
  return 'BankTransaction(date: $date, description: $description, amount: $amount, matchedCategory: $matchedCategory)';
}


}

/// @nodoc
abstract mixin class $BankTransactionCopyWith<$Res>  {
  factory $BankTransactionCopyWith(BankTransaction value, $Res Function(BankTransaction) _then) = _$BankTransactionCopyWithImpl;
@useResult
$Res call({
 String date, String description,@JsonKey(fromJson: _amountToInt) int amount, String? matchedCategory
});




}
/// @nodoc
class _$BankTransactionCopyWithImpl<$Res>
    implements $BankTransactionCopyWith<$Res> {
  _$BankTransactionCopyWithImpl(this._self, this._then);

  final BankTransaction _self;
  final $Res Function(BankTransaction) _then;

/// Create a copy of BankTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? description = null,Object? amount = null,Object? matchedCategory = freezed,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,matchedCategory: freezed == matchedCategory ? _self.matchedCategory : matchedCategory // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BankTransaction].
extension BankTransactionPatterns on BankTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BankTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BankTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BankTransaction value)  $default,){
final _that = this;
switch (_that) {
case _BankTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BankTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _BankTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  String description, @JsonKey(fromJson: _amountToInt)  int amount,  String? matchedCategory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BankTransaction() when $default != null:
return $default(_that.date,_that.description,_that.amount,_that.matchedCategory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  String description, @JsonKey(fromJson: _amountToInt)  int amount,  String? matchedCategory)  $default,) {final _that = this;
switch (_that) {
case _BankTransaction():
return $default(_that.date,_that.description,_that.amount,_that.matchedCategory);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  String description, @JsonKey(fromJson: _amountToInt)  int amount,  String? matchedCategory)?  $default,) {final _that = this;
switch (_that) {
case _BankTransaction() when $default != null:
return $default(_that.date,_that.description,_that.amount,_that.matchedCategory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BankTransaction implements BankTransaction {
  const _BankTransaction({required this.date, required this.description, @JsonKey(fromJson: _amountToInt) required this.amount, this.matchedCategory});
  factory _BankTransaction.fromJson(Map<String, dynamic> json) => _$BankTransactionFromJson(json);

@override final  String date;
@override final  String description;
@override@JsonKey(fromJson: _amountToInt) final  int amount;
@override final  String? matchedCategory;

/// Create a copy of BankTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BankTransactionCopyWith<_BankTransaction> get copyWith => __$BankTransactionCopyWithImpl<_BankTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BankTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BankTransaction&&(identical(other.date, date) || other.date == date)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.matchedCategory, matchedCategory) || other.matchedCategory == matchedCategory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,description,amount,matchedCategory);

@override
String toString() {
  return 'BankTransaction(date: $date, description: $description, amount: $amount, matchedCategory: $matchedCategory)';
}


}

/// @nodoc
abstract mixin class _$BankTransactionCopyWith<$Res> implements $BankTransactionCopyWith<$Res> {
  factory _$BankTransactionCopyWith(_BankTransaction value, $Res Function(_BankTransaction) _then) = __$BankTransactionCopyWithImpl;
@override @useResult
$Res call({
 String date, String description,@JsonKey(fromJson: _amountToInt) int amount, String? matchedCategory
});




}
/// @nodoc
class __$BankTransactionCopyWithImpl<$Res>
    implements _$BankTransactionCopyWith<$Res> {
  __$BankTransactionCopyWithImpl(this._self, this._then);

  final _BankTransaction _self;
  final $Res Function(_BankTransaction) _then;

/// Create a copy of BankTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? description = null,Object? amount = null,Object? matchedCategory = freezed,}) {
  return _then(_BankTransaction(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,matchedCategory: freezed == matchedCategory ? _self.matchedCategory : matchedCategory // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

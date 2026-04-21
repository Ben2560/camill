// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailySummary {

@JsonKey(fromJson: _dateOnly) String get date; int get expense; int get income;
/// Create a copy of DailySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailySummaryCopyWith<DailySummary> get copyWith => _$DailySummaryCopyWithImpl<DailySummary>(this as DailySummary, _$identity);

  /// Serializes this DailySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailySummary&&(identical(other.date, date) || other.date == date)&&(identical(other.expense, expense) || other.expense == expense)&&(identical(other.income, income) || other.income == income));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,expense,income);

@override
String toString() {
  return 'DailySummary(date: $date, expense: $expense, income: $income)';
}


}

/// @nodoc
abstract mixin class $DailySummaryCopyWith<$Res>  {
  factory $DailySummaryCopyWith(DailySummary value, $Res Function(DailySummary) _then) = _$DailySummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _dateOnly) String date, int expense, int income
});




}
/// @nodoc
class _$DailySummaryCopyWithImpl<$Res>
    implements $DailySummaryCopyWith<$Res> {
  _$DailySummaryCopyWithImpl(this._self, this._then);

  final DailySummary _self;
  final $Res Function(DailySummary) _then;

/// Create a copy of DailySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? expense = null,Object? income = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,expense: null == expense ? _self.expense : expense // ignore: cast_nullable_to_non_nullable
as int,income: null == income ? _self.income : income // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DailySummary].
extension DailySummaryPatterns on DailySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailySummary value)  $default,){
final _that = this;
switch (_that) {
case _DailySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailySummary value)?  $default,){
final _that = this;
switch (_that) {
case _DailySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _dateOnly)  String date,  int expense,  int income)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailySummary() when $default != null:
return $default(_that.date,_that.expense,_that.income);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _dateOnly)  String date,  int expense,  int income)  $default,) {final _that = this;
switch (_that) {
case _DailySummary():
return $default(_that.date,_that.expense,_that.income);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _dateOnly)  String date,  int expense,  int income)?  $default,) {final _that = this;
switch (_that) {
case _DailySummary() when $default != null:
return $default(_that.date,_that.expense,_that.income);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailySummary implements DailySummary {
  const _DailySummary({@JsonKey(fromJson: _dateOnly) required this.date, required this.expense, this.income = 0});
  factory _DailySummary.fromJson(Map<String, dynamic> json) => _$DailySummaryFromJson(json);

@override@JsonKey(fromJson: _dateOnly) final  String date;
@override final  int expense;
@override@JsonKey() final  int income;

/// Create a copy of DailySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailySummaryCopyWith<_DailySummary> get copyWith => __$DailySummaryCopyWithImpl<_DailySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailySummary&&(identical(other.date, date) || other.date == date)&&(identical(other.expense, expense) || other.expense == expense)&&(identical(other.income, income) || other.income == income));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,expense,income);

@override
String toString() {
  return 'DailySummary(date: $date, expense: $expense, income: $income)';
}


}

/// @nodoc
abstract mixin class _$DailySummaryCopyWith<$Res> implements $DailySummaryCopyWith<$Res> {
  factory _$DailySummaryCopyWith(_DailySummary value, $Res Function(_DailySummary) _then) = __$DailySummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _dateOnly) String date, int expense, int income
});




}
/// @nodoc
class __$DailySummaryCopyWithImpl<$Res>
    implements _$DailySummaryCopyWith<$Res> {
  __$DailySummaryCopyWithImpl(this._self, this._then);

  final _DailySummary _self;
  final $Res Function(_DailySummary) _then;

/// Create a copy of DailySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? expense = null,Object? income = null,}) {
  return _then(_DailySummary(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,expense: null == expense ? _self.expense : expense // ignore: cast_nullable_to_non_nullable
as int,income: null == income ? _self.income : income // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CategorySummary {

 String get category; int get amount;
/// Create a copy of CategorySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategorySummaryCopyWith<CategorySummary> get copyWith => _$CategorySummaryCopyWithImpl<CategorySummary>(this as CategorySummary, _$identity);

  /// Serializes this CategorySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategorySummary&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,amount);

@override
String toString() {
  return 'CategorySummary(category: $category, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $CategorySummaryCopyWith<$Res>  {
  factory $CategorySummaryCopyWith(CategorySummary value, $Res Function(CategorySummary) _then) = _$CategorySummaryCopyWithImpl;
@useResult
$Res call({
 String category, int amount
});




}
/// @nodoc
class _$CategorySummaryCopyWithImpl<$Res>
    implements $CategorySummaryCopyWith<$Res> {
  _$CategorySummaryCopyWithImpl(this._self, this._then);

  final CategorySummary _self;
  final $Res Function(CategorySummary) _then;

/// Create a copy of CategorySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? amount = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CategorySummary].
extension CategorySummaryPatterns on CategorySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategorySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategorySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategorySummary value)  $default,){
final _that = this;
switch (_that) {
case _CategorySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategorySummary value)?  $default,){
final _that = this;
switch (_that) {
case _CategorySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String category,  int amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategorySummary() when $default != null:
return $default(_that.category,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String category,  int amount)  $default,) {final _that = this;
switch (_that) {
case _CategorySummary():
return $default(_that.category,_that.amount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String category,  int amount)?  $default,) {final _that = this;
switch (_that) {
case _CategorySummary() when $default != null:
return $default(_that.category,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategorySummary implements CategorySummary {
  const _CategorySummary({required this.category, required this.amount});
  factory _CategorySummary.fromJson(Map<String, dynamic> json) => _$CategorySummaryFromJson(json);

@override final  String category;
@override final  int amount;

/// Create a copy of CategorySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategorySummaryCopyWith<_CategorySummary> get copyWith => __$CategorySummaryCopyWithImpl<_CategorySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategorySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategorySummary&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,amount);

@override
String toString() {
  return 'CategorySummary(category: $category, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$CategorySummaryCopyWith<$Res> implements $CategorySummaryCopyWith<$Res> {
  factory _$CategorySummaryCopyWith(_CategorySummary value, $Res Function(_CategorySummary) _then) = __$CategorySummaryCopyWithImpl;
@override @useResult
$Res call({
 String category, int amount
});




}
/// @nodoc
class __$CategorySummaryCopyWithImpl<$Res>
    implements _$CategorySummaryCopyWith<$Res> {
  __$CategorySummaryCopyWithImpl(this._self, this._then);

  final _CategorySummary _self;
  final $Res Function(_CategorySummary) _then;

/// Create a copy of CategorySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? amount = null,}) {
  return _then(_CategorySummary(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WeeklySummary {

 String get weekStart; String get weekEnd; int get totalExpense; int get totalIncome; int get billTotal; List<CategorySummary> get byCategory; List<DailySummary> get byDay;
/// Create a copy of WeeklySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklySummaryCopyWith<WeeklySummary> get copyWith => _$WeeklySummaryCopyWithImpl<WeeklySummary>(this as WeeklySummary, _$identity);

  /// Serializes this WeeklySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklySummary&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.weekEnd, weekEnd) || other.weekEnd == weekEnd)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.billTotal, billTotal) || other.billTotal == billTotal)&&const DeepCollectionEquality().equals(other.byCategory, byCategory)&&const DeepCollectionEquality().equals(other.byDay, byDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekStart,weekEnd,totalExpense,totalIncome,billTotal,const DeepCollectionEquality().hash(byCategory),const DeepCollectionEquality().hash(byDay));

@override
String toString() {
  return 'WeeklySummary(weekStart: $weekStart, weekEnd: $weekEnd, totalExpense: $totalExpense, totalIncome: $totalIncome, billTotal: $billTotal, byCategory: $byCategory, byDay: $byDay)';
}


}

/// @nodoc
abstract mixin class $WeeklySummaryCopyWith<$Res>  {
  factory $WeeklySummaryCopyWith(WeeklySummary value, $Res Function(WeeklySummary) _then) = _$WeeklySummaryCopyWithImpl;
@useResult
$Res call({
 String weekStart, String weekEnd, int totalExpense, int totalIncome, int billTotal, List<CategorySummary> byCategory, List<DailySummary> byDay
});




}
/// @nodoc
class _$WeeklySummaryCopyWithImpl<$Res>
    implements $WeeklySummaryCopyWith<$Res> {
  _$WeeklySummaryCopyWithImpl(this._self, this._then);

  final WeeklySummary _self;
  final $Res Function(WeeklySummary) _then;

/// Create a copy of WeeklySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekStart = null,Object? weekEnd = null,Object? totalExpense = null,Object? totalIncome = null,Object? billTotal = null,Object? byCategory = null,Object? byDay = null,}) {
  return _then(_self.copyWith(
weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as String,weekEnd: null == weekEnd ? _self.weekEnd : weekEnd // ignore: cast_nullable_to_non_nullable
as String,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as int,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as int,billTotal: null == billTotal ? _self.billTotal : billTotal // ignore: cast_nullable_to_non_nullable
as int,byCategory: null == byCategory ? _self.byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as List<CategorySummary>,byDay: null == byDay ? _self.byDay : byDay // ignore: cast_nullable_to_non_nullable
as List<DailySummary>,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklySummary].
extension WeeklySummaryPatterns on WeeklySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklySummary value)  $default,){
final _that = this;
switch (_that) {
case _WeeklySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklySummary value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String weekStart,  String weekEnd,  int totalExpense,  int totalIncome,  int billTotal,  List<CategorySummary> byCategory,  List<DailySummary> byDay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklySummary() when $default != null:
return $default(_that.weekStart,_that.weekEnd,_that.totalExpense,_that.totalIncome,_that.billTotal,_that.byCategory,_that.byDay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String weekStart,  String weekEnd,  int totalExpense,  int totalIncome,  int billTotal,  List<CategorySummary> byCategory,  List<DailySummary> byDay)  $default,) {final _that = this;
switch (_that) {
case _WeeklySummary():
return $default(_that.weekStart,_that.weekEnd,_that.totalExpense,_that.totalIncome,_that.billTotal,_that.byCategory,_that.byDay);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String weekStart,  String weekEnd,  int totalExpense,  int totalIncome,  int billTotal,  List<CategorySummary> byCategory,  List<DailySummary> byDay)?  $default,) {final _that = this;
switch (_that) {
case _WeeklySummary() when $default != null:
return $default(_that.weekStart,_that.weekEnd,_that.totalExpense,_that.totalIncome,_that.billTotal,_that.byCategory,_that.byDay);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklySummary implements WeeklySummary {
  const _WeeklySummary({required this.weekStart, required this.weekEnd, required this.totalExpense, this.totalIncome = 0, this.billTotal = 0, required final  List<CategorySummary> byCategory, required final  List<DailySummary> byDay}): _byCategory = byCategory,_byDay = byDay;
  factory _WeeklySummary.fromJson(Map<String, dynamic> json) => _$WeeklySummaryFromJson(json);

@override final  String weekStart;
@override final  String weekEnd;
@override final  int totalExpense;
@override@JsonKey() final  int totalIncome;
@override@JsonKey() final  int billTotal;
 final  List<CategorySummary> _byCategory;
@override List<CategorySummary> get byCategory {
  if (_byCategory is EqualUnmodifiableListView) return _byCategory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byCategory);
}

 final  List<DailySummary> _byDay;
@override List<DailySummary> get byDay {
  if (_byDay is EqualUnmodifiableListView) return _byDay;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byDay);
}


/// Create a copy of WeeklySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklySummaryCopyWith<_WeeklySummary> get copyWith => __$WeeklySummaryCopyWithImpl<_WeeklySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklySummary&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.weekEnd, weekEnd) || other.weekEnd == weekEnd)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.billTotal, billTotal) || other.billTotal == billTotal)&&const DeepCollectionEquality().equals(other._byCategory, _byCategory)&&const DeepCollectionEquality().equals(other._byDay, _byDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekStart,weekEnd,totalExpense,totalIncome,billTotal,const DeepCollectionEquality().hash(_byCategory),const DeepCollectionEquality().hash(_byDay));

@override
String toString() {
  return 'WeeklySummary(weekStart: $weekStart, weekEnd: $weekEnd, totalExpense: $totalExpense, totalIncome: $totalIncome, billTotal: $billTotal, byCategory: $byCategory, byDay: $byDay)';
}


}

/// @nodoc
abstract mixin class _$WeeklySummaryCopyWith<$Res> implements $WeeklySummaryCopyWith<$Res> {
  factory _$WeeklySummaryCopyWith(_WeeklySummary value, $Res Function(_WeeklySummary) _then) = __$WeeklySummaryCopyWithImpl;
@override @useResult
$Res call({
 String weekStart, String weekEnd, int totalExpense, int totalIncome, int billTotal, List<CategorySummary> byCategory, List<DailySummary> byDay
});




}
/// @nodoc
class __$WeeklySummaryCopyWithImpl<$Res>
    implements _$WeeklySummaryCopyWith<$Res> {
  __$WeeklySummaryCopyWithImpl(this._self, this._then);

  final _WeeklySummary _self;
  final $Res Function(_WeeklySummary) _then;

/// Create a copy of WeeklySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekStart = null,Object? weekEnd = null,Object? totalExpense = null,Object? totalIncome = null,Object? billTotal = null,Object? byCategory = null,Object? byDay = null,}) {
  return _then(_WeeklySummary(
weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as String,weekEnd: null == weekEnd ? _self.weekEnd : weekEnd // ignore: cast_nullable_to_non_nullable
as String,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as int,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as int,billTotal: null == billTotal ? _self.billTotal : billTotal // ignore: cast_nullable_to_non_nullable
as int,byCategory: null == byCategory ? _self._byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as List<CategorySummary>,byDay: null == byDay ? _self._byDay : byDay // ignore: cast_nullable_to_non_nullable
as List<DailySummary>,
  ));
}


}


/// @nodoc
mixin _$MonthlyPoint {

 int get month; int get expense; int get income;
/// Create a copy of MonthlyPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthlyPointCopyWith<MonthlyPoint> get copyWith => _$MonthlyPointCopyWithImpl<MonthlyPoint>(this as MonthlyPoint, _$identity);

  /// Serializes this MonthlyPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthlyPoint&&(identical(other.month, month) || other.month == month)&&(identical(other.expense, expense) || other.expense == expense)&&(identical(other.income, income) || other.income == income));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,expense,income);

@override
String toString() {
  return 'MonthlyPoint(month: $month, expense: $expense, income: $income)';
}


}

/// @nodoc
abstract mixin class $MonthlyPointCopyWith<$Res>  {
  factory $MonthlyPointCopyWith(MonthlyPoint value, $Res Function(MonthlyPoint) _then) = _$MonthlyPointCopyWithImpl;
@useResult
$Res call({
 int month, int expense, int income
});




}
/// @nodoc
class _$MonthlyPointCopyWithImpl<$Res>
    implements $MonthlyPointCopyWith<$Res> {
  _$MonthlyPointCopyWithImpl(this._self, this._then);

  final MonthlyPoint _self;
  final $Res Function(MonthlyPoint) _then;

/// Create a copy of MonthlyPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? expense = null,Object? income = null,}) {
  return _then(_self.copyWith(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,expense: null == expense ? _self.expense : expense // ignore: cast_nullable_to_non_nullable
as int,income: null == income ? _self.income : income // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthlyPoint].
extension MonthlyPointPatterns on MonthlyPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthlyPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthlyPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthlyPoint value)  $default,){
final _that = this;
switch (_that) {
case _MonthlyPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthlyPoint value)?  $default,){
final _that = this;
switch (_that) {
case _MonthlyPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int month,  int expense,  int income)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthlyPoint() when $default != null:
return $default(_that.month,_that.expense,_that.income);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int month,  int expense,  int income)  $default,) {final _that = this;
switch (_that) {
case _MonthlyPoint():
return $default(_that.month,_that.expense,_that.income);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int month,  int expense,  int income)?  $default,) {final _that = this;
switch (_that) {
case _MonthlyPoint() when $default != null:
return $default(_that.month,_that.expense,_that.income);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthlyPoint implements MonthlyPoint {
  const _MonthlyPoint({required this.month, required this.expense, this.income = 0});
  factory _MonthlyPoint.fromJson(Map<String, dynamic> json) => _$MonthlyPointFromJson(json);

@override final  int month;
@override final  int expense;
@override@JsonKey() final  int income;

/// Create a copy of MonthlyPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthlyPointCopyWith<_MonthlyPoint> get copyWith => __$MonthlyPointCopyWithImpl<_MonthlyPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthlyPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthlyPoint&&(identical(other.month, month) || other.month == month)&&(identical(other.expense, expense) || other.expense == expense)&&(identical(other.income, income) || other.income == income));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,month,expense,income);

@override
String toString() {
  return 'MonthlyPoint(month: $month, expense: $expense, income: $income)';
}


}

/// @nodoc
abstract mixin class _$MonthlyPointCopyWith<$Res> implements $MonthlyPointCopyWith<$Res> {
  factory _$MonthlyPointCopyWith(_MonthlyPoint value, $Res Function(_MonthlyPoint) _then) = __$MonthlyPointCopyWithImpl;
@override @useResult
$Res call({
 int month, int expense, int income
});




}
/// @nodoc
class __$MonthlyPointCopyWithImpl<$Res>
    implements _$MonthlyPointCopyWith<$Res> {
  __$MonthlyPointCopyWithImpl(this._self, this._then);

  final _MonthlyPoint _self;
  final $Res Function(_MonthlyPoint) _then;

/// Create a copy of MonthlyPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? expense = null,Object? income = null,}) {
  return _then(_MonthlyPoint(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int,expense: null == expense ? _self.expense : expense // ignore: cast_nullable_to_non_nullable
as int,income: null == income ? _self.income : income // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$YearlySummary {

 int get year; int get totalExpense; int get totalIncome; int get billTotal; List<CategorySummary> get byCategory; List<MonthlyPoint> get byMonth;
/// Create a copy of YearlySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YearlySummaryCopyWith<YearlySummary> get copyWith => _$YearlySummaryCopyWithImpl<YearlySummary>(this as YearlySummary, _$identity);

  /// Serializes this YearlySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YearlySummary&&(identical(other.year, year) || other.year == year)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.billTotal, billTotal) || other.billTotal == billTotal)&&const DeepCollectionEquality().equals(other.byCategory, byCategory)&&const DeepCollectionEquality().equals(other.byMonth, byMonth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,totalExpense,totalIncome,billTotal,const DeepCollectionEquality().hash(byCategory),const DeepCollectionEquality().hash(byMonth));

@override
String toString() {
  return 'YearlySummary(year: $year, totalExpense: $totalExpense, totalIncome: $totalIncome, billTotal: $billTotal, byCategory: $byCategory, byMonth: $byMonth)';
}


}

/// @nodoc
abstract mixin class $YearlySummaryCopyWith<$Res>  {
  factory $YearlySummaryCopyWith(YearlySummary value, $Res Function(YearlySummary) _then) = _$YearlySummaryCopyWithImpl;
@useResult
$Res call({
 int year, int totalExpense, int totalIncome, int billTotal, List<CategorySummary> byCategory, List<MonthlyPoint> byMonth
});




}
/// @nodoc
class _$YearlySummaryCopyWithImpl<$Res>
    implements $YearlySummaryCopyWith<$Res> {
  _$YearlySummaryCopyWithImpl(this._self, this._then);

  final YearlySummary _self;
  final $Res Function(YearlySummary) _then;

/// Create a copy of YearlySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? year = null,Object? totalExpense = null,Object? totalIncome = null,Object? billTotal = null,Object? byCategory = null,Object? byMonth = null,}) {
  return _then(_self.copyWith(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as int,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as int,billTotal: null == billTotal ? _self.billTotal : billTotal // ignore: cast_nullable_to_non_nullable
as int,byCategory: null == byCategory ? _self.byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as List<CategorySummary>,byMonth: null == byMonth ? _self.byMonth : byMonth // ignore: cast_nullable_to_non_nullable
as List<MonthlyPoint>,
  ));
}

}


/// Adds pattern-matching-related methods to [YearlySummary].
extension YearlySummaryPatterns on YearlySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YearlySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YearlySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YearlySummary value)  $default,){
final _that = this;
switch (_that) {
case _YearlySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YearlySummary value)?  $default,){
final _that = this;
switch (_that) {
case _YearlySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int year,  int totalExpense,  int totalIncome,  int billTotal,  List<CategorySummary> byCategory,  List<MonthlyPoint> byMonth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YearlySummary() when $default != null:
return $default(_that.year,_that.totalExpense,_that.totalIncome,_that.billTotal,_that.byCategory,_that.byMonth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int year,  int totalExpense,  int totalIncome,  int billTotal,  List<CategorySummary> byCategory,  List<MonthlyPoint> byMonth)  $default,) {final _that = this;
switch (_that) {
case _YearlySummary():
return $default(_that.year,_that.totalExpense,_that.totalIncome,_that.billTotal,_that.byCategory,_that.byMonth);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int year,  int totalExpense,  int totalIncome,  int billTotal,  List<CategorySummary> byCategory,  List<MonthlyPoint> byMonth)?  $default,) {final _that = this;
switch (_that) {
case _YearlySummary() when $default != null:
return $default(_that.year,_that.totalExpense,_that.totalIncome,_that.billTotal,_that.byCategory,_that.byMonth);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _YearlySummary implements YearlySummary {
  const _YearlySummary({required this.year, required this.totalExpense, this.totalIncome = 0, this.billTotal = 0, required final  List<CategorySummary> byCategory, required final  List<MonthlyPoint> byMonth}): _byCategory = byCategory,_byMonth = byMonth;
  factory _YearlySummary.fromJson(Map<String, dynamic> json) => _$YearlySummaryFromJson(json);

@override final  int year;
@override final  int totalExpense;
@override@JsonKey() final  int totalIncome;
@override@JsonKey() final  int billTotal;
 final  List<CategorySummary> _byCategory;
@override List<CategorySummary> get byCategory {
  if (_byCategory is EqualUnmodifiableListView) return _byCategory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byCategory);
}

 final  List<MonthlyPoint> _byMonth;
@override List<MonthlyPoint> get byMonth {
  if (_byMonth is EqualUnmodifiableListView) return _byMonth;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byMonth);
}


/// Create a copy of YearlySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YearlySummaryCopyWith<_YearlySummary> get copyWith => __$YearlySummaryCopyWithImpl<_YearlySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$YearlySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YearlySummary&&(identical(other.year, year) || other.year == year)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.billTotal, billTotal) || other.billTotal == billTotal)&&const DeepCollectionEquality().equals(other._byCategory, _byCategory)&&const DeepCollectionEquality().equals(other._byMonth, _byMonth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,year,totalExpense,totalIncome,billTotal,const DeepCollectionEquality().hash(_byCategory),const DeepCollectionEquality().hash(_byMonth));

@override
String toString() {
  return 'YearlySummary(year: $year, totalExpense: $totalExpense, totalIncome: $totalIncome, billTotal: $billTotal, byCategory: $byCategory, byMonth: $byMonth)';
}


}

/// @nodoc
abstract mixin class _$YearlySummaryCopyWith<$Res> implements $YearlySummaryCopyWith<$Res> {
  factory _$YearlySummaryCopyWith(_YearlySummary value, $Res Function(_YearlySummary) _then) = __$YearlySummaryCopyWithImpl;
@override @useResult
$Res call({
 int year, int totalExpense, int totalIncome, int billTotal, List<CategorySummary> byCategory, List<MonthlyPoint> byMonth
});




}
/// @nodoc
class __$YearlySummaryCopyWithImpl<$Res>
    implements _$YearlySummaryCopyWith<$Res> {
  __$YearlySummaryCopyWithImpl(this._self, this._then);

  final _YearlySummary _self;
  final $Res Function(_YearlySummary) _then;

/// Create a copy of YearlySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? year = null,Object? totalExpense = null,Object? totalIncome = null,Object? billTotal = null,Object? byCategory = null,Object? byMonth = null,}) {
  return _then(_YearlySummary(
year: null == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as int,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as int,billTotal: null == billTotal ? _self.billTotal : billTotal // ignore: cast_nullable_to_non_nullable
as int,byCategory: null == byCategory ? _self._byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as List<CategorySummary>,byMonth: null == byMonth ? _self._byMonth : byMonth // ignore: cast_nullable_to_non_nullable
as List<MonthlyPoint>,
  ));
}


}


/// @nodoc
mixin _$ReceiptListItem {

 String get receiptId; String get storeName; int get totalAmount; String get purchasedAt; String get paymentMethod; String get category; List<ReceiptItem> get items; bool get isTaxExempt; String? get memo;
/// Create a copy of ReceiptListItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptListItemCopyWith<ReceiptListItem> get copyWith => _$ReceiptListItemCopyWithImpl<ReceiptListItem>(this as ReceiptListItem, _$identity);

  /// Serializes this ReceiptListItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptListItem&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.isTaxExempt, isTaxExempt) || other.isTaxExempt == isTaxExempt)&&(identical(other.memo, memo) || other.memo == memo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,receiptId,storeName,totalAmount,purchasedAt,paymentMethod,category,const DeepCollectionEquality().hash(items),isTaxExempt,memo);

@override
String toString() {
  return 'ReceiptListItem(receiptId: $receiptId, storeName: $storeName, totalAmount: $totalAmount, purchasedAt: $purchasedAt, paymentMethod: $paymentMethod, category: $category, items: $items, isTaxExempt: $isTaxExempt, memo: $memo)';
}


}

/// @nodoc
abstract mixin class $ReceiptListItemCopyWith<$Res>  {
  factory $ReceiptListItemCopyWith(ReceiptListItem value, $Res Function(ReceiptListItem) _then) = _$ReceiptListItemCopyWithImpl;
@useResult
$Res call({
 String receiptId, String storeName, int totalAmount, String purchasedAt, String paymentMethod, String category, List<ReceiptItem> items, bool isTaxExempt, String? memo
});




}
/// @nodoc
class _$ReceiptListItemCopyWithImpl<$Res>
    implements $ReceiptListItemCopyWith<$Res> {
  _$ReceiptListItemCopyWithImpl(this._self, this._then);

  final ReceiptListItem _self;
  final $Res Function(ReceiptListItem) _then;

/// Create a copy of ReceiptListItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? receiptId = null,Object? storeName = null,Object? totalAmount = null,Object? purchasedAt = null,Object? paymentMethod = null,Object? category = null,Object? items = null,Object? isTaxExempt = null,Object? memo = freezed,}) {
  return _then(_self.copyWith(
receiptId: null == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String,storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,purchasedAt: null == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as String,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ReceiptItem>,isTaxExempt: null == isTaxExempt ? _self.isTaxExempt : isTaxExempt // ignore: cast_nullable_to_non_nullable
as bool,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceiptListItem].
extension ReceiptListItemPatterns on ReceiptListItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptListItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptListItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptListItem value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptListItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptListItem value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptListItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String receiptId,  String storeName,  int totalAmount,  String purchasedAt,  String paymentMethod,  String category,  List<ReceiptItem> items,  bool isTaxExempt,  String? memo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptListItem() when $default != null:
return $default(_that.receiptId,_that.storeName,_that.totalAmount,_that.purchasedAt,_that.paymentMethod,_that.category,_that.items,_that.isTaxExempt,_that.memo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String receiptId,  String storeName,  int totalAmount,  String purchasedAt,  String paymentMethod,  String category,  List<ReceiptItem> items,  bool isTaxExempt,  String? memo)  $default,) {final _that = this;
switch (_that) {
case _ReceiptListItem():
return $default(_that.receiptId,_that.storeName,_that.totalAmount,_that.purchasedAt,_that.paymentMethod,_that.category,_that.items,_that.isTaxExempt,_that.memo);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String receiptId,  String storeName,  int totalAmount,  String purchasedAt,  String paymentMethod,  String category,  List<ReceiptItem> items,  bool isTaxExempt,  String? memo)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptListItem() when $default != null:
return $default(_that.receiptId,_that.storeName,_that.totalAmount,_that.purchasedAt,_that.paymentMethod,_that.category,_that.items,_that.isTaxExempt,_that.memo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReceiptListItem implements ReceiptListItem {
  const _ReceiptListItem({required this.receiptId, required this.storeName, required this.totalAmount, required this.purchasedAt, this.paymentMethod = 'cash', this.category = 'other', final  List<ReceiptItem> items = const [], this.isTaxExempt = false, this.memo}): _items = items;
  factory _ReceiptListItem.fromJson(Map<String, dynamic> json) => _$ReceiptListItemFromJson(json);

@override final  String receiptId;
@override final  String storeName;
@override final  int totalAmount;
@override final  String purchasedAt;
@override@JsonKey() final  String paymentMethod;
@override@JsonKey() final  String category;
 final  List<ReceiptItem> _items;
@override@JsonKey() List<ReceiptItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  bool isTaxExempt;
@override final  String? memo;

/// Create a copy of ReceiptListItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptListItemCopyWith<_ReceiptListItem> get copyWith => __$ReceiptListItemCopyWithImpl<_ReceiptListItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptListItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptListItem&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.isTaxExempt, isTaxExempt) || other.isTaxExempt == isTaxExempt)&&(identical(other.memo, memo) || other.memo == memo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,receiptId,storeName,totalAmount,purchasedAt,paymentMethod,category,const DeepCollectionEquality().hash(_items),isTaxExempt,memo);

@override
String toString() {
  return 'ReceiptListItem(receiptId: $receiptId, storeName: $storeName, totalAmount: $totalAmount, purchasedAt: $purchasedAt, paymentMethod: $paymentMethod, category: $category, items: $items, isTaxExempt: $isTaxExempt, memo: $memo)';
}


}

/// @nodoc
abstract mixin class _$ReceiptListItemCopyWith<$Res> implements $ReceiptListItemCopyWith<$Res> {
  factory _$ReceiptListItemCopyWith(_ReceiptListItem value, $Res Function(_ReceiptListItem) _then) = __$ReceiptListItemCopyWithImpl;
@override @useResult
$Res call({
 String receiptId, String storeName, int totalAmount, String purchasedAt, String paymentMethod, String category, List<ReceiptItem> items, bool isTaxExempt, String? memo
});




}
/// @nodoc
class __$ReceiptListItemCopyWithImpl<$Res>
    implements _$ReceiptListItemCopyWith<$Res> {
  __$ReceiptListItemCopyWithImpl(this._self, this._then);

  final _ReceiptListItem _self;
  final $Res Function(_ReceiptListItem) _then;

/// Create a copy of ReceiptListItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? receiptId = null,Object? storeName = null,Object? totalAmount = null,Object? purchasedAt = null,Object? paymentMethod = null,Object? category = null,Object? items = null,Object? isTaxExempt = null,Object? memo = freezed,}) {
  return _then(_ReceiptListItem(
receiptId: null == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String,storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,purchasedAt: null == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as String,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ReceiptItem>,isTaxExempt: null == isTaxExempt ? _self.isTaxExempt : isTaxExempt // ignore: cast_nullable_to_non_nullable
as bool,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RecentReceipt {

 String get receiptId; String get storeName; int get totalAmount; String get purchasedAt; bool get isBill; String? get billId;
/// Create a copy of RecentReceipt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentReceiptCopyWith<RecentReceipt> get copyWith => _$RecentReceiptCopyWithImpl<RecentReceipt>(this as RecentReceipt, _$identity);

  /// Serializes this RecentReceipt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentReceipt&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.isBill, isBill) || other.isBill == isBill)&&(identical(other.billId, billId) || other.billId == billId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,receiptId,storeName,totalAmount,purchasedAt,isBill,billId);

@override
String toString() {
  return 'RecentReceipt(receiptId: $receiptId, storeName: $storeName, totalAmount: $totalAmount, purchasedAt: $purchasedAt, isBill: $isBill, billId: $billId)';
}


}

/// @nodoc
abstract mixin class $RecentReceiptCopyWith<$Res>  {
  factory $RecentReceiptCopyWith(RecentReceipt value, $Res Function(RecentReceipt) _then) = _$RecentReceiptCopyWithImpl;
@useResult
$Res call({
 String receiptId, String storeName, int totalAmount, String purchasedAt, bool isBill, String? billId
});




}
/// @nodoc
class _$RecentReceiptCopyWithImpl<$Res>
    implements $RecentReceiptCopyWith<$Res> {
  _$RecentReceiptCopyWithImpl(this._self, this._then);

  final RecentReceipt _self;
  final $Res Function(RecentReceipt) _then;

/// Create a copy of RecentReceipt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? receiptId = null,Object? storeName = null,Object? totalAmount = null,Object? purchasedAt = null,Object? isBill = null,Object? billId = freezed,}) {
  return _then(_self.copyWith(
receiptId: null == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String,storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,purchasedAt: null == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as String,isBill: null == isBill ? _self.isBill : isBill // ignore: cast_nullable_to_non_nullable
as bool,billId: freezed == billId ? _self.billId : billId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecentReceipt].
extension RecentReceiptPatterns on RecentReceipt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecentReceipt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecentReceipt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecentReceipt value)  $default,){
final _that = this;
switch (_that) {
case _RecentReceipt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecentReceipt value)?  $default,){
final _that = this;
switch (_that) {
case _RecentReceipt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String receiptId,  String storeName,  int totalAmount,  String purchasedAt,  bool isBill,  String? billId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecentReceipt() when $default != null:
return $default(_that.receiptId,_that.storeName,_that.totalAmount,_that.purchasedAt,_that.isBill,_that.billId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String receiptId,  String storeName,  int totalAmount,  String purchasedAt,  bool isBill,  String? billId)  $default,) {final _that = this;
switch (_that) {
case _RecentReceipt():
return $default(_that.receiptId,_that.storeName,_that.totalAmount,_that.purchasedAt,_that.isBill,_that.billId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String receiptId,  String storeName,  int totalAmount,  String purchasedAt,  bool isBill,  String? billId)?  $default,) {final _that = this;
switch (_that) {
case _RecentReceipt() when $default != null:
return $default(_that.receiptId,_that.storeName,_that.totalAmount,_that.purchasedAt,_that.isBill,_that.billId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecentReceipt implements RecentReceipt {
  const _RecentReceipt({required this.receiptId, required this.storeName, required this.totalAmount, required this.purchasedAt, this.isBill = false, this.billId});
  factory _RecentReceipt.fromJson(Map<String, dynamic> json) => _$RecentReceiptFromJson(json);

@override final  String receiptId;
@override final  String storeName;
@override final  int totalAmount;
@override final  String purchasedAt;
@override@JsonKey() final  bool isBill;
@override final  String? billId;

/// Create a copy of RecentReceipt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecentReceiptCopyWith<_RecentReceipt> get copyWith => __$RecentReceiptCopyWithImpl<_RecentReceipt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecentReceiptToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecentReceipt&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.storeName, storeName) || other.storeName == storeName)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.isBill, isBill) || other.isBill == isBill)&&(identical(other.billId, billId) || other.billId == billId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,receiptId,storeName,totalAmount,purchasedAt,isBill,billId);

@override
String toString() {
  return 'RecentReceipt(receiptId: $receiptId, storeName: $storeName, totalAmount: $totalAmount, purchasedAt: $purchasedAt, isBill: $isBill, billId: $billId)';
}


}

/// @nodoc
abstract mixin class _$RecentReceiptCopyWith<$Res> implements $RecentReceiptCopyWith<$Res> {
  factory _$RecentReceiptCopyWith(_RecentReceipt value, $Res Function(_RecentReceipt) _then) = __$RecentReceiptCopyWithImpl;
@override @useResult
$Res call({
 String receiptId, String storeName, int totalAmount, String purchasedAt, bool isBill, String? billId
});




}
/// @nodoc
class __$RecentReceiptCopyWithImpl<$Res>
    implements _$RecentReceiptCopyWith<$Res> {
  __$RecentReceiptCopyWithImpl(this._self, this._then);

  final _RecentReceipt _self;
  final $Res Function(_RecentReceipt) _then;

/// Create a copy of RecentReceipt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? receiptId = null,Object? storeName = null,Object? totalAmount = null,Object? purchasedAt = null,Object? isBill = null,Object? billId = freezed,}) {
  return _then(_RecentReceipt(
receiptId: null == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String,storeName: null == storeName ? _self.storeName : storeName // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,purchasedAt: null == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as String,isBill: null == isBill ? _self.isBill : isBill // ignore: cast_nullable_to_non_nullable
as bool,billId: freezed == billId ? _self.billId : billId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MonthlySummary {

 String get yearMonth; int get totalExpense; int get totalIncome; int get score; int get billTotal; int get totalSavings; List<CategorySummary> get byCategory; List<RecentReceipt> get recentReceipts; List<RecentReceipt> get allReceipts;
/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthlySummaryCopyWith<MonthlySummary> get copyWith => _$MonthlySummaryCopyWithImpl<MonthlySummary>(this as MonthlySummary, _$identity);

  /// Serializes this MonthlySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthlySummary&&(identical(other.yearMonth, yearMonth) || other.yearMonth == yearMonth)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.score, score) || other.score == score)&&(identical(other.billTotal, billTotal) || other.billTotal == billTotal)&&(identical(other.totalSavings, totalSavings) || other.totalSavings == totalSavings)&&const DeepCollectionEquality().equals(other.byCategory, byCategory)&&const DeepCollectionEquality().equals(other.recentReceipts, recentReceipts)&&const DeepCollectionEquality().equals(other.allReceipts, allReceipts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,yearMonth,totalExpense,totalIncome,score,billTotal,totalSavings,const DeepCollectionEquality().hash(byCategory),const DeepCollectionEquality().hash(recentReceipts),const DeepCollectionEquality().hash(allReceipts));

@override
String toString() {
  return 'MonthlySummary(yearMonth: $yearMonth, totalExpense: $totalExpense, totalIncome: $totalIncome, score: $score, billTotal: $billTotal, totalSavings: $totalSavings, byCategory: $byCategory, recentReceipts: $recentReceipts, allReceipts: $allReceipts)';
}


}

/// @nodoc
abstract mixin class $MonthlySummaryCopyWith<$Res>  {
  factory $MonthlySummaryCopyWith(MonthlySummary value, $Res Function(MonthlySummary) _then) = _$MonthlySummaryCopyWithImpl;
@useResult
$Res call({
 String yearMonth, int totalExpense, int totalIncome, int score, int billTotal, int totalSavings, List<CategorySummary> byCategory, List<RecentReceipt> recentReceipts, List<RecentReceipt> allReceipts
});




}
/// @nodoc
class _$MonthlySummaryCopyWithImpl<$Res>
    implements $MonthlySummaryCopyWith<$Res> {
  _$MonthlySummaryCopyWithImpl(this._self, this._then);

  final MonthlySummary _self;
  final $Res Function(MonthlySummary) _then;

/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? yearMonth = null,Object? totalExpense = null,Object? totalIncome = null,Object? score = null,Object? billTotal = null,Object? totalSavings = null,Object? byCategory = null,Object? recentReceipts = null,Object? allReceipts = null,}) {
  return _then(_self.copyWith(
yearMonth: null == yearMonth ? _self.yearMonth : yearMonth // ignore: cast_nullable_to_non_nullable
as String,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as int,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as int,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,billTotal: null == billTotal ? _self.billTotal : billTotal // ignore: cast_nullable_to_non_nullable
as int,totalSavings: null == totalSavings ? _self.totalSavings : totalSavings // ignore: cast_nullable_to_non_nullable
as int,byCategory: null == byCategory ? _self.byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as List<CategorySummary>,recentReceipts: null == recentReceipts ? _self.recentReceipts : recentReceipts // ignore: cast_nullable_to_non_nullable
as List<RecentReceipt>,allReceipts: null == allReceipts ? _self.allReceipts : allReceipts // ignore: cast_nullable_to_non_nullable
as List<RecentReceipt>,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthlySummary].
extension MonthlySummaryPatterns on MonthlySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthlySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthlySummary value)  $default,){
final _that = this;
switch (_that) {
case _MonthlySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthlySummary value)?  $default,){
final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String yearMonth,  int totalExpense,  int totalIncome,  int score,  int billTotal,  int totalSavings,  List<CategorySummary> byCategory,  List<RecentReceipt> recentReceipts,  List<RecentReceipt> allReceipts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
return $default(_that.yearMonth,_that.totalExpense,_that.totalIncome,_that.score,_that.billTotal,_that.totalSavings,_that.byCategory,_that.recentReceipts,_that.allReceipts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String yearMonth,  int totalExpense,  int totalIncome,  int score,  int billTotal,  int totalSavings,  List<CategorySummary> byCategory,  List<RecentReceipt> recentReceipts,  List<RecentReceipt> allReceipts)  $default,) {final _that = this;
switch (_that) {
case _MonthlySummary():
return $default(_that.yearMonth,_that.totalExpense,_that.totalIncome,_that.score,_that.billTotal,_that.totalSavings,_that.byCategory,_that.recentReceipts,_that.allReceipts);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String yearMonth,  int totalExpense,  int totalIncome,  int score,  int billTotal,  int totalSavings,  List<CategorySummary> byCategory,  List<RecentReceipt> recentReceipts,  List<RecentReceipt> allReceipts)?  $default,) {final _that = this;
switch (_that) {
case _MonthlySummary() when $default != null:
return $default(_that.yearMonth,_that.totalExpense,_that.totalIncome,_that.score,_that.billTotal,_that.totalSavings,_that.byCategory,_that.recentReceipts,_that.allReceipts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonthlySummary implements MonthlySummary {
  const _MonthlySummary({required this.yearMonth, required this.totalExpense, this.totalIncome = 0, this.score = 0, this.billTotal = 0, this.totalSavings = 0, required final  List<CategorySummary> byCategory, required final  List<RecentReceipt> recentReceipts, required final  List<RecentReceipt> allReceipts}): _byCategory = byCategory,_recentReceipts = recentReceipts,_allReceipts = allReceipts;
  factory _MonthlySummary.fromJson(Map<String, dynamic> json) => _$MonthlySummaryFromJson(json);

@override final  String yearMonth;
@override final  int totalExpense;
@override@JsonKey() final  int totalIncome;
@override@JsonKey() final  int score;
@override@JsonKey() final  int billTotal;
@override@JsonKey() final  int totalSavings;
 final  List<CategorySummary> _byCategory;
@override List<CategorySummary> get byCategory {
  if (_byCategory is EqualUnmodifiableListView) return _byCategory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byCategory);
}

 final  List<RecentReceipt> _recentReceipts;
@override List<RecentReceipt> get recentReceipts {
  if (_recentReceipts is EqualUnmodifiableListView) return _recentReceipts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentReceipts);
}

 final  List<RecentReceipt> _allReceipts;
@override List<RecentReceipt> get allReceipts {
  if (_allReceipts is EqualUnmodifiableListView) return _allReceipts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allReceipts);
}


/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthlySummaryCopyWith<_MonthlySummary> get copyWith => __$MonthlySummaryCopyWithImpl<_MonthlySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonthlySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthlySummary&&(identical(other.yearMonth, yearMonth) || other.yearMonth == yearMonth)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.score, score) || other.score == score)&&(identical(other.billTotal, billTotal) || other.billTotal == billTotal)&&(identical(other.totalSavings, totalSavings) || other.totalSavings == totalSavings)&&const DeepCollectionEquality().equals(other._byCategory, _byCategory)&&const DeepCollectionEquality().equals(other._recentReceipts, _recentReceipts)&&const DeepCollectionEquality().equals(other._allReceipts, _allReceipts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,yearMonth,totalExpense,totalIncome,score,billTotal,totalSavings,const DeepCollectionEquality().hash(_byCategory),const DeepCollectionEquality().hash(_recentReceipts),const DeepCollectionEquality().hash(_allReceipts));

@override
String toString() {
  return 'MonthlySummary(yearMonth: $yearMonth, totalExpense: $totalExpense, totalIncome: $totalIncome, score: $score, billTotal: $billTotal, totalSavings: $totalSavings, byCategory: $byCategory, recentReceipts: $recentReceipts, allReceipts: $allReceipts)';
}


}

/// @nodoc
abstract mixin class _$MonthlySummaryCopyWith<$Res> implements $MonthlySummaryCopyWith<$Res> {
  factory _$MonthlySummaryCopyWith(_MonthlySummary value, $Res Function(_MonthlySummary) _then) = __$MonthlySummaryCopyWithImpl;
@override @useResult
$Res call({
 String yearMonth, int totalExpense, int totalIncome, int score, int billTotal, int totalSavings, List<CategorySummary> byCategory, List<RecentReceipt> recentReceipts, List<RecentReceipt> allReceipts
});




}
/// @nodoc
class __$MonthlySummaryCopyWithImpl<$Res>
    implements _$MonthlySummaryCopyWith<$Res> {
  __$MonthlySummaryCopyWithImpl(this._self, this._then);

  final _MonthlySummary _self;
  final $Res Function(_MonthlySummary) _then;

/// Create a copy of MonthlySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? yearMonth = null,Object? totalExpense = null,Object? totalIncome = null,Object? score = null,Object? billTotal = null,Object? totalSavings = null,Object? byCategory = null,Object? recentReceipts = null,Object? allReceipts = null,}) {
  return _then(_MonthlySummary(
yearMonth: null == yearMonth ? _self.yearMonth : yearMonth // ignore: cast_nullable_to_non_nullable
as String,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as int,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as int,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,billTotal: null == billTotal ? _self.billTotal : billTotal // ignore: cast_nullable_to_non_nullable
as int,totalSavings: null == totalSavings ? _self.totalSavings : totalSavings // ignore: cast_nullable_to_non_nullable
as int,byCategory: null == byCategory ? _self._byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as List<CategorySummary>,recentReceipts: null == recentReceipts ? _self._recentReceipts : recentReceipts // ignore: cast_nullable_to_non_nullable
as List<RecentReceipt>,allReceipts: null == allReceipts ? _self._allReceipts : allReceipts // ignore: cast_nullable_to_non_nullable
as List<RecentReceipt>,
  ));
}


}

// dart format on

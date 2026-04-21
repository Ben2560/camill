// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fixed_expense_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FixedExpenseSetting _$FixedExpenseSettingFromJson(Map<String, dynamic> json) =>
    _FixedExpenseSetting(
      category: json['category'] as String,
      billingDay: (json['billing_day'] as num?)?.toInt(),
      holidayRule: json['holiday_rule'] as String?,
    );

Map<String, dynamic> _$FixedExpenseSettingToJson(
  _FixedExpenseSetting instance,
) => <String, dynamic>{
  'category': instance.category,
  'billing_day': instance.billingDay,
  'holiday_rule': instance.holidayRule,
};

_FixedPayment _$FixedPaymentFromJson(Map<String, dynamic> json) =>
    _FixedPayment(
      category: json['category'] as String,
      yearMonth: json['year_month'] as String,
      paidAt: DateTime.parse(json['paid_at'] as String),
      confirmedBy: json['confirmed_by'] as String,
      amount: (json['amount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FixedPaymentToJson(_FixedPayment instance) =>
    <String, dynamic>{
      'category': instance.category,
      'year_month': instance.yearMonth,
      'paid_at': instance.paidAt.toIso8601String(),
      'confirmed_by': instance.confirmedBy,
      'amount': instance.amount,
    };

_BankTransaction _$BankTransactionFromJson(Map<String, dynamic> json) =>
    _BankTransaction(
      date: json['date'] as String,
      description: json['description'] as String,
      amount: _amountToInt(json['amount'] as num),
      matchedCategory: json['matched_category'] as String?,
    );

Map<String, dynamic> _$BankTransactionToJson(_BankTransaction instance) =>
    <String, dynamic>{
      'date': instance.date,
      'description': instance.description,
      'amount': instance.amount,
      'matched_category': instance.matchedCategory,
    };

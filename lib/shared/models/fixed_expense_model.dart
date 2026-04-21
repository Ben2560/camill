import 'package:freezed_annotation/freezed_annotation.dart';

part 'fixed_expense_model.freezed.dart';
part 'fixed_expense_model.g.dart';

int _amountToInt(num v) => v.toInt();

@freezed
sealed class FixedExpenseSetting with _$FixedExpenseSetting {
  const FixedExpenseSetting._();

  const factory FixedExpenseSetting({
    required String category,
    int? billingDay,
    String? holidayRule,
  }) = _FixedExpenseSetting;

  factory FixedExpenseSetting.fromJson(Map<String, dynamic> json) =>
      _$FixedExpenseSettingFromJson(json);

  /// APIレスポンス（category=mapキー, json=値）用ファクトリ
  static FixedExpenseSetting fromEntry(String category, dynamic json) {
    if (json is Map<String, dynamic>) {
      return FixedExpenseSetting(
        category: category,
        billingDay: json['billing_day'] as int?,
        holidayRule: json['holiday_rule'] as String?,
      );
    }
    return FixedExpenseSetting(category: category, billingDay: json as int?);
  }

  String get billingDayLabel {
    if (billingDay == null) return '未設定';
    if (billingDay == 32) return '末日';
    return '$billingDay日';
  }

  String? get holidayRuleLabel {
    switch (holidayRule) {
      case 'before': return '前営業日';
      case 'after':  return '翌営業日';
      default:       return null;
    }
  }
}

@freezed
sealed class FixedPayment with _$FixedPayment {
  const FixedPayment._();

  const factory FixedPayment({
    required String category,
    required String yearMonth,
    required DateTime paidAt,
    required String confirmedBy,
    int? amount,
  }) = _FixedPayment;

  factory FixedPayment.fromJson(Map<String, dynamic> json) =>
      _$FixedPaymentFromJson(json);

  /// APIレスポンス（category・yearMonth は外部から注入）用ファクトリ
  static FixedPayment fromEntry(
      String category, String yearMonth, Map<String, dynamic> json) {
    return FixedPayment(
      category: category,
      yearMonth: yearMonth,
      paidAt: DateTime.parse(json['paid_at'] as String),
      confirmedBy: json['confirmed_by'] as String,
      amount: json['amount'] as int?,
    );
  }

  String get confirmedByLabel {
    switch (confirmedBy) {
      case 'auto': return '自動確認';
      case 'ocr':  return '明細確認';
      default:     return '手動確認';
    }
  }
}

@freezed
sealed class BankTransaction with _$BankTransaction {
  const factory BankTransaction({
    required String date,
    required String description,
    @JsonKey(fromJson: _amountToInt) required int amount,
    String? matchedCategory,
  }) = _BankTransaction;

  factory BankTransaction.fromJson(Map<String, dynamic> json) =>
      _$BankTransactionFromJson(json);
}

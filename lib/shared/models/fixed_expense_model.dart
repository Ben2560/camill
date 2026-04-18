class FixedExpenseSetting {
  final String category;
  final int? billingDay;     // 1-31, 32=末日, null=未設定
  final String? holidayRule; // 'before'=前営業日 | 'after'=翌営業日 | null=そのまま

  const FixedExpenseSetting({
    required this.category,
    this.billingDay,
    this.holidayRule,
  });

  factory FixedExpenseSetting.fromJson(String category, dynamic json) {
    if (json is Map<String, dynamic>) {
      return FixedExpenseSetting(
        category: category,
        billingDay: json['billing_day'] as int?,
        holidayRule: json['holiday_rule'] as String?,
      );
    }
    // 旧フォーマット（int のみ）との互換
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

class FixedPayment {
  final String category;
  final String yearMonth;
  final DateTime paidAt;
  final String confirmedBy; // auto | manual | ocr
  final int? amount;

  const FixedPayment({
    required this.category,
    required this.yearMonth,
    required this.paidAt,
    required this.confirmedBy,
    this.amount,
  });

  factory FixedPayment.fromJson(String category, String yearMonth, Map<String, dynamic> json) {
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
      case 'auto':
        return '自動確認';
      case 'ocr':
        return '明細確認';
      default:
        return '手動確認';
    }
  }
}

class BankTransaction {
  final String date;
  final String description;
  final int amount;
  final String? matchedCategory;

  const BankTransaction({
    required this.date,
    required this.description,
    required this.amount,
    this.matchedCategory,
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    return BankTransaction(
      date: json['date'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toInt(),
      matchedCategory: json['matched_category'] as String?,
    );
  }
}

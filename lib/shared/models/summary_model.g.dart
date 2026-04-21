// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailySummary _$DailySummaryFromJson(Map<String, dynamic> json) =>
    _DailySummary(
      date: _dateOnly(json['date'] as String),
      expense: (json['expense'] as num).toInt(),
      income: (json['income'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$DailySummaryToJson(_DailySummary instance) =>
    <String, dynamic>{
      'date': instance.date,
      'expense': instance.expense,
      'income': instance.income,
    };

_CategorySummary _$CategorySummaryFromJson(Map<String, dynamic> json) =>
    _CategorySummary(
      category: json['category'] as String,
      amount: (json['amount'] as num).toInt(),
    );

Map<String, dynamic> _$CategorySummaryToJson(_CategorySummary instance) =>
    <String, dynamic>{'category': instance.category, 'amount': instance.amount};

_WeeklySummary _$WeeklySummaryFromJson(Map<String, dynamic> json) =>
    _WeeklySummary(
      weekStart: json['week_start'] as String,
      weekEnd: json['week_end'] as String,
      totalExpense: (json['total_expense'] as num).toInt(),
      totalIncome: (json['total_income'] as num?)?.toInt() ?? 0,
      billTotal: (json['bill_total'] as num?)?.toInt() ?? 0,
      byCategory: (json['by_category'] as List<dynamic>)
          .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      byDay: (json['by_day'] as List<dynamic>)
          .map((e) => DailySummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WeeklySummaryToJson(_WeeklySummary instance) =>
    <String, dynamic>{
      'week_start': instance.weekStart,
      'week_end': instance.weekEnd,
      'total_expense': instance.totalExpense,
      'total_income': instance.totalIncome,
      'bill_total': instance.billTotal,
      'by_category': instance.byCategory.map((e) => e.toJson()).toList(),
      'by_day': instance.byDay.map((e) => e.toJson()).toList(),
    };

_MonthlyPoint _$MonthlyPointFromJson(Map<String, dynamic> json) =>
    _MonthlyPoint(
      month: (json['month'] as num).toInt(),
      expense: (json['expense'] as num).toInt(),
      income: (json['income'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MonthlyPointToJson(_MonthlyPoint instance) =>
    <String, dynamic>{
      'month': instance.month,
      'expense': instance.expense,
      'income': instance.income,
    };

_YearlySummary _$YearlySummaryFromJson(Map<String, dynamic> json) =>
    _YearlySummary(
      year: (json['year'] as num).toInt(),
      totalExpense: (json['total_expense'] as num).toInt(),
      totalIncome: (json['total_income'] as num?)?.toInt() ?? 0,
      billTotal: (json['bill_total'] as num?)?.toInt() ?? 0,
      byCategory: (json['by_category'] as List<dynamic>)
          .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      byMonth: (json['by_month'] as List<dynamic>)
          .map((e) => MonthlyPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$YearlySummaryToJson(_YearlySummary instance) =>
    <String, dynamic>{
      'year': instance.year,
      'total_expense': instance.totalExpense,
      'total_income': instance.totalIncome,
      'bill_total': instance.billTotal,
      'by_category': instance.byCategory.map((e) => e.toJson()).toList(),
      'by_month': instance.byMonth.map((e) => e.toJson()).toList(),
    };

_ReceiptListItem _$ReceiptListItemFromJson(Map<String, dynamic> json) =>
    _ReceiptListItem(
      receiptId: json['receipt_id'] as String,
      storeName: json['store_name'] as String,
      totalAmount: (json['total_amount'] as num).toInt(),
      purchasedAt: json['purchased_at'] as String,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      category: json['category'] as String? ?? 'other',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isTaxExempt: json['is_tax_exempt'] as bool? ?? false,
      memo: json['memo'] as String?,
    );

Map<String, dynamic> _$ReceiptListItemToJson(_ReceiptListItem instance) =>
    <String, dynamic>{
      'receipt_id': instance.receiptId,
      'store_name': instance.storeName,
      'total_amount': instance.totalAmount,
      'purchased_at': instance.purchasedAt,
      'payment_method': instance.paymentMethod,
      'category': instance.category,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'is_tax_exempt': instance.isTaxExempt,
      'memo': instance.memo,
    };

_RecentReceipt _$RecentReceiptFromJson(Map<String, dynamic> json) =>
    _RecentReceipt(
      receiptId: json['receipt_id'] as String,
      storeName: json['store_name'] as String,
      totalAmount: (json['total_amount'] as num).toInt(),
      purchasedAt: json['purchased_at'] as String,
      isBill: json['is_bill'] as bool? ?? false,
      billId: json['bill_id'] as String?,
    );

Map<String, dynamic> _$RecentReceiptToJson(_RecentReceipt instance) =>
    <String, dynamic>{
      'receipt_id': instance.receiptId,
      'store_name': instance.storeName,
      'total_amount': instance.totalAmount,
      'purchased_at': instance.purchasedAt,
      'is_bill': instance.isBill,
      'bill_id': instance.billId,
    };

_MonthlySummary _$MonthlySummaryFromJson(Map<String, dynamic> json) =>
    _MonthlySummary(
      yearMonth: json['year_month'] as String,
      totalExpense: (json['total_expense'] as num).toInt(),
      totalIncome: (json['total_income'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      billTotal: (json['bill_total'] as num?)?.toInt() ?? 0,
      totalSavings: (json['total_savings'] as num?)?.toInt() ?? 0,
      byCategory: (json['by_category'] as List<dynamic>)
          .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentReceipts: (json['recent_receipts'] as List<dynamic>)
          .map((e) => RecentReceipt.fromJson(e as Map<String, dynamic>))
          .toList(),
      allReceipts: (json['all_receipts'] as List<dynamic>)
          .map((e) => RecentReceipt.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MonthlySummaryToJson(
  _MonthlySummary instance,
) => <String, dynamic>{
  'year_month': instance.yearMonth,
  'total_expense': instance.totalExpense,
  'total_income': instance.totalIncome,
  'score': instance.score,
  'bill_total': instance.billTotal,
  'total_savings': instance.totalSavings,
  'by_category': instance.byCategory.map((e) => e.toJson()).toList(),
  'recent_receipts': instance.recentReceipts.map((e) => e.toJson()).toList(),
  'all_receipts': instance.allReceipts.map((e) => e.toJson()).toList(),
};

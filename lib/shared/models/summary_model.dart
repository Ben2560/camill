import 'package:freezed_annotation/freezed_annotation.dart';

import 'receipt_model.dart';

part 'summary_model.freezed.dart';
part 'summary_model.g.dart';

String _dateOnly(String s) => s.substring(0, 10);

@freezed
sealed class DailySummary with _$DailySummary {
  const factory DailySummary({
    @JsonKey(fromJson: _dateOnly) required String date,
    required int expense,
    @Default(0) int income,
  }) = _DailySummary;

  factory DailySummary.fromJson(Map<String, dynamic> json) =>
      _$DailySummaryFromJson(json);
}

@freezed
sealed class CategorySummary with _$CategorySummary {
  const factory CategorySummary({
    required String category,
    required int amount,
  }) = _CategorySummary;

  factory CategorySummary.fromJson(Map<String, dynamic> json) =>
      _$CategorySummaryFromJson(json);
}

@freezed
sealed class WeeklySummary with _$WeeklySummary {
  const factory WeeklySummary({
    required String weekStart,
    required String weekEnd,
    required int totalExpense,
    @Default(0) int totalIncome,
    @Default(0) int billTotal,
    required List<CategorySummary> byCategory,
    required List<DailySummary> byDay,
  }) = _WeeklySummary;

  factory WeeklySummary.fromJson(Map<String, dynamic> json) =>
      _$WeeklySummaryFromJson(json);
}

@freezed
sealed class MonthlyPoint with _$MonthlyPoint {
  const factory MonthlyPoint({
    required int month,
    required int expense,
    @Default(0) int income,
  }) = _MonthlyPoint;

  factory MonthlyPoint.fromJson(Map<String, dynamic> json) =>
      _$MonthlyPointFromJson(json);
}

@freezed
sealed class YearlySummary with _$YearlySummary {
  const factory YearlySummary({
    required int year,
    required int totalExpense,
    @Default(0) int totalIncome,
    @Default(0) int billTotal,
    required List<CategorySummary> byCategory,
    required List<MonthlyPoint> byMonth,
  }) = _YearlySummary;

  factory YearlySummary.fromJson(Map<String, dynamic> json) =>
      _$YearlySummaryFromJson(json);
}

@freezed
sealed class ReceiptListItem with _$ReceiptListItem {
  const factory ReceiptListItem({
    required String receiptId,
    required String storeName,
    required int totalAmount,
    required String purchasedAt,
    @Default('cash') String paymentMethod,
    @Default('other') String category,
    @Default([]) List<ReceiptItem> items,
    @Default(false) bool isTaxExempt,
    String? memo,
  }) = _ReceiptListItem;

  factory ReceiptListItem.fromJson(Map<String, dynamic> json) =>
      _$ReceiptListItemFromJson(json);
}

@freezed
sealed class RecentReceipt with _$RecentReceipt {
  const factory RecentReceipt({
    required String receiptId,
    required String storeName,
    required int totalAmount,
    required String purchasedAt,
    @Default(false) bool isBill,
    String? billId,
  }) = _RecentReceipt;

  factory RecentReceipt.fromJson(Map<String, dynamic> json) =>
      _$RecentReceiptFromJson(json);
}

@freezed
sealed class MonthlySummary with _$MonthlySummary {
  const factory MonthlySummary({
    required String yearMonth,
    required int totalExpense,
    @Default(0) int totalIncome,
    @Default(0) int score,
    @Default(0) int billTotal,
    @Default(0) int totalSavings,
    required List<CategorySummary> byCategory,
    required List<RecentReceipt> recentReceipts,
    required List<RecentReceipt> allReceipts,
  }) = _MonthlySummary;

  factory MonthlySummary.fromJson(Map<String, dynamic> json) =>
      _$MonthlySummaryFromJson(json);
}

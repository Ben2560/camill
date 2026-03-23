import 'receipt_model.dart';

class DailySummary {
  final String date;
  final int expense;
  final int income;

  DailySummary({required this.date, required this.expense, required this.income});

  factory DailySummary.fromJson(Map<String, dynamic> json) => DailySummary(
        date: (json['date'] as String).substring(0, 10),
        expense: (json['expense'] as num).toInt(),
        income: (json['income'] as num? ?? 0).toInt(),
      );
}

class WeeklySummary {
  final String weekStart;
  final String weekEnd;
  final int totalExpense;
  final int totalIncome;
  final List<CategorySummary> byCategory;
  final List<DailySummary> byDay;

  WeeklySummary({
    required this.weekStart,
    required this.weekEnd,
    required this.totalExpense,
    required this.totalIncome,
    required this.byCategory,
    required this.byDay,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) => WeeklySummary(
        weekStart: json['week_start'] as String,
        weekEnd: json['week_end'] as String,
        totalExpense: (json['total_expense'] as num).toInt(),
        totalIncome: (json['total_income'] as num? ?? 0).toInt(),
        byCategory: (json['by_category'] as List<dynamic>)
            .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        byDay: (json['by_day'] as List<dynamic>)
            .map((e) => DailySummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MonthlyPoint {
  final int month;
  final int expense;
  final int income;

  MonthlyPoint({required this.month, required this.expense, required this.income});

  factory MonthlyPoint.fromJson(Map<String, dynamic> json) => MonthlyPoint(
        month: (json['month'] as num).toInt(),
        expense: (json['expense'] as num).toInt(),
        income: (json['income'] as num? ?? 0).toInt(),
      );
}

class YearlySummary {
  final int year;
  final int totalExpense;
  final int totalIncome;
  final List<CategorySummary> byCategory;
  final List<MonthlyPoint> byMonth;

  YearlySummary({
    required this.year,
    required this.totalExpense,
    required this.totalIncome,
    required this.byCategory,
    required this.byMonth,
  });

  factory YearlySummary.fromJson(Map<String, dynamic> json) => YearlySummary(
        year: (json['year'] as num).toInt(),
        totalExpense: (json['total_expense'] as num).toInt(),
        totalIncome: (json['total_income'] as num? ?? 0).toInt(),
        byCategory: (json['by_category'] as List<dynamic>)
            .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        byMonth: (json['by_month'] as List<dynamic>)
            .map((e) => MonthlyPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// レシート一覧画面用モデル
class ReceiptListItem {
  final String receiptId;
  final String storeName;
  final int totalAmount;
  final String purchasedAt;
  final String paymentMethod;
  final String category;
  final List<ReceiptItem> items;

  ReceiptListItem({
    required this.receiptId,
    required this.storeName,
    required this.totalAmount,
    required this.purchasedAt,
    required this.paymentMethod,
    required this.category,
    required this.items,
  });

  factory ReceiptListItem.fromJson(Map<String, dynamic> json) =>
      ReceiptListItem(
        receiptId: json['receipt_id'] as String,
        storeName: json['store_name'] as String,
        totalAmount: (json['total_amount'] as num).toInt(),
        purchasedAt: json['purchased_at'] as String,
        paymentMethod: json['payment_method'] as String? ?? 'cash',
        category: json['category'] as String? ?? 'other',
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class CategorySummary {
  final String category;
  final int amount;

  CategorySummary({required this.category, required this.amount});

  factory CategorySummary.fromJson(Map<String, dynamic> json) =>
      CategorySummary(
        category: json['category'] as String,
        amount: (json['amount'] as num).toInt(),
      );
}

class RecentReceipt {
  final String receiptId;
  final String storeName;
  final int totalAmount;
  final String purchasedAt;

  RecentReceipt({
    required this.receiptId,
    required this.storeName,
    required this.totalAmount,
    required this.purchasedAt,
  });

  factory RecentReceipt.fromJson(Map<String, dynamic> json) => RecentReceipt(
        receiptId: json['receipt_id'] as String,
        storeName: json['store_name'] as String,
        totalAmount: (json['total_amount'] as num).toInt(),
        purchasedAt: json['purchased_at'] as String,
      );
}

class MonthlySummary {
  final String yearMonth;
  final int totalExpense;
  final int totalIncome;
  final List<CategorySummary> byCategory;
  final List<RecentReceipt> recentReceipts;

  MonthlySummary({
    required this.yearMonth,
    required this.totalExpense,
    required this.totalIncome,
    required this.byCategory,
    required this.recentReceipts,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) => MonthlySummary(
        yearMonth: json['year_month'] as String,
        totalExpense: (json['total_expense'] as num).toInt(),
        totalIncome: (json['total_income'] as num? ?? 0).toInt(),
        byCategory: (json['by_category'] as List<dynamic>)
            .map((e) => CategorySummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentReceipts: (json['recent_receipts'] as List<dynamic>)
            .map((e) => RecentReceipt.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:camill/shared/models/summary_model.dart';

void main() {
  group('DailySummary.fromJson', () {
    test('date を YYYY-MM-DD に切り詰める', () {
      final s = DailySummary.fromJson({
        'date': '2026-04-21T00:00:00',
        'expense': 1000,
        'income': 500,
      });
      expect(s.date, '2026-04-21');
      expect(s.expense, 1000);
      expect(s.income, 500);
    });

    test('income が省略されるとき 0', () {
      final s = DailySummary.fromJson({'date': '2026-04-21', 'expense': 200});
      expect(s.income, 0);
    });
  });

  group('CategorySummary.fromJson', () {
    test('category と amount をパースする', () {
      final cs = CategorySummary.fromJson({'category': 'food', 'amount': 3000});
      expect(cs.category, 'food');
      expect(cs.amount, 3000);
    });
  });

  group('WeeklySummary.fromJson', () {
    test('ネストされたリストをパースする', () {
      final ws = WeeklySummary.fromJson({
        'week_start': '2026-04-14',
        'week_end': '2026-04-20',
        'total_expense': 20000,
        'by_category': [
          {'category': 'food', 'amount': 8000},
        ],
        'by_day': [
          {'date': '2026-04-14', 'expense': 1000},
        ],
      });
      expect(ws.totalExpense, 20000);
      expect(ws.totalIncome, 0);
      expect(ws.billTotal, 0);
      expect(ws.byCategory.length, 1);
      expect(ws.byDay.first.date, '2026-04-14');
    });
  });

  group('MonthlyPoint.fromJson', () {
    test('月次データをパースする', () {
      final mp = MonthlyPoint.fromJson({'month': 4, 'expense': 50000, 'income': 0});
      expect(mp.month, 4);
      expect(mp.expense, 50000);
    });
  });

  group('YearlySummary.fromJson', () {
    test('ネストされたリストをパースする', () {
      final ys = YearlySummary.fromJson({
        'year': 2026,
        'total_expense': 600000,
        'by_category': [],
        'by_month': [
          {'month': 1, 'expense': 50000},
        ],
      });
      expect(ys.year, 2026);
      expect(ys.byMonth.length, 1);
    });
  });

  group('ReceiptListItem.fromJson', () {
    test('必須フィールドをパースする', () {
      final item = ReceiptListItem.fromJson({
        'receipt_id': 'r1',
        'store_name': 'コンビニ',
        'total_amount': 500,
        'purchased_at': '2026-04-21T10:00:00',
      });
      expect(item.receiptId, 'r1');
      expect(item.category, 'other');
      expect(item.paymentMethod, 'cash');
      expect(item.items, isEmpty);
      expect(item.isTaxExempt, false);
    });
  });

  group('RecentReceipt.fromJson', () {
    test('基本フィールドをパースする', () {
      final r = RecentReceipt.fromJson({
        'receipt_id': 'r2',
        'store_name': 'スーパー',
        'total_amount': 1200,
        'purchased_at': '2026-04-21T12:00:00',
      });
      expect(r.receiptId, 'r2');
      expect(r.isBill, false);
      expect(r.billId, isNull);
    });
  });

  group('MonthlySummary.fromJson', () {
    test('月次サマリー全体をパースする', () {
      final ms = MonthlySummary.fromJson({
        'year_month': '2026-04',
        'total_expense': 80000,
        'total_income': 0,
        'score': 72,
        'by_category': [
          {'category': 'food', 'amount': 30000},
        ],
        'recent_receipts': [],
        'all_receipts': [],
      });
      expect(ms.yearMonth, '2026-04');
      expect(ms.totalExpense, 80000);
      expect(ms.score, 72);
      expect(ms.byCategory.first.category, 'food');
      expect(ms.totalSavings, 0);
    });
  });

  group('Freezed copyWith', () {
    test('CategorySummary copyWith', () {
      const cs = CategorySummary(category: 'food', amount: 1000);
      final updated = cs.copyWith(amount: 2000);
      expect(updated.amount, 2000);
      expect(updated.category, 'food');
    });

    test('MonthlySummary copyWith', () {
      final ms = MonthlySummary(
        yearMonth: '2026-04',
        totalExpense: 50000,
        byCategory: const [],
        recentReceipts: const [],
        allReceipts: const [],
      );
      final updated = ms.copyWith(totalExpense: 60000);
      expect(updated.totalExpense, 60000);
      expect(updated.yearMonth, '2026-04');
    });
  });
}

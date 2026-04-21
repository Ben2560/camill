import 'package:flutter_test/flutter_test.dart';
import 'package:camill/shared/models/fixed_expense_model.dart';

void main() {
  group('FixedExpenseSetting.fromJson', () {
    test('Map フォーマットをパースする', () {
      final s = FixedExpenseSetting.fromEntry('housing', {
        'billing_day': 27,
        'holiday_rule': 'before',
      });
      expect(s.category, 'housing');
      expect(s.billingDay, 27);
      expect(s.holidayRule, 'before');
    });

    test('旧フォーマット（int のみ）との互換', () {
      final s = FixedExpenseSetting.fromEntry('utilities', 15);
      expect(s.category, 'utilities');
      expect(s.billingDay, 15);
      expect(s.holidayRule, isNull);
    });

    test('billingDay が null のとき未設定', () {
      final s = FixedExpenseSetting.fromEntry('other', <String, dynamic>{});
      expect(s.billingDayLabel, '未設定');
    });

    test('billingDay が 32 のとき末日', () {
      final s = FixedExpenseSetting.fromEntry('rent', {'billing_day': 32});
      expect(s.billingDayLabel, '末日');
    });

    test('billingDay が通常値のとき N日', () {
      final s = FixedExpenseSetting.fromEntry('rent', {'billing_day': 10});
      expect(s.billingDayLabel, '10日');
    });

    test('holidayRuleLabel: before → 前営業日', () {
      final s = FixedExpenseSetting.fromEntry('x', {'holiday_rule': 'before'});
      expect(s.holidayRuleLabel, '前営業日');
    });

    test('holidayRuleLabel: after → 翌営業日', () {
      final s = FixedExpenseSetting.fromEntry('x', {'holiday_rule': 'after'});
      expect(s.holidayRuleLabel, '翌営業日');
    });

    test('holidayRuleLabel: null → null', () {
      final s = FixedExpenseSetting.fromEntry('x', <String, dynamic>{});
      expect(s.holidayRuleLabel, isNull);
    });
  });

  group('FixedPayment.fromJson', () {
    test('全フィールドをパースする', () {
      final p = FixedPayment.fromEntry('housing', '2026-04', {
        'paid_at': '2026-04-27T00:00:00.000',
        'confirmed_by': 'auto',
        'amount': 80000,
      });
      expect(p.category, 'housing');
      expect(p.yearMonth, '2026-04');
      expect(p.confirmedBy, 'auto');
      expect(p.amount, 80000);
    });

    test('confirmedByLabel: auto → 自動確認', () {
      final p = FixedPayment.fromEntry('x', '2026-04', {
        'paid_at': '2026-04-01T00:00:00',
        'confirmed_by': 'auto',
      });
      expect(p.confirmedByLabel, '自動確認');
    });

    test('confirmedByLabel: ocr → 明細確認', () {
      final p = FixedPayment.fromEntry('x', '2026-04', {
        'paid_at': '2026-04-01T00:00:00',
        'confirmed_by': 'ocr',
      });
      expect(p.confirmedByLabel, '明細確認');
    });

    test('confirmedByLabel: manual → 手動確認', () {
      final p = FixedPayment.fromEntry('x', '2026-04', {
        'paid_at': '2026-04-01T00:00:00',
        'confirmed_by': 'manual',
      });
      expect(p.confirmedByLabel, '手動確認');
    });
  });

  group('BankTransaction.fromJson', () {
    test('全フィールドをパースする', () {
      final t = BankTransaction.fromJson({
        'date': '2026-04-21',
        'description': 'セブン銀行ATM',
        'amount': -5000,
        'matched_category': 'other',
      });
      expect(t.date, '2026-04-21');
      expect(t.description, 'セブン銀行ATM');
      expect(t.amount, -5000);
      expect(t.matchedCategory, 'other');
    });

    test('matchedCategory が省略されるとき null', () {
      final t = BankTransaction.fromJson({
        'date': '2026-04-21',
        'description': 'test',
        'amount': 1000,
      });
      expect(t.matchedCategory, isNull);
    });
  });
}

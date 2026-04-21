import 'package:flutter_test/flutter_test.dart';
import 'package:camill/shared/models/bill_model.dart';

void main() {
  final now = DateTime.now();

  Bill makeBill({
    BillStatus status = BillStatus.unpaid,
    DateTime? dueDate,
    String? memo,
  }) =>
      Bill(
        billId: 'b1',
        title: '電気代',
        amount: 8000,
        status: status,
        createdAt: now,
        dueDate: dueDate,
        memo: memo,
      );

  group('Bill.fromJson', () {
    test('必須フィールドを正しくパースする', () {
      final json = {
        'bill_id': 'bill-001',
        'title': '水道代',
        'amount': 5000,
        'status': 'unpaid',
        'created_at': now.toIso8601String(),
      };
      final bill = Bill.fromJson(json);
      expect(bill.billId, 'bill-001');
      expect(bill.title, '水道代');
      expect(bill.amount, 5000);
      expect(bill.status, BillStatus.unpaid);
      expect(bill.isTaxExempt, false);
    });

    test('status を正しくパースする', () {
      for (final entry in {
        'unpaid': BillStatus.unpaid,
        'pending': BillStatus.pending,
        'paid': BillStatus.paid,
      }.entries) {
        final bill = Bill.fromJson({
          'bill_id': 'x',
          'title': 't',
          'amount': 100,
          'status': entry.key,
          'created_at': now.toIso8601String(),
        });
        expect(bill.status, entry.value, reason: 'status=${entry.key}');
      }
    });

    test('オプションフィールドがデフォルト値になる', () {
      final json = {
        'bill_id': 'x',
        'title': 't',
        'amount': 100,
        'status': 'paid',
        'created_at': now.toIso8601String(),
      };
      final bill = Bill.fromJson(json);
      expect(bill.dueDate, isNull);
      expect(bill.category, isNull);
      expect(bill.paidAt, isNull);
      expect(bill.memo, isNull);
    });
  });

  group('daysUntilDue', () {
    test('dueDate が null のとき null を返す', () {
      expect(makeBill().daysUntilDue, isNull);
    });

    test('明日以降が期限のとき正の値を返す', () {
      final bill = makeBill(dueDate: DateTime.now().add(const Duration(hours: 36)));
      expect(bill.daysUntilDue! >= 1, isTrue);
    });

    test('昨日が期限のとき負の値を返す', () {
      final bill = makeBill(dueDate: DateTime.now().subtract(const Duration(days: 1)));
      expect(bill.daysUntilDue! < 0, isTrue);
    });
  });

  group('isUrgent', () {
    test('dueDate が null のとき false', () {
      expect(makeBill().isUrgent, isFalse);
    });

    test('3日以内の期限は true', () {
      final bill = makeBill(dueDate: DateTime.now().add(const Duration(days: 2)));
      expect(bill.isUrgent, isTrue);
    });

    test('10日後の期限は false', () {
      final bill = makeBill(dueDate: DateTime.now().add(const Duration(days: 10)));
      expect(bill.isUrgent, isFalse);
    });

    test('期限切れ（昨日）は false', () {
      final bill = makeBill(dueDate: DateTime.now().subtract(const Duration(days: 1)));
      expect(bill.isUrgent, isFalse);
    });
  });

  group('copyWith', () {
    test('指定フィールドだけ変更される', () {
      final original = makeBill(status: BillStatus.unpaid);
      final updated = original.copyWith(status: BillStatus.paid);
      expect(updated.status, BillStatus.paid);
      expect(updated.billId, original.billId);
      expect(updated.amount, original.amount);
    });

    test('nullable フィールドを null に設定できる', () {
      final bill = makeBill(memo: '元のメモ');
      final updated = bill.copyWith(memo: null);
      expect(updated.memo, isNull);
    });
  });

  group('Freezed equality', () {
    test('同じ値のインスタンスは等価', () {
      final a = makeBill();
      final b = makeBill();
      expect(a, equals(b));
    });

    test('異なる値は非等価', () {
      expect(makeBill(status: BillStatus.unpaid), isNot(equals(makeBill(status: BillStatus.paid))));
    });
  });
}

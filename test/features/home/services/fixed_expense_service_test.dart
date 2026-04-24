import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:camill/features/home/services/fixed_expense_service.dart';
import 'package:camill/shared/models/fixed_expense_model.dart';
import 'package:camill/shared/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApi;
  late FixedExpenseService service;

  setUp(() {
    mockApi = MockApiService();
    service = FixedExpenseService(api: mockApi);
  });

  // ─────────────────────────────────────────
  // getSettings
  // ─────────────────────────────────────────
  group('getSettings', () {
    test('Map<category, FixedExpenseSetting> を返す', () async {
      when(() => mockApi.get('/fixed-expenses/settings')).thenAnswer(
        (_) async => {
          'food': {'billing_day': 27, 'holiday_rule': 'before'},
          'utility': {'billing_day': 5, 'holiday_rule': null},
        },
      );

      final result = await service.getSettings();
      expect(result.length, 2);
      expect(result['food']?.billingDay, 27);
      expect(result['food']?.holidayRule, 'before');
      expect(result['utility']?.billingDay, 5);
      expect(result['utility']?.holidayRule, isNull);
    });

    test('整数値（旧形式）でも FixedExpenseSetting を生成できる', () async {
      when(() => mockApi.get('/fixed-expenses/settings'))
          .thenAnswer((_) async => {'housing': 25});

      final result = await service.getSettings();
      expect(result['housing']?.billingDay, 25);
      expect(result['housing']?.holidayRule, isNull);
    });

    test('空マップが返ると空の Map を返す', () async {
      when(() => mockApi.get('/fixed-expenses/settings'))
          .thenAnswer((_) async => <String, dynamic>{});

      final result = await service.getSettings();
      expect(result, isEmpty);
    });
  });

  // ─────────────────────────────────────────
  // updateBillingDay
  // ─────────────────────────────────────────
  group('updateBillingDay', () {
    test('billingDay と holidayRule が正しいパスで送信される', () async {
      when(
        () => mockApi.patch(
          '/fixed-expenses/settings/food',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{});

      await service.updateBillingDay(
        'food',
        billingDay: 27,
        holidayRule: 'before',
      );

      final captured = verify(
        () => mockApi.patch(
          '/fixed-expenses/settings/food',
          body: captureAny(named: 'body'),
        ),
      ).captured;
      final body = captured.first as Map<String, dynamic>;
      expect(body['billing_day'], 27);
      expect(body['holiday_rule'], 'before');
    });

    test('billingDay=null で削除リクエストが送信される', () async {
      when(
        () => mockApi.patch(
          '/fixed-expenses/settings/food',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{});

      await service.updateBillingDay('food', billingDay: null);

      final captured = verify(
        () => mockApi.patch(
          '/fixed-expenses/settings/food',
          body: captureAny(named: 'body'),
        ),
      ).captured;
      expect((captured.first as Map)['billing_day'], isNull);
    });
  });

  // ─────────────────────────────────────────
  // getPayments
  // ─────────────────────────────────────────
  group('getPayments', () {
    test('Map<category, FixedPayment> を返す', () async {
      when(() => mockApi.get('/fixed-expenses/payments/2026-04')).thenAnswer(
        (_) async => {
          'food': {
            'paid_at': '2026-04-27T00:00:00',
            'confirmed_by': 'auto',
            'amount': 30000,
          },
        },
      );

      final result = await service.getPayments('2026-04');
      expect(result.length, 1);
      expect(result['food']?.confirmedBy, 'auto');
      expect(result['food']?.amount, 30000);
      expect(result['food']?.yearMonth, '2026-04');
    });

    test('空マップが返ると空の Map を返す', () async {
      when(() => mockApi.get('/fixed-expenses/payments/2026-04'))
          .thenAnswer((_) async => <String, dynamic>{});

      final result = await service.getPayments('2026-04');
      expect(result, isEmpty);
    });
  });

  // ─────────────────────────────────────────
  // markPaid / unmarkPaid
  // ─────────────────────────────────────────
  group('markPaid', () {
    test('正しいパスで POST が呼ばれる', () async {
      when(
        () => mockApi.post(
          '/fixed-expenses/payments/2026-04/food',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{});

      await service.markPaid('2026-04', 'food');
      verify(
        () => mockApi.post(
          '/fixed-expenses/payments/2026-04/food',
          body: {},
        ),
      ).called(1);
    });
  });

  group('unmarkPaid', () {
    test('正しいパスで DELETE が呼ばれる', () async {
      when(
        () => mockApi.delete('/fixed-expenses/payments/2026-04/food'),
      ).thenAnswer((_) async {});

      await service.unmarkPaid('2026-04', 'food');
      verify(
        () => mockApi.delete('/fixed-expenses/payments/2026-04/food'),
      ).called(1);
    });
  });

  // ─────────────────────────────────────────
  // scanBankStatement
  // ─────────────────────────────────────────
  group('scanBankStatement', () {
    test('BankTransaction リストを返す', () async {
      when(
        () => mockApi.post(
          '/fixed-expenses/scan',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => {
            'transactions': [
              {
                'date': '2026-04-27',
                'description': 'イオン引き落とし',
                'amount': 3500,
                'matched_category': 'food',
              },
              {
                'date': '2026-04-28',
                'description': '電気代',
                'amount': 8200,
                'matched_category': null,
              },
            ],
          });

      final result = await service.scanBankStatement('base64data');
      expect(result.length, 2);
      expect(result.first.description, 'イオン引き落とし');
      expect(result.first.amount, 3500);
      expect(result.first.matchedCategory, 'food');
      expect(result[1].matchedCategory, isNull);
    });

    test('transactions が空リストなら空を返す', () async {
      when(
        () => mockApi.post('/fixed-expenses/scan', body: any(named: 'body')),
      ).thenAnswer((_) async => {'transactions': []});

      final result = await service.scanBankStatement('img');
      expect(result, isEmpty);
    });

    test('transactions キーがない場合も空リストを返す', () async {
      when(
        () => mockApi.post('/fixed-expenses/scan', body: any(named: 'body')),
      ).thenAnswer((_) async => <String, dynamic>{});

      final result = await service.scanBankStatement('img');
      expect(result, isEmpty);
    });

    test('imageBase64 がボディに含まれる', () async {
      when(
        () => mockApi.post('/fixed-expenses/scan', body: any(named: 'body')),
      ).thenAnswer((_) async => {'transactions': []});

      await service.scanBankStatement('mybase64');

      final captured = verify(
        () => mockApi.post(
          '/fixed-expenses/scan',
          body: captureAny(named: 'body'),
        ),
      ).captured;
      expect((captured.first as Map)['image'], 'mybase64');
    });
  });

  // ─────────────────────────────────────────
  // FixedExpenseSetting ラベル
  // ─────────────────────────────────────────
  group('FixedExpenseSetting labels', () {
    test('billingDayLabel: null → 未設定', () {
      const s = FixedExpenseSetting(category: 'food', billingDay: null);
      expect(s.billingDayLabel, '未設定');
    });

    test('billingDayLabel: 32 → 末日', () {
      const s = FixedExpenseSetting(category: 'food', billingDay: 32);
      expect(s.billingDayLabel, '末日');
    });

    test('billingDayLabel: 15 → 15日', () {
      const s = FixedExpenseSetting(category: 'food', billingDay: 15);
      expect(s.billingDayLabel, '15日');
    });

    test('holidayRuleLabel: before → 前営業日', () {
      const s = FixedExpenseSetting(
        category: 'food',
        billingDay: 27,
        holidayRule: 'before',
      );
      expect(s.holidayRuleLabel, '前営業日');
    });

    test('holidayRuleLabel: after → 翌営業日', () {
      const s = FixedExpenseSetting(
        category: 'food',
        billingDay: 27,
        holidayRule: 'after',
      );
      expect(s.holidayRuleLabel, '翌営業日');
    });

    test('holidayRuleLabel: null → null', () {
      const s = FixedExpenseSetting(category: 'food', billingDay: 27);
      expect(s.holidayRuleLabel, isNull);
    });
  });

  // ─────────────────────────────────────────
  // FixedPayment ラベル
  // ─────────────────────────────────────────
  group('FixedPayment labels', () {
    final base = FixedPayment(
      category: 'food',
      yearMonth: '2026-04',
      paidAt: DateTime(2026, 4, 27),
      confirmedBy: 'auto',
    );

    test('confirmedByLabel: auto → 自動確認', () {
      expect(base.confirmedByLabel, '自動確認');
    });

    test('confirmedByLabel: ocr → 明細確認', () {
      expect(
        base.copyWith(confirmedBy: 'ocr').confirmedByLabel,
        '明細確認',
      );
    });

    test('confirmedByLabel: manual → 手動確認', () {
      expect(
        base.copyWith(confirmedBy: 'manual').confirmedByLabel,
        '手動確認',
      );
    });
  });
}

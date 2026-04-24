import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:camill/features/bill/services/bill_service.dart';
import 'package:camill/shared/models/bill_model.dart';
import 'package:camill/shared/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApi;
  late BillService service;

  setUp(() {
    mockApi = MockApiService();
    service = BillService(api: mockApi);
  });

  final billJson = <String, dynamic>{
    'bill_id': 'b1',
    'title': '電気代',
    'amount': 5000,
    'due_date': null,
    'status': 'unpaid',
    'created_at': '2026-04-01T00:00:00',
    'category': 'utility',
    'is_tax_exempt': false,
    'paid_at': null,
    'memo': null,
  };

  group('fetchBills', () {
    test('未払いリストを返す', () async {
      when(
        () => mockApi.getAny('/bills', query: any(named: 'query')),
      ).thenAnswer((_) async => [billJson]);

      final bills = await service.fetchBills();
      expect(bills.length, 1);
      expect(bills.first.title, '電気代');
      expect(bills.first.status, BillStatus.unpaid);
    });

    test('status フィルター付きで getAny が呼ばれる', () async {
      when(
        () => mockApi.getAny('/bills', query: any(named: 'query')),
      ).thenAnswer((_) async => []);

      await service.fetchBills(status: 'paid');
      final captured = verify(
        () => mockApi.getAny('/bills', query: captureAny(named: 'query')),
      ).captured;
      expect((captured.first as Map)['status'], 'paid');
    });

    test('API が null を返すとき空リストを返す', () async {
      when(
        () => mockApi.getAny('/bills', query: any(named: 'query')),
      ).thenAnswer((_) async => null);

      final bills = await service.fetchBills();
      expect(bills, isEmpty);
    });
  });

  group('createBill', () {
    test('新しい Bill を返す', () async {
      when(
        () => mockApi.postAny('/bills', body: any(named: 'body')),
      ).thenAnswer((_) async => billJson);

      final bill = await service.createBill(title: '電気代', amount: 5000);
      expect(bill.billId, 'b1');
      expect(bill.amount, 5000);
    });
  });

  group('updateMemo', () {
    test('patch が billId パスで呼ばれる', () async {
      when(
        () => mockApi.patch('/bills/b1', body: any(named: 'body')),
      ).thenAnswer((_) async => <String, dynamic>{});

      await service.updateMemo('b1', 'テストメモ');
      verify(
        () => mockApi.patch('/bills/b1', body: {'memo': 'テストメモ'}),
      ).called(1);
    });
  });

  group('payBill', () {
    test('patch が /bills/b1/pay で呼ばれる', () async {
      when(
        () => mockApi.patch('/bills/b1/pay', body: any(named: 'body')),
      ).thenAnswer((_) async => <String, dynamic>{});

      await service.payBill('b1');
      verify(() => mockApi.patch('/bills/b1/pay', body: {})).called(1);
    });
  });

  group('deleteBill', () {
    test('delete が正しいパスで呼ばれる', () async {
      when(() => mockApi.delete('/bills/b1')).thenAnswer((_) async {});

      await service.deleteBill('b1');
      verify(() => mockApi.delete('/bills/b1')).called(1);
    });
  });

  group('analyzeBill', () {
    test('post が /bills/analyze で呼ばれ結果を返す', () async {
      final result = <String, dynamic>{'title': '電気代', 'amount': 5000};
      when(
        () => mockApi.post('/bills/analyze', body: any(named: 'body')),
      ).thenAnswer((_) async => result);

      final response = await service.analyzeBill('base64str', 'receipt');
      expect(response['title'], '電気代');
      verify(
        () => mockApi.post(
          '/bills/analyze',
          body: {'image_base64': 'base64str', 'image_type': 'receipt'},
        ),
      ).called(1);
    });
  });
}

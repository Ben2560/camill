import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:camill/features/receipt/services/receipt_service.dart';
import 'package:camill/shared/models/receipt_model.dart';
import 'package:camill/shared/services/api_service.dart';
import 'package:camill/shared/services/overseas_service.dart';

class MockApiService extends Mock implements ApiService {}

class MockOverseasService extends Mock implements OverseasService {}

void main() {
  late MockApiService mockApi;
  late ReceiptService service;

  final receiptJson = <String, dynamic>{
    'receipt_id': 'r1',
    'store_name': 'イオン',
    'total_amount': 3000,
    'purchased_at': '2026-04-01T10:00:00',
    'payment_method': 'credit',
    'items': [],
    'discounts': [],
    'memo': null,
    'savings_amount': 0,
  };

  final analysisJson = <String, dynamic>{
    'store_name': 'セブン',
    'purchased_at': '2026-04-01T10:00:00',
    'total_amount': 500,
    'items': [],
    'coupons_detected': [],
  };

  setUp(() {
    mockApi = MockApiService();
    service = ReceiptService(api: mockApi);
  });

  // ─────────────────────────────────────────
  // saveReceipt
  // ─────────────────────────────────────────
  group('saveReceipt', () {
    test('receipt_id を返す', () async {
      when(
        () => mockApi.post('/receipts', body: any(named: 'body')),
      ).thenAnswer((_) async => {'receipt_id': 'r1'});

      const analysis = ReceiptAnalysis(
        storeName: 'セブン',
        purchasedAt: '2026-04-01T10:00:00',
        totalAmount: 500,
        items: [],
        couponsDetected: [],
      );

      final id = await service.saveReceipt(analysis);
      expect(id, 'r1');
    });

    test('analysis.toJson() がボディに渡される', () async {
      when(
        () => mockApi.post('/receipts', body: any(named: 'body')),
      ).thenAnswer((_) async => {'receipt_id': 'r2'});

      const analysis = ReceiptAnalysis(
        storeName: 'ファミマ',
        purchasedAt: '2026-04-02T09:00:00',
        totalAmount: 800,
        items: [],
        couponsDetected: [],
      );

      await service.saveReceipt(analysis);

      final captured = verify(
        () => mockApi.post('/receipts', body: captureAny(named: 'body')),
      ).captured;
      final body = captured.first as Map<String, dynamic>;
      expect(body['store_name'], 'ファミマ');
      expect(body['total_amount'], 800);
    });
  });

  // ─────────────────────────────────────────
  // overwriteReceipt
  // ─────────────────────────────────────────
  group('overwriteReceipt', () {
    test('既存 ID を DELETE してから POST する', () async {
      when(() => mockApi.delete('/receipts/old1')).thenAnswer((_) async {});
      when(
        () => mockApi.post('/receipts', body: any(named: 'body')),
      ).thenAnswer((_) async => {'receipt_id': 'new1'});

      const analysis = ReceiptAnalysis(
        storeName: 'ローソン',
        purchasedAt: '2026-04-01T10:00:00',
        totalAmount: 400,
        items: [],
        couponsDetected: [],
      );

      final newId = await service.overwriteReceipt('old1', analysis);
      expect(newId, 'new1');
      verify(() => mockApi.delete('/receipts/old1')).called(1);
    });

    test('POST ボディの duplicate_check_hash が空文字になる', () async {
      when(() => mockApi.delete(any())).thenAnswer((_) async {});
      when(
        () => mockApi.post('/receipts', body: any(named: 'body')),
      ).thenAnswer((_) async => {'receipt_id': 'x'});

      const analysis = ReceiptAnalysis(
        storeName: 'テスト',
        purchasedAt: '2026-04-01T10:00:00',
        totalAmount: 100,
        items: [],
        couponsDetected: [],
        duplicateCheckHash: 'original_hash',
      );

      await service.overwriteReceipt('old', analysis);

      final captured = verify(
        () => mockApi.post('/receipts', body: captureAny(named: 'body')),
      ).captured;
      expect((captured.first as Map)['duplicate_check_hash'], '');
    });
  });

  // ─────────────────────────────────────────
  // getReceipts
  // ─────────────────────────────────────────
  group('getReceipts', () {
    test('Receipt リストを返す', () async {
      when(
        () => mockApi.get('/receipts', query: any(named: 'query')),
      ).thenAnswer((_) async => {'receipts': [receiptJson]});

      final receipts = await service.getReceipts('2026-04');
      expect(receipts.length, 1);
      expect(receipts.first.storeName, 'イオン');
      expect(receipts.first.totalAmount, 3000);
    });

    test('year_month クエリが渡される', () async {
      when(
        () => mockApi.get('/receipts', query: any(named: 'query')),
      ).thenAnswer((_) async => {'receipts': []});

      await service.getReceipts('2026-04');

      final captured = verify(
        () => mockApi.get('/receipts', query: captureAny(named: 'query')),
      ).captured;
      expect((captured.first as Map)['year_month'], '2026-04');
    });

    test('receipts キーが null の場合は空リストを返す', () async {
      when(
        () => mockApi.get('/receipts', query: any(named: 'query')),
      ).thenAnswer((_) async => {'receipts': null});

      final receipts = await service.getReceipts('2026-04');
      expect(receipts, isEmpty);
    });
  });

  // ─────────────────────────────────────────
  // getReceiptDetail
  // ─────────────────────────────────────────
  group('getReceiptDetail', () {
    test('Receipt を返す', () async {
      when(() => mockApi.get('/receipts/r1')).thenAnswer((_) async => receiptJson);

      final receipt = await service.getReceiptDetail('r1');
      expect(receipt.receiptId, 'r1');
      expect(receipt.paymentMethod, 'credit');
    });
  });

  // ─────────────────────────────────────────
  // deleteReceipt
  // ─────────────────────────────────────────
  group('deleteReceipt', () {
    test('正しいパスで DELETE が呼ばれる', () async {
      when(() => mockApi.delete('/receipts/r1')).thenAnswer((_) async {});

      await service.deleteReceipt('r1');
      verify(() => mockApi.delete('/receipts/r1')).called(1);
    });
  });

  // ─────────────────────────────────────────
  // updateMemo
  // ─────────────────────────────────────────
  group('updateMemo', () {
    test('メモが PATCH ボディに含まれる', () async {
      when(
        () => mockApi.patch('/receipts/r1', body: any(named: 'body')),
      ).thenAnswer((_) async => <String, dynamic>{});

      await service.updateMemo('r1', '買いすぎ注意');

      final captured = verify(
        () => mockApi.patch('/receipts/r1', body: captureAny(named: 'body')),
      ).captured;
      expect((captured.first as Map)['memo'], '買いすぎ注意');
    });

    test('空文字のメモは null として送信される', () async {
      when(
        () => mockApi.patch('/receipts/r1', body: any(named: 'body')),
      ).thenAnswer((_) async => <String, dynamic>{});

      await service.updateMemo('r1', '');

      final captured = verify(
        () => mockApi.patch('/receipts/r1', body: captureAny(named: 'body')),
      ).captured;
      expect((captured.first as Map)['memo'], isNull);
    });
  });

  // ─────────────────────────────────────────
  // getActiveMonths
  // ─────────────────────────────────────────
  group('getActiveMonths', () {
    test('月リストを返す', () async {
      when(() => mockApi.getAny('/receipts/active-months')).thenAnswer(
        (_) async => {
          'months': ['2026-01', '2026-02', '2026-03'],
        },
      );

      final months = await service.getActiveMonths();
      expect(months, ['2026-01', '2026-02', '2026-03']);
    });

    test('months キーが null なら空リストを返す', () async {
      when(() => mockApi.getAny('/receipts/active-months'))
          .thenAnswer((_) async => {'months': null});

      final months = await service.getActiveMonths();
      expect(months, isEmpty);
    });
  });

  // ─────────────────────────────────────────
  // mergeReceiptsAndCoupons
  // ─────────────────────────────────────────
  group('mergeReceiptsAndCoupons', () {
    const base = ReceiptAnalysis(
      storeName: 'イオン',
      purchasedAt: '2026-04-01T10:00:00',
      totalAmount: 1000,
      items: [],
      couponsDetected: [],
    );

    test('1件のみのときそのまま返す', () {
      final result = service.mergeReceiptsAndCoupons([base]);
      expect(result.length, 1);
      expect(result.first.storeName, 'イオン');
    });

    test('空リストを渡すと空リストを返す', () {
      expect(service.mergeReceiptsAndCoupons([]), isEmpty);
    });

    test('異なる店舗は別々に返す', () {
      const other = ReceiptAnalysis(
        storeName: 'セブン',
        purchasedAt: '2026-04-01T10:00:00',
        totalAmount: 500,
        items: [],
        couponsDetected: [],
      );
      final result = service.mergeReceiptsAndCoupons([base, other]);
      expect(result.length, 2);
    });

    test('同一店舗・同一日時はマージされる', () {
      const coupon1 = CouponDetected(
        description: 'クーポンA',
        discountAmount: 100,
      );
      const coupon2 = CouponDetected(
        description: 'クーポンB',
        discountAmount: 200,
      );
      const r1 = ReceiptAnalysis(
        storeName: 'イオン',
        purchasedAt: '2026-04-01T10:00:00',
        totalAmount: 1000,
        items: [],
        couponsDetected: [coupon1],
      );
      const r2 = ReceiptAnalysis(
        storeName: 'イオン',
        purchasedAt: '2026-04-01T10:00:00',
        totalAmount: 1000,
        items: [],
        couponsDetected: [coupon2],
      );
      final result = service.mergeReceiptsAndCoupons([r1, r2]);
      expect(result.length, 1);
      expect(result.first.couponsDetected.length, 2);
    });

    test('items 数が多い方がベースになる', () {
      const item = ReceiptItem(
        itemName: '商品',
        unitPrice: 100,
        quantity: 1,
        amount: 100,
      );
      const r1 = ReceiptAnalysis(
        storeName: 'イオン',
        purchasedAt: '2026-04-01T10:00:00',
        totalAmount: 1000,
        items: [item, item],
        couponsDetected: [],
      );
      const r2 = ReceiptAnalysis(
        storeName: 'イオン',
        purchasedAt: '2026-04-01T10:00:00',
        totalAmount: 999,
        items: [item],
        couponsDetected: [],
      );
      final result = service.mergeReceiptsAndCoupons([r2, r1]);
      expect(result.first.totalAmount, 1000);
    });

    test('linePromotions が両方から結合される', () {
      const promo1 = LinePromotion(description: 'プロモA');
      const promo2 = LinePromotion(description: 'プロモB');
      const r1 = ReceiptAnalysis(
        storeName: 'イオン',
        purchasedAt: '2026-04-01T10:00:00',
        totalAmount: 1000,
        items: [],
        couponsDetected: [],
        linePromotions: [promo1],
      );
      const r2 = ReceiptAnalysis(
        storeName: 'イオン',
        purchasedAt: '2026-04-01T10:00:00',
        totalAmount: 1000,
        items: [],
        couponsDetected: [],
        linePromotions: [promo2],
      );
      final result = service.mergeReceiptsAndCoupons([r1, r2]);
      expect(result.first.linePromotions.length, 2);
    });

    test('店舗名の大文字小文字・前後スペースは正規化される', () {
      const r1 = ReceiptAnalysis(
        storeName: ' AEON ',
        purchasedAt: '2026-04-01T10:00:00',
        totalAmount: 1000,
        items: [],
        couponsDetected: [],
      );
      const r2 = ReceiptAnalysis(
        storeName: 'aeon',
        purchasedAt: '2026-04-01T10:00:00',
        totalAmount: 1000,
        items: [],
        couponsDetected: [],
      );
      final result = service.mergeReceiptsAndCoupons([r1, r2]);
      expect(result.length, 1);
    });
  });

  // ─────────────────────────────────────────
  // mergeKey
  // ─────────────────────────────────────────
  group('mergeKey', () {
    test('有効な ISO 日時を含むキーを返す', () {
      final key = service.mergeKey('イオン', '2026-04-01T10:30:00');
      expect(key, 'イオン|2026-04-01 10:30');
    });

    test('店舗名は lowercase・trim 正規化される', () {
      final key = service.mergeKey(' AEON ', '2026-04-01T09:00:00');
      expect(key, 'aeon|2026-04-01 09:00');
    });

    test('日時がパース不能のとき店舗名のみ返す', () {
      final key = service.mergeKey('セブン', 'invalid-date');
      expect(key, 'セブン');
    });

    test('同一店舗・同一分は同じキーになる', () {
      final k1 = service.mergeKey('ファミマ', '2026-04-01T15:00:00');
      final k2 = service.mergeKey('ファミマ', '2026-04-01T15:00:30');
      expect(k1, k2);
    });
  });

  // ─────────────────────────────────────────
  // OverseasService DI
  // ─────────────────────────────────────────
  group('OverseasService injection', () {
    test('overseasService を注入できる', () {
      final mockOverseas = MockOverseasService();
      final injected = ReceiptService(api: mockApi, overseasService: mockOverseas);
      expect(injected, isNotNull);
    });

    test('引数なしでデフォルト構築できる', () {
      // ApiService() / OverseasService() のフォールバックパスを通す
      expect(ReceiptService(), isNotNull);
    });
  });

  // ─────────────────────────────────────────
  // analyzeReceipt
  // ─────────────────────────────────────────
  group('analyzeReceipt', () {
    final fakeBytes = Uint8List.fromList([1, 2, 3]);
    final dummyFile = File('/dev/null');

    final singleAnalysisJson = <String, dynamic>{
      'store_name': 'テスト店',
      'purchased_at': '2026-04-01T10:00:00',
      'total_amount': 1000,
      'items': [],
      'coupons_detected': [],
    };

    test('非海外: is_overseas がボディに含まれない', () async {
      final mockOverseas = MockOverseasService();
      when(() => mockOverseas.getIsOverseas()).thenAnswer((_) async => false);
      when(() => mockApi.post('/receipts/analyze', body: any(named: 'body')))
          .thenAnswer((_) async => singleAnalysisJson);

      final svc = ReceiptService(
        api: mockApi,
        overseasService: mockOverseas,
        compressImage: (_) async => fakeBytes,
      );
      final results = await svc.analyzeReceipt(dummyFile);
      expect(results.length, 1);
      expect(results.first.storeName, 'テスト店');

      final captured = verify(
        () => mockApi.post('/receipts/analyze', body: captureAny(named: 'body')),
      ).captured;
      final body = captured.first as Map<String, dynamic>;
      expect(body.containsKey('is_overseas'), isFalse);
    });

    test('海外モード: is_overseas と current_currency がボディに含まれる', () async {
      final mockOverseas = MockOverseasService();
      when(() => mockOverseas.getIsOverseas()).thenAnswer((_) async => true);
      when(() => mockOverseas.getCurrentCurrency()).thenAnswer((_) async => 'USD');
      when(() => mockApi.post('/receipts/analyze', body: any(named: 'body')))
          .thenAnswer((_) async => singleAnalysisJson);

      final svc = ReceiptService(
        api: mockApi,
        overseasService: mockOverseas,
        compressImage: (_) async => fakeBytes,
      );
      await svc.analyzeReceipt(dummyFile);

      final captured = verify(
        () => mockApi.post('/receipts/analyze', body: captureAny(named: 'body')),
      ).captured;
      final body = captured.first as Map<String, dynamic>;
      expect(body['is_overseas'], true);
      expect(body['current_currency'], 'USD');
    });

    test('receipts キーがある場合は複数レシートをパースする', () async {
      final mockOverseas = MockOverseasService();
      when(() => mockOverseas.getIsOverseas()).thenAnswer((_) async => false);
      when(() => mockApi.post('/receipts/analyze', body: any(named: 'body')))
          .thenAnswer((_) async => {
                'receipts': [singleAnalysisJson, singleAnalysisJson],
              });

      final svc = ReceiptService(
        api: mockApi,
        overseasService: mockOverseas,
        compressImage: (_) async => fakeBytes,
      );
      final results = await svc.analyzeReceipt(dummyFile);
      // 同一店舗・同一日時なので mergeReceiptsAndCoupons で1件にまとまる
      expect(results.length, 1);
    });

    test('documentHint がボディに含まれる', () async {
      final mockOverseas = MockOverseasService();
      when(() => mockOverseas.getIsOverseas()).thenAnswer((_) async => false);
      when(() => mockApi.post('/receipts/analyze', body: any(named: 'body')))
          .thenAnswer((_) async => singleAnalysisJson);

      final svc = ReceiptService(
        api: mockApi,
        overseasService: mockOverseas,
        compressImage: (_) async => fakeBytes,
      );
      await svc.analyzeReceipt(dummyFile, documentHint: 'receipt');

      final captured = verify(
        () => mockApi.post('/receipts/analyze', body: captureAny(named: 'body')),
      ).captured;
      expect((captured.first as Map)['document_hint'], 'receipt');
    });

    test('image_base64 が data:image/jpeg;base64, プレフィックス付きで送られる', () async {
      final mockOverseas = MockOverseasService();
      when(() => mockOverseas.getIsOverseas()).thenAnswer((_) async => false);
      when(() => mockApi.post('/receipts/analyze', body: any(named: 'body')))
          .thenAnswer((_) async => singleAnalysisJson);

      final svc = ReceiptService(
        api: mockApi,
        overseasService: mockOverseas,
        compressImage: (_) async => fakeBytes,
      );
      await svc.analyzeReceipt(dummyFile);

      final captured = verify(
        () => mockApi.post('/receipts/analyze', body: captureAny(named: 'body')),
      ).captured;
      final imageBase64 = (captured.first as Map)['image_base64'] as String;
      expect(imageBase64.startsWith('data:image/jpeg;base64,'), isTrue);
    });
  });

  // ─────────────────────────────────────────
  // Receipt model
  // ─────────────────────────────────────────
  group('Receipt.fromJson', () {
    test('全フィールドが正しくパースされる', () {
      final r = Receipt.fromJson(receiptJson);
      expect(r.receiptId, 'r1');
      expect(r.storeName, 'イオン');
      expect(r.totalAmount, 3000);
      expect(r.paymentMethod, 'credit');
      expect(r.memo, isNull);
      expect(r.savingsAmount, 0);
    });

    test('デフォルト paymentMethod は cash', () {
      final json = Map<String, dynamic>.from(receiptJson)
        ..remove('payment_method');
      final r = Receipt.fromJson(json);
      expect(r.paymentMethod, 'cash');
    });
  });

  // ─────────────────────────────────────────
  // ReceiptAnalysis model
  // ─────────────────────────────────────────
  group('ReceiptAnalysis.fromJson', () {
    test('基本フィールドがパースされる', () {
      final a = ReceiptAnalysis.fromJson(analysisJson);
      expect(a.storeName, 'セブン');
      expect(a.totalAmount, 500);
      expect(a.isMedical, isFalse);
      expect(a.isBill, isFalse);
    });

    test('デフォルト paymentMethod は cash', () {
      final a = ReceiptAnalysis.fromJson(analysisJson);
      expect(a.paymentMethod, 'cash');
    });
  });
}

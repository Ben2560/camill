import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:camill/features/coupon/services/coupon_service.dart';
import 'package:camill/shared/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApi;
  late CouponService service;

  setUp(() {
    mockApi = MockApiService();
    service = CouponService(api: mockApi);
  });

  final couponJson = <String, dynamic>{
    'coupon_id': 'c1',
    'store_name': 'イオン',
    'description': '100円引き',
    'discount_amount': 100,
    'valid_from': null,
    'valid_until': null,
    'is_used': false,
    'is_from_ocr': false,
    'available_days': null,
    'requires_survey': false,
    'survey_url': null,
    'survey_answered': false,
    'created_at': '2026-04-01T00:00:00',
  };

  group('fetchCoupons', () {
    test('クーポンリストを返す', () async {
      when(
        () => mockApi.getAny('/coupons', query: any(named: 'query')),
      ).thenAnswer((_) async => [couponJson]);

      final coupons = await service.fetchCoupons();
      expect(coupons.length, 1);
      expect(coupons.first.storeName, 'イオン');
      expect(coupons.first.discountAmount, 100);
    });

    test('is_used フィルター付きで getAny が呼ばれる', () async {
      when(
        () => mockApi.getAny('/coupons', query: any(named: 'query')),
      ).thenAnswer((_) async => []);

      await service.fetchCoupons(isUsed: true);
      final captured = verify(
        () => mockApi.getAny('/coupons', query: captureAny(named: 'query')),
      ).captured;
      expect((captured.first as Map)['is_used'], 'true');
    });

    test('API が null を返すとき空リストを返す', () async {
      when(
        () => mockApi.getAny('/coupons', query: any(named: 'query')),
      ).thenAnswer((_) async => null);

      final coupons = await service.fetchCoupons();
      expect(coupons, isEmpty);
    });
  });

  group('createCoupon', () {
    test('新しい Coupon を返す', () async {
      when(
        () => mockApi.postAny('/coupons', body: any(named: 'body')),
      ).thenAnswer((_) async => couponJson);

      final coupon = await service.createCoupon(
        storeName: 'イオン',
        description: '100円引き',
        discountAmount: 100,
      );
      expect(coupon.couponId, 'c1');
    });
  });

  group('useCoupon', () {
    test('patch /coupons/c1/use が呼ばれる', () async {
      when(
        () => mockApi.patch('/coupons/c1/use', body: any(named: 'body')),
      ).thenAnswer((_) async => <String, dynamic>{});

      await service.useCoupon('c1');
      verify(() => mockApi.patch('/coupons/c1/use', body: {})).called(1);
    });
  });

  group('deleteCoupon', () {
    test('delete /coupons/c1 が呼ばれる', () async {
      when(() => mockApi.delete('/coupons/c1')).thenAnswer((_) async {});

      await service.deleteCoupon('c1');
      verify(() => mockApi.delete('/coupons/c1')).called(1);
    });
  });

  group('shareToCommunity', () {
    test('patch /coupons/c1/share-to-community が呼ばれる', () async {
      when(
        () => mockApi.patch(
          '/coupons/c1/share-to-community',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{});

      await service.shareToCommunity('c1');
      verify(
        () => mockApi.patch('/coupons/c1/share-to-community', body: {}),
      ).called(1);
    });
  });
}

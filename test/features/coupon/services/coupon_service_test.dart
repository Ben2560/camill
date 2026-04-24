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

    test('全オプション引数を渡したときボディに含まれる', () async {
      when(
        () => mockApi.postAny('/coupons', body: any(named: 'body')),
      ).thenAnswer((_) async => couponJson);

      await service.createCoupon(
        storeName: 'イオン',
        description: '100円引き',
        discountAmount: 100,
        validFrom: '2026-04-01',
        validUntil: '2026-04-30',
        availableDays: [1, 2, 3],
        isFromOcr: true,
        isUsed: true,
        receiptId: 'r1',
        requiresSurvey: true,
        surveyUrl: 'https://example.com',
        surveyAnswered: true,
      );

      final captured = verify(
        () => mockApi.postAny('/coupons', body: captureAny(named: 'body')),
      ).captured;
      final body = captured.first as Map<String, dynamic>;
      expect(body['valid_from'], '2026-04-01');
      expect(body['valid_until'], '2026-04-30');
      expect(body['available_days'], [1, 2, 3]);
      expect(body['receipt_id'], 'r1');
      expect(body['survey_url'], 'https://example.com');
      expect(body['is_from_ocr'], true);
      expect(body['requires_survey'], true);
      expect(body['survey_answered'], true);
    });
  });

  group('markSurveyAnswered', () {
    test('patch /coupons/c1/survey-answered が呼ばれる', () async {
      when(
        () => mockApi.patch(
          '/coupons/c1/survey-answered',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{});

      await service.markSurveyAnswered('c1');
      verify(
        () => mockApi.patch('/coupons/c1/survey-answered', body: {}),
      ).called(1);
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

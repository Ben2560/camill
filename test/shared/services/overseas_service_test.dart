import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camill/shared/services/overseas_service.dart';
import 'package:camill/shared/services/api_service.dart';
import 'package:camill/shared/services/user_prefs.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserPrefs.uidGetter = () => 'testuid';
  });

  tearDown(() {
    UserPrefs.uidGetter = null;
  });

  // ─────────────────────────────────────────
  // OverseasDetectionResult
  // ─────────────────────────────────────────
  group('OverseasDetectionResult', () {
    test('全フィールドが設定される', () {
      final r = OverseasDetectionResult(
        isOverseas: true,
        countryCode: 'US',
        currency: 'USD',
        countryName: 'アメリカ',
      );
      expect(r.isOverseas, true);
      expect(r.countryCode, 'US');
      expect(r.currency, 'USD');
      expect(r.countryName, 'アメリカ');
    });

    test('countryName は省略可能（null）', () {
      final r = OverseasDetectionResult(
        isOverseas: false,
        countryCode: 'JP',
        currency: 'JPY',
      );
      expect(r.countryName, isNull);
      expect(r.isOverseas, false);
    });

    test('isOverseas=false でも有効なインスタンスを生成できる', () {
      final r = OverseasDetectionResult(
        isOverseas: false,
        countryCode: 'JP',
        currency: 'JPY',
        countryName: null,
      );
      expect(r.currency, 'JPY');
    });
  });

  // ─────────────────────────────────────────
  // getIsOverseas
  // ─────────────────────────────────────────
  group('getIsOverseas', () {
    test('値未設定のとき false を返す', () async {
      final service = OverseasService(MockApiService());
      expect(await service.getIsOverseas(), false);
    });

    test('true が保存されているとき true を返す', () async {
      SharedPreferences.setMockInitialValues({
        'uid_testuid_is_overseas': true,
      });
      final service = OverseasService(MockApiService());
      expect(await service.getIsOverseas(), true);
    });

    test('false が保存されているとき false を返す', () async {
      SharedPreferences.setMockInitialValues({
        'uid_testuid_is_overseas': false,
      });
      final service = OverseasService(MockApiService());
      expect(await service.getIsOverseas(), false);
    });
  });

  // ─────────────────────────────────────────
  // getCurrentCurrency
  // ─────────────────────────────────────────
  group('getCurrentCurrency', () {
    test('値未設定のとき JPY を返す', () async {
      final service = OverseasService(MockApiService());
      expect(await service.getCurrentCurrency(), 'JPY');
    });

    test('保存済み通貨コードを返す', () async {
      SharedPreferences.setMockInitialValues({
        'uid_testuid_current_currency': 'USD',
      });
      final service = OverseasService(MockApiService());
      expect(await service.getCurrentCurrency(), 'USD');
    });

    test('THB が保存されているとき THB を返す', () async {
      SharedPreferences.setMockInitialValues({
        'uid_testuid_current_currency': 'THB',
      });
      final service = OverseasService(MockApiService());
      expect(await service.getCurrentCurrency(), 'THB');
    });
  });

  // ─────────────────────────────────────────
  // applyOverseasStatus
  // ─────────────────────────────────────────
  group('applyOverseasStatus', () {
    test('is_overseas と currency が SharedPreferences に保存される', () async {
      final mockApi = MockApiService();
      when(
        () => mockApi.patch(
          '/exchange-rates/overseas',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{});

      final service = OverseasService(mockApi);
      await service.applyOverseasStatus(
        isOverseas: true,
        currency: 'USD',
        countryCode: 'US',
      );

      final p = await SharedPreferences.getInstance();
      expect(p.getBool('uid_testuid_is_overseas'), true);
      expect(p.getString('uid_testuid_current_currency'), 'USD');
      expect(p.getString('uid_testuid_last_country_code'), 'US');
    });

    test('帰国時に false と JPY が保存される', () async {
      final mockApi = MockApiService();
      when(
        () => mockApi.patch(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => <String, dynamic>{});

      final service = OverseasService(mockApi);
      await service.applyOverseasStatus(
        isOverseas: false,
        currency: 'JPY',
        countryCode: 'JP',
      );

      final p = await SharedPreferences.getInstance();
      expect(p.getBool('uid_testuid_is_overseas'), false);
      expect(p.getString('uid_testuid_current_currency'), 'JPY');
    });

    test('API エラーが発生しても例外をスローしない', () async {
      final mockApi = MockApiService();
      when(
        () => mockApi.patch(any(), body: any(named: 'body')),
      ).thenThrow(Exception('network error'));

      final service = OverseasService(mockApi);
      await expectLater(
        service.applyOverseasStatus(
          isOverseas: true,
          currency: 'EUR',
          countryCode: 'DE',
        ),
        completes,
      );
    });

    test('API エラー時もローカルには保存される', () async {
      final mockApi = MockApiService();
      when(
        () => mockApi.patch(any(), body: any(named: 'body')),
      ).thenThrow(Exception('offline'));

      final service = OverseasService(mockApi);
      await service.applyOverseasStatus(
        isOverseas: true,
        currency: 'KRW',
        countryCode: 'KR',
      );

      final p = await SharedPreferences.getInstance();
      expect(p.getBool('uid_testuid_is_overseas'), true);
      expect(p.getString('uid_testuid_current_currency'), 'KRW');
    });

    test('正しいエンドポイントに PATCH が呼ばれる', () async {
      final mockApi = MockApiService();
      when(
        () => mockApi.patch(
          '/exchange-rates/overseas',
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => <String, dynamic>{});

      final service = OverseasService(mockApi);
      await service.applyOverseasStatus(
        isOverseas: true,
        currency: 'SGD',
        countryCode: 'SG',
      );

      final captured = verify(
        () => mockApi.patch(
          '/exchange-rates/overseas',
          body: captureAny(named: 'body'),
        ),
      ).captured;
      final body = captured.first as Map<String, dynamic>;
      expect(body['is_overseas'], true);
      expect(body['current_currency'], 'SGD');
    });
  });
}

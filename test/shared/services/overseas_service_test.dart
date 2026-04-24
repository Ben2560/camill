import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camill/shared/services/overseas_service.dart';
import 'package:camill/shared/services/api_service.dart';
import 'package:camill/shared/services/user_prefs.dart';

Position _pos(double lat, double lon) => Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime(2026, 4, 24),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

/// Nominatim レスポンスを返す MockClient を作る
MockClient _nominatimClient(String countryCode) => MockClient(
      (_) async => http.Response(
        '{"address": {"country_code": "$countryCode"}}',
        200,
      ),
    );

/// getCountryCode が null を返す MockClient
final _nullCountryClient = MockClient((_) async => http.Response('{}', 200));

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

  // ─────────────────────────────────────────
  // getCountryCode
  // ─────────────────────────────────────────
  group('getCountryCode', () {
    test('200 OK で country_code を大文字で返す', () async {
      final client = MockClient((_) async => http.Response(
            '{"address": {"country_code": "jp"}}',
            200,
          ));
      final service = OverseasService(MockApiService(), httpClient: client);
      final code = await service.getCountryCode(35.6, 139.7);
      expect(code, 'JP');
    });

    test('200 OK で US を返す', () async {
      final client = MockClient((_) async => http.Response(
            '{"address": {"country_code": "us"}}',
            200,
          ));
      final service = OverseasService(MockApiService(), httpClient: client);
      final code = await service.getCountryCode(40.7, -74.0);
      expect(code, 'US');
    });

    test('address フィールドがない場合は null を返す', () async {
      final client = MockClient((_) async => http.Response('{}', 200));
      final service = OverseasService(MockApiService(), httpClient: client);
      final code = await service.getCountryCode(0.0, 0.0);
      expect(code, isNull);
    });

    test('非200 ステータスは null を返す', () async {
      final client = MockClient((_) async => http.Response('', 500));
      final service = OverseasService(MockApiService(), httpClient: client);
      final code = await service.getCountryCode(0.0, 0.0);
      expect(code, isNull);
    });

    test('通信エラーは null を返す（例外をスローしない）', () async {
      final client = MockClient((_) async => throw Exception('network error'));
      final service = OverseasService(MockApiService(), httpClient: client);
      expect(await service.getCountryCode(0.0, 0.0), isNull);
    });
  });

  // ─────────────────────────────────────────
  // fetchRates
  // ─────────────────────────────────────────
  group('fetchRates', () {
    test('200 OK でレートマップを返す', () async {
      const body = '{"USD": 150.0, "EUR": 163.0}';
      final client = MockClient((_) async => http.Response(body, 200));
      final service = OverseasService(MockApiService(), httpClient: client);
      final rates = await service.fetchRates();
      expect(rates['USD'], 150.0);
      expect(rates['EUR'], 163.0);
    });

    test('非200 ステータスは空マップを返す', () async {
      final client = MockClient((_) async => http.Response('', 500));
      final service = OverseasService(MockApiService(), httpClient: client);
      expect(await service.fetchRates(), isEmpty);
    });

    test('通信エラーは空マップを返す', () async {
      final client = MockClient((_) async => throw Exception('timeout'));
      final service = OverseasService(MockApiService(), httpClient: client);
      expect(await service.fetchRates(), isEmpty);
    });
  });

  // ─────────────────────────────────────────
  // fetchRateHistory
  // ─────────────────────────────────────────
  group('fetchRateHistory', () {
    test('200 OK で履歴リストを返す', () async {
      const body =
          '{"history": [{"date": "2026-04-24", "rate": 150.0}, {"date": "2026-04-23", "rate": 149.5}]}';
      final client = MockClient((_) async => http.Response(body, 200));
      final service = OverseasService(MockApiService(), httpClient: client);
      final history = await service.fetchRateHistory('USD');
      expect(history.length, 2);
      expect(history.first['date'], '2026-04-24');
    });

    test('history キーが null の場合は空リストを返す', () async {
      final client =
          MockClient((_) async => http.Response('{"history": null}', 200));
      final service = OverseasService(MockApiService(), httpClient: client);
      expect(await service.fetchRateHistory('USD'), isEmpty);
    });

    test('非200 ステータスは空リストを返す', () async {
      final client = MockClient((_) async => http.Response('', 404));
      final service = OverseasService(MockApiService(), httpClient: client);
      expect(await service.fetchRateHistory('USD'), isEmpty);
    });

    test('通信エラーは空リストを返す', () async {
      final client = MockClient((_) async => throw Exception('offline'));
      final service = OverseasService(MockApiService(), httpClient: client);
      expect(await service.fetchRateHistory('EUR'), isEmpty);
    });

    test('currency がクエリパラメータに含まれる', () async {
      Uri? capturedUri;
      final client = MockClient((req) async {
        capturedUri = req.url;
        return http.Response('{"history": []}', 200);
      });
      final service = OverseasService(MockApiService(), httpClient: client);
      await service.fetchRateHistory('THB');
      expect(capturedUri?.queryParameters['currency'], 'THB');
    });
  });

  // ─────────────────────────────────────────
  // detectCountryChange
  // ─────────────────────────────────────────
  group('detectCountryChange', () {
    OverseasService makeService({
      LocationPermission permission = LocationPermission.always,
      Position? position,
      bool positionThrows = false,
      http.Client? httpClient,
    }) {
      return OverseasService(
        MockApiService(),
        httpClient: httpClient ?? _nullCountryClient,
        checkPermission: () async => permission,
        getCurrentPosition: positionThrows
            ? () async => throw Exception('location error')
            : () async => position ?? _pos(35.6, 139.7),
      );
    }

    test('権限 denied のとき null を返す', () async {
      final svc = makeService(permission: LocationPermission.denied);
      expect(await svc.detectCountryChange(), isNull);
    });

    test('権限 deniedForever のとき null を返す', () async {
      final svc = makeService(permission: LocationPermission.deniedForever);
      expect(await svc.detectCountryChange(), isNull);
    });

    test('位置情報取得で例外が出たとき null を返す', () async {
      final svc = makeService(positionThrows: true);
      expect(await svc.detectCountryChange(), isNull);
    });

    test('getCountryCode が null のとき null を返す', () async {
      final svc = makeService(httpClient: _nullCountryClient);
      expect(await svc.detectCountryChange(), isNull);
    });

    test('前回と同じ国コードのとき null を返す', () async {
      SharedPreferences.setMockInitialValues({
        'uid_testuid_last_country_code': 'US',
      });
      final svc = makeService(httpClient: _nominatimClient('us'));
      expect(await svc.detectCountryChange(), isNull);
    });

    test('新しい海外国（US）→ isOverseas=true / currency=USD', () async {
      final svc = makeService(httpClient: _nominatimClient('us'));
      final result = await svc.detectCountryChange();
      expect(result, isNotNull);
      expect(result!.isOverseas, true);
      expect(result.countryCode, 'US');
      expect(result.currency, 'USD');
      expect(result.countryName, 'アメリカ');
    });

    test('帰国（JP）→ isOverseas=false / currency=JPY', () async {
      SharedPreferences.setMockInitialValues({
        'uid_testuid_last_country_code': 'US',
      });
      final svc = makeService(httpClient: _nominatimClient('jp'));
      final result = await svc.detectCountryChange();
      expect(result, isNotNull);
      expect(result!.isOverseas, false);
      expect(result.currency, 'JPY');
      // isOverseas=false のとき countryName は null → countryCode フォールバック
      expect(result.countryName, 'JP');
    });

    test('通貨マップにない国コード → currency=JPY', () async {
      // ZZ は _countryCurrencyMap に存在しない
      final svc = makeService(httpClient: _nominatimClient('zz'));
      final result = await svc.detectCountryChange();
      expect(result, isNotNull);
      expect(result!.currency, 'JPY');
    });

    test('countryNames にない国コード → countryName=countryCode', () async {
      // NL は _countryCurrencyMap には EUR だが _countryNames には存在しない
      final svc = makeService(httpClient: _nominatimClient('nl'));
      final result = await svc.detectCountryChange();
      expect(result, isNotNull);
      expect(result!.currency, 'EUR');
      expect(result.countryName, 'NL');
    });
  });
}

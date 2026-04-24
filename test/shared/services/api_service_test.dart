import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:camill/shared/services/api_service.dart';

class MockHttpClient extends Mock implements http.Client {}

// http.Response(String) は Latin-1 エンコードで日本語が通らないため bytes() を使う
http.Response _jsonResponse(Map<String, dynamic> body, int statusCode) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), statusCode);

/// テスト用 ApiService（Firebase 不要）
ApiService _makeService(MockHttpClient client) => ApiService(
      client: client,
      tokenProvider: () async => 'test-token',
    );

void main() {
  late MockHttpClient mockClient;
  late ApiService apiService;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://example.com'));
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    mockClient = MockHttpClient();
    apiService = _makeService(mockClient);
  });

  // ─────────────────────────────────────────
  // ApiException
  // ─────────────────────────────────────────
  group('ApiException', () {
    test('toString にステータスコードとメッセージが含まれる', () {
      final e = ApiException(404, 'NOT_FOUND', 'みつかりません');
      expect(e.toString(), contains('404'));
      expect(e.toString(), contains('みつかりません'));
    });

    test('extra フィールドを保持する', () {
      final e = ApiException(400, 'BAD', 'bad', extra: {'field': 'value'});
      expect(e.extra?['field'], 'value');
    });

    test('code・message・statusCode が正しく設定される', () {
      final e = ApiException(422, 'VALIDATION_ERROR', 'name: 必須項目です');
      expect(e.code, 'VALIDATION_ERROR');
      expect(e.statusCode, 422);
      expect(e.message, contains('必須'));
    });
  });

  // ─────────────────────────────────────────
  // GET
  // ─────────────────────────────────────────
  group('get()', () {
    test('200 レスポンスの data を Map として返す', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _jsonResponse({'data': {'id': '1'}}, 200));

      final result = await apiService.get('/test');
      expect(result['id'], '1');
    });

    test('Authorization ヘッダーが Bearer token 形式で送信される', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _jsonResponse({'data': {}}, 200));

      await apiService.get('/test');

      final captured = verify(
        () => mockClient.get(any(), headers: captureAny(named: 'headers')),
      ).captured;
      final headers = captured.first as Map<String, String>;
      expect(headers['Authorization'], 'Bearer test-token');
      expect(headers['Content-Type'], 'application/json');
    });

    test('query パラメータが URI に付与される', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _jsonResponse({'data': []}, 200));

      await apiService.getAny('/items', query: {'page': '2', 'limit': '10'});

      final captured = verify(
        () => mockClient.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      final uri = captured.first as Uri;
      expect(uri.queryParameters['page'], '2');
      expect(uri.queryParameters['limit'], '10');
    });

    test('400 でカスタムエラー（detail が Map）は ApiException をスロー', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _jsonResponse({
                'data': null,
                'detail': {'code': 'LIMIT_EXCEEDED', 'message': '上限超過'},
              }, 400));

      expect(
        () => apiService.get('/test'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'LIMIT_EXCEEDED')
              .having((e) => e.message, 'message', '上限超過')
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });

    test('422 で FastAPI バリデーションエラー（detail が List）は ApiException をスロー', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _jsonResponse({
                'data': null,
                'detail': [
                  {'loc': ['body', 'name'], 'msg': 'field required'},
                ],
              }, 422));

      expect(
        () => apiService.get('/test'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'VALIDATION_ERROR')
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.message, 'message', contains('name')),
        ),
      );
    });

    test('503 で detail が String の場合メッセージが設定される', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async =>
              _jsonResponse({'data': null, 'detail': 'Service Unavailable'}, 503));

      expect(
        () => apiService.get('/test'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Service Unavailable')
              .having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });
  });

  // ─────────────────────────────────────────
  // getAny（List レスポンス）
  // ─────────────────────────────────────────
  group('getAny()', () {
    test('data が List の場合そのまま返す', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => _jsonResponse({
                'data': [
                  {'id': 1},
                  {'id': 2},
                ],
              }, 200));

      final result = await apiService.getAny('/list');
      expect(result, isA<List>());
      expect((result as List).length, 2);
    });
  });

  // ─────────────────────────────────────────
  // POST
  // ─────────────────────────────────────────
  group('post()', () {
    test('200 レスポンスの data を Map として返す', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _jsonResponse({'data': {'created': true}}, 201));

      final result = await apiService.post('/create', body: {'name': 'test'});
      expect(result['created'], true);
    });

    test('ボディが JSON エンコードされて送信される', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _jsonResponse({'data': {}}, 200));

      await apiService.post('/test', body: {'key': 'value', 'num': 42});

      final captured = verify(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured;
      final decoded = jsonDecode(captured.first as String);
      expect(decoded['key'], 'value');
      expect(decoded['num'], 42);
    });

    test('data が null の場合は空 Map を返す', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _jsonResponse({'data': null}, 200));

      final result = await apiService.post('/test', body: {});
      expect(result, isEmpty);
    });

    test('400 カスタムエラーは ApiException をスロー', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _jsonResponse({
                'data': null,
                'detail': {'code': 'DUPLICATE', 'message': '重複しています'},
              }, 400));

      expect(
        () => apiService.post('/test', body: {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'DUPLICATE')
              .having((e) => e.message, 'message', '重複しています'),
        ),
      );
    });

    test('extra フィールドが ApiException に含まれる', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _jsonResponse({
                'data': null,
                'detail': {
                  'code': 'LIMIT',
                  'message': '上限',
                  'current': 5,
                  'max': 3,
                },
              }, 400));

      ApiException? caught;
      try {
        await apiService.post('/test', body: {});
      } on ApiException catch (e) {
        caught = e;
      }
      expect(caught?.extra?['current'], 5);
      expect(caught?.extra?['max'], 3);
    });
  });

  // ─────────────────────────────────────────
  // PATCH
  // ─────────────────────────────────────────
  group('patch()', () {
    test('200 レスポンスの data を Map として返す', () async {
      when(() => mockClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _jsonResponse({'data': {'updated': true}}, 200));

      final result = await apiService.patch('/update', body: {'name': 'new'});
      expect(result['updated'], true);
    });

    test('400 エラーは ApiException をスロー', () async {
      when(() => mockClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _jsonResponse({
                'data': null,
                'detail': {'code': 'NOT_FOUND', 'message': '存在しません'},
              }, 404));

      expect(
        () => apiService.patch('/update', body: {}),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  // ─────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────
  group('delete()', () {
    test('204 は正常終了する', () async {
      when(() => mockClient.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 204));

      await expectLater(apiService.delete('/item/1'), completes);
    });

    test('200 は正常終了する', () async {
      when(() => mockClient.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 200));

      await expectLater(apiService.delete('/item/1'), completes);
    });

    test('404 でカスタムエラーボディがある場合 ApiException をスロー', () async {
      when(() => mockClient.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response.bytes(
                utf8.encode(jsonEncode({
                  'detail': {'code': 'NOT_FOUND', 'message': '存在しません'},
                })),
                404,
              ));

      expect(
        () => apiService.delete('/item/999'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'NOT_FOUND')
              .having((e) => e.message, 'message', '存在しません')
              .having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('500 でボディなしの場合デフォルトメッセージで ApiException をスロー', () async {
      when(() => mockClient.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 500));

      expect(
        () => apiService.delete('/item/1'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'DELETE_FAILED')
              .having((e) => e.message, 'message', '削除に失敗しました')
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('400 で detail が String の場合その文字列がメッセージになる', () async {
      when(() => mockClient.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response.bytes(
                utf8.encode(jsonEncode({'detail': 'cannot delete'})),
                400,
              ));

      expect(
        () => apiService.delete('/item/1'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'cannot delete'),
        ),
      );
    });
  });

  // ─────────────────────────────────────────
  // _handleResponse の境界ケース
  // ─────────────────────────────────────────
  group('_handleResponse 境界ケース', () {
    test('422 で detail が空 List の場合デフォルトエラーメッセージ', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async =>
              _jsonResponse({'data': null, 'detail': []}, 422));

      // detail が空 List → List branch に入らずデフォルトメッセージになる
      expect(
        () => apiService.get('/test'),
        throwsA(
          isA<ApiException>().having(
              (e) => e.message, 'message', 'エラーが発生しました'),
        ),
      );
    });

    test('エラー時 detail が null の場合デフォルト UNKNOWN コード', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async =>
              _jsonResponse({'data': null, 'detail': null}, 500));

      expect(
        () => apiService.get('/test'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'UNKNOWN')
              .having((e) => e.message, 'message', 'エラーが発生しました'),
        ),
      );
    });
  });
}

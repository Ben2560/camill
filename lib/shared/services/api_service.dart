import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;
  final Map<String, dynamic>? extra;

  ApiException(this.statusCode, this.code, this.message, {this.extra});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  final http.Client _client;
  final Future<String> Function()? _tokenProvider;

  ApiService({http.Client? client, Future<String> Function()? tokenProvider})
      : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider;

  static final Future<void> _authReady = FirebaseAuth.instance
      .authStateChanges()
      .first
      .then((_) {});

  Future<Map<String, String>> _authHeaders() async {
    final String token;
    if (_tokenProvider != null) {
      token = await _tokenProvider();
    } else {
      await _authReady;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw ApiException(401, 'UNAUTHORIZED', '未ログインです');
      token = await user.getIdToken() ?? '';
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// data が Map の場合に使う
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final data = await getAny(path, query: query);
    return data as Map<String, dynamic>;
  }

  /// data が List または Map の場合に使う
  Future<dynamic> getAny(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}$path',
    ).replace(queryParameters: query);
    final headers = await _authHeaders();
    final response = await _client.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final data = await postAny(path, body: body);
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Future<dynamic> postAny(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final headers = await _authHeaders();
    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final headers = await _authHeaders();
    final response = await _client.patch(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }

  Future<void> delete(String path) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final headers = await _authHeaders();
    final response = await _client.delete(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String code = 'DELETE_FAILED';
      String message = '削除に失敗しました';
      if (response.bodyBytes.isNotEmpty) {
        try {
          final body =
              jsonDecode(utf8.decode(response.bodyBytes))
                  as Map<String, dynamic>;
          final detail = body['detail'];
          if (detail is Map) {
            code = detail['code'] as String? ?? code;
            message = detail['message'] as String? ?? message;
          } else if (detail is String) {
            message = detail;
          }
        } catch (_) {}
      }
      throw ApiException(response.statusCode, code, message);
    }
  }

  dynamic _handleResponse(http.Response response) {
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body['data'];
    }
    final detail = body['detail'];
    String code = 'UNKNOWN';
    String message = 'エラーが発生しました';

    if (detail is Map) {
      // カスタムエラー形式
      code = detail['code'] as String? ?? code;
      message = detail['message'] as String? ?? message;
      throw ApiException(
        response.statusCode,
        code,
        message,
        extra: Map<String, dynamic>.from(detail),
      );
    } else if (detail is List && detail.isNotEmpty) {
      // FastAPI バリデーションエラー（422）
      code = response.statusCode == 422 ? 'VALIDATION_ERROR' : code;
      message = detail
          .whereType<Map>()
          .map((e) {
            final loc = (e['loc'] as List?)?.join('.') ?? '';
            final msg = e['msg'] ?? '';
            return loc.isNotEmpty ? '$loc: $msg' : '$msg';
          })
          .join(' / ');
      if (message.isEmpty) message = 'バリデーションエラー';
    } else if (detail is String) {
      message = detail;
    }

    throw ApiException(response.statusCode, code, message);
  }
}

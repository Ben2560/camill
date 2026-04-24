import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants.dart';

class ErrorReporter {
  static final _crashlytics = FirebaseCrashlytics.instance;

  /// エラーをCrashlytics + 管理画面APIの両方に送信する
  static Future<void> report(
    dynamic error,
    StackTrace? stack, {
    String? endpoint,
    String level = 'error',
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(
        error,
        stack,
        reason: endpoint,
        fatal: fatal,
      );
    } catch (_) {}
    _postToAdminApi(
      message: error.toString(),
      traceback: stack?.toString(),
      endpoint: endpoint,
      level: level,
    );
  }

  /// メッセージをCrashlytics + 管理画面APIの両方に送信する
  static Future<void> reportMessage(
    String message, {
    String? endpoint,
    String level = 'warning',
  }) async {
    try {
      await _crashlytics.log(message);
    } catch (_) {}
    _postToAdminApi(message: message, endpoint: endpoint, level: level);
  }

  static void _postToAdminApi({
    required String message,
    String? traceback,
    String? endpoint,
    required String level,
  }) {
    final body = <String, dynamic>{
      'message': message,
      'level': level,
      'endpoint': endpoint,
      'traceback': traceback,
    };
    http
        .post(
          Uri.parse('${AppConstants.apiBaseUrl}/admin/errors/report'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .catchError((Object _) => http.Response('', 0));
  }

  // ── パフォーマンス計測ユーティリティ ──────────────────────────

  static Stopwatch startTimer() => Stopwatch()..start();

  /// 計測終了し、閾値を超えたら警告として送信する
  static void checkSlow(
    Stopwatch sw,
    String operationName, {
    Duration threshold = const Duration(seconds: 3),
  }) {
    sw.stop();
    if (sw.elapsed > threshold) {
      reportMessage(
        'Slow operation: $operationName (${sw.elapsedMilliseconds}ms)',
        endpoint: operationName,
        level: 'warning',
      );
      debugPrint(
        '[Perf] $operationName took ${sw.elapsedMilliseconds}ms (threshold: ${threshold.inMilliseconds}ms)',
      );
    }
  }
}

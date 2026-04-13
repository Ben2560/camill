import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'notification_inbox.dart';

/// バックグラウンドメッセージハンドラー（トップレベル関数・アノテーション必須）。
/// アプリが完全に終了しているときにFCMメッセージを受け取った場合に呼ばれる。
/// この関数ではUIを触れないため、ログのみ記録する。
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  debugPrint('[FCM] background message: ${message.messageId}');
}

/// FCMプッシュ通知の初期化・トークン管理・受信ハンドリングを担うサービス。
///
/// 使い方:
///   1. `main()` で `NotificationService.init()` を呼ぶ。
///   2. ログイン後（MainShell.initState）で `NotificationService().registerToken()` を呼ぶ。
///   3. MainShell で `onForegroundMessage` と `onRoutePush` を購読してUIに反映する。
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final _messaging = FirebaseMessaging.instance;

  /// フォアグラウンド着信メッセージのストリーム。
  /// MainShell でリッスンしてトースト表示に使う。
  final onForegroundMessage = StreamController<RemoteMessage>.broadcast();

  /// 通知タップ時のルートストリーム（例: '/bills', '/coupon-wallet'）。
  /// MainShell でリッスンして context.go() で遷移する。
  final onRoutePush = StreamController<String>.broadcast();

  // ──────────────────────────────────────────────────────
  // 初期化（main() で一度だけ呼ぶ）
  // ──────────────────────────────────────────────────────

  /// Firebase Messaging をセットアップする。
  /// バックグラウンドハンドラーの登録、フォアグラウンド通知表示設定、
  /// 通知タップ時のルーティングをまとめて行う。
  static Future<void> init() async {
    // バックグラウンドハンドラー登録（必ず initializeApp の後）
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

    // iOS: フォアグラウンド中も通知バナーを表示する
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // バックグラウンドから通知タップで復帰したとき
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _saveToInbox(message);
      final route = message.data['route'] as String?;
      if (route != null) {
        NotificationService()._pushRoute(route);
      }
    });

    // フォアグラウンドでメッセージを受信したとき → インボックスに保存してトーストも出す
    FirebaseMessaging.onMessage.listen((message) {
      _saveToInbox(message);
      NotificationService().onForegroundMessage.add(message);
    });
  }

  static void _saveToInbox(RemoteMessage message) {
    final title = message.notification?.title ?? '';
    final body  = message.notification?.body  ?? '';
    NotificationInbox().add(
      title: title,
      body:  body,
      route: message.data['route'] as String?,
    );
  }

  void _pushRoute(String route) => onRoutePush.add(route);

  // ──────────────────────────────────────────────────────
  // ログイン後に呼ぶ
  // ──────────────────────────────────────────────────────

  /// 通知パーミッションを要求し、FCMトークンをバックエンドに登録する。
  /// トークンが更新されたときも自動的に再登録する。
  Future<void> registerToken() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] permission denied');
        return;
      }

      // iOS では APNS トークンが準備できていない場合（シミュレーター等）はスキップ
      if (Platform.isIOS) {
        final apns = await _messaging.getAPNSToken();
        if (apns == null) {
          debugPrint('[FCM] APNS token not available (simulator?)');
          return;
        }
      }

      final token = await _messaging.getToken();
      if (token == null) return;

      await _sendTokenToServer(token);

      // トークンリフレッシュを監視して自動更新
      _messaging.onTokenRefresh.listen(_sendTokenToServer);
    } catch (e) {
      debugPrint('[FCM] registerToken failed: $e');
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await ApiService().patch('/users/fcm-token', body: {'token': token});
      debugPrint('[FCM] token registered: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('[FCM] token upload failed: $e');
    }
  }

  // ──────────────────────────────────────────────────────
  // アプリ起動時に呼ぶ（MainShell.initState）
  // ──────────────────────────────────────────────────────

  /// アプリが終了した状態から通知タップで起動した場合の初期メッセージを確認する。
  /// GoRouter が準備できる後（addPostFrameCallback 内など）に呼ぶこと。
  Future<void> checkInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      NotificationService._saveToInbox(message);
      final route = message.data['route'] as String?;
      if (route != null) {
        _pushRoute(route);
      }
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationItem {
  final String title;
  final String body;
  final String? route;
  final DateTime receivedAt;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.body,
    this.route,
    required this.receivedAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'route': route,
        'receivedAt': receivedAt.toIso8601String(),
        'isRead': isRead,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        route: json['route'] as String?,
        receivedAt: DateTime.parse(json['receivedAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
      );
}

/// 受信したプッシュ通知をローカルに蓄積するインボックス。
///
/// SharedPreferences に最大 [_maxItems] 件保存する。
/// [unreadCount] を ValueNotifier で公開しているため、
/// UIはこれをリッスンしてバッジを更新できる。
class NotificationInbox {
  NotificationInbox._();
  static final NotificationInbox _instance = NotificationInbox._();
  factory NotificationInbox() => _instance;

  static const _prefsKey = 'camill_notification_inbox';
  static const _maxItems = 50;

  /// 未読件数。ValueNotifier なのでベルバッジの再描画に使う。
  final unreadCount = ValueNotifier<int>(0);

  List<NotificationItem> _items = [];

  /// アプリ起動時に呼んで保存済みデータを読み込む。
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _items = list
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _items = [];
    }
    _refreshUnread();
  }

  /// 通知を先頭に追加して保存する。
  Future<void> add({
    required String title,
    required String body,
    String? route,
  }) async {
    if (title.isEmpty && body.isEmpty) return;
    _items.insert(
      0,
      NotificationItem(
        title: title,
        body: body,
        route: route,
        receivedAt: DateTime.now(),
      ),
    );
    if (_items.length > _maxItems) _items = _items.sublist(0, _maxItems);
    _refreshUnread();
    await _save();
  }

  List<NotificationItem> getAll() => List.unmodifiable(_items);

  /// 全通知を既読にする。
  Future<void> markAllRead() async {
    for (final item in _items) {
      item.isRead = true;
    }
    _refreshUnread();
    await _save();
  }

  /// 全通知を削除する。
  Future<void> clear() async {
    _items = [];
    _refreshUnread();
    await _save();
  }

  void _refreshUnread() =>
      unreadCount.value = _items.where((i) => !i.isRead).length;

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_items.map((i) => i.toJson()).toList()),
    );
  }
}

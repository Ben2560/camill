import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camill/shared/services/notification_inbox.dart';
import 'package:camill/shared/services/user_prefs.dart';

void main() {
  late NotificationInbox inbox;

  setUpAll(() {
    // Firebase を使わず固定 UID で動作させる
    UserPrefs.uidGetter = () => null;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    inbox = NotificationInbox();
    await inbox.clear(); // シングルトンのメモリ状態をリセット
  });

  tearDownAll(() {
    UserPrefs.uidGetter = null;
  });

  // ─────────────────────────────────────────
  // add
  // ─────────────────────────────────────────
  group('add', () {
    test('通知を追加すると getAll に含まれる', () async {
      await inbox.add(title: '予算超過', body: '食費が上限を超えました');
      final items = inbox.getAll();
      expect(items.length, 1);
      expect(items.first.title, '予算超過');
      expect(items.first.body, '食費が上限を超えました');
    });

    test('route を付与して追加できる', () async {
      await inbox.add(title: 'test', body: 'body', route: '/home');
      expect(inbox.getAll().first.route, '/home');
    });

    test('追加した通知はデフォルトで未読', () async {
      await inbox.add(title: 'test', body: 'b');
      expect(inbox.getAll().first.isRead, isFalse);
    });

    test('複数追加すると先頭に積まれる（新しい順）', () async {
      await inbox.add(title: '1', body: 'a');
      await inbox.add(title: '2', body: 'b');
      await inbox.add(title: '3', body: 'c');
      final titles = inbox.getAll().map((i) => i.title).toList();
      expect(titles, ['3', '2', '1']);
    });

    test('title と body が両方空の通知は追加されない', () async {
      await inbox.add(title: '', body: '');
      expect(inbox.getAll(), isEmpty);
    });

    test('title が空で body があれば追加される', () async {
      await inbox.add(title: '', body: 'メッセージ本文');
      expect(inbox.getAll().length, 1);
    });
  });

  // ─────────────────────────────────────────
  // unreadCount
  // ─────────────────────────────────────────
  group('unreadCount', () {
    test('追加するたびに unreadCount が増える', () async {
      expect(inbox.unreadCount.value, 0);
      await inbox.add(title: 'a', body: 'b');
      expect(inbox.unreadCount.value, 1);
      await inbox.add(title: 'c', body: 'd');
      expect(inbox.unreadCount.value, 2);
    });

    test('markAllRead で unreadCount が 0 になる', () async {
      await inbox.add(title: 'a', body: 'b');
      await inbox.add(title: 'c', body: 'd');
      await inbox.markAllRead();
      expect(inbox.unreadCount.value, 0);
    });

    test('clear で unreadCount が 0 になる', () async {
      await inbox.add(title: 'a', body: 'b');
      await inbox.clear();
      expect(inbox.unreadCount.value, 0);
    });
  });

  // ─────────────────────────────────────────
  // markAllRead
  // ─────────────────────────────────────────
  group('markAllRead', () {
    test('全通知が isRead = true になる', () async {
      await inbox.add(title: 'a', body: 'b');
      await inbox.add(title: 'c', body: 'd');
      await inbox.markAllRead();
      final items = inbox.getAll();
      expect(items.every((i) => i.isRead), isTrue);
    });

    test('空のインボックスで呼んでもクラッシュしない', () async {
      await expectLater(inbox.markAllRead(), completes);
    });
  });

  // ─────────────────────────────────────────
  // clear
  // ─────────────────────────────────────────
  group('clear', () {
    test('clear で全通知が削除される', () async {
      await inbox.add(title: 'x', body: 'y');
      await inbox.clear();
      expect(inbox.getAll(), isEmpty);
    });
  });

  // ─────────────────────────────────────────
  // reset (ログアウト用)
  // ─────────────────────────────────────────
  group('reset', () {
    test('reset でメモリ上のリストが空になる', () async {
      await inbox.add(title: 'a', body: 'b');
      inbox.reset();
      expect(inbox.getAll(), isEmpty);
      expect(inbox.unreadCount.value, 0);
    });
  });

  // ─────────────────────────────────────────
  // load (永続化往復)
  // ─────────────────────────────────────────
  group('load', () {
    test('add → load で通知が復元される', () async {
      await inbox.add(title: '保存テスト', body: 'body');
      // メモリをリセットしてから load
      inbox.reset();
      expect(inbox.getAll(), isEmpty);
      await inbox.load();
      expect(inbox.getAll().first.title, '保存テスト');
    });

    test('load 後の unreadCount が正しい', () async {
      await inbox.add(title: 'a', body: 'b');
      await inbox.add(title: 'c', body: 'd');
      await inbox.markAllRead();
      inbox.reset();
      await inbox.load();
      expect(inbox.unreadCount.value, 0);
    });

    test('空ストレージで load してもクラッシュしない', () async {
      await expectLater(inbox.load(), completes);
      expect(inbox.getAll(), isEmpty);
    });
  });

  // ─────────────────────────────────────────
  // 上限 (50件)
  // ─────────────────────────────────────────
  group('上限', () {
    test('50件を超えると古いものが削除される', () async {
      for (var i = 0; i < 55; i++) {
        await inbox.add(title: 'n$i', body: 'b');
      }
      expect(inbox.getAll().length, 50);
      // 最新の n54 が先頭にある
      expect(inbox.getAll().first.title, 'n54');
    });
  });

  // ─────────────────────────────────────────
  // getAll は immutable コピーを返す
  // ─────────────────────────────────────────
  group('getAll', () {
    test('getAll の戻り値を変更しても内部リストに影響しない', () async {
      await inbox.add(title: 'orig', body: 'b');
      final list = inbox.getAll();
      expect(() => (list as dynamic).add(null), throwsA(anything));
    });
  });

  // ─────────────────────────────────────────
  // NotificationItem JSON
  // ─────────────────────────────────────────
  group('NotificationItem', () {
    test('toJson / fromJson ラウンドトリップ', () {
      final now = DateTime(2026, 4, 24, 10, 0);
      final item = NotificationItem(
        title: 'タイトル',
        body: '本文',
        route: '/detail',
        receivedAt: now,
        isRead: true,
      );
      final json = item.toJson();
      final restored = NotificationItem.fromJson(json);
      expect(restored.title, item.title);
      expect(restored.body, item.body);
      expect(restored.route, item.route);
      expect(restored.receivedAt, item.receivedAt);
      expect(restored.isRead, item.isRead);
    });

    test('route が null でも fromJson できる', () {
      final item = NotificationItem.fromJson({
        'title': 'a',
        'body': 'b',
        'route': null,
        'receivedAt': '2026-04-01T00:00:00.000',
        'isRead': false,
      });
      expect(item.route, isNull);
    });

    test('isRead がない JSON は false になる', () {
      final item = NotificationItem.fromJson({
        'title': 'a',
        'body': 'b',
        'receivedAt': '2026-04-01T00:00:00.000',
      });
      expect(item.isRead, isFalse);
    });
  });
}

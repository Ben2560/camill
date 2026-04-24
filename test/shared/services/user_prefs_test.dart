import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camill/shared/services/user_prefs.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserPrefs.uidGetter = null; // リセット
  });

  tearDown(() {
    UserPrefs.uidGetter = null;
  });

  // ─────────────────────────────────────────
  // prefixed
  // ─────────────────────────────────────────
  group('prefixed', () {
    test('UID なし: キーをそのまま返す', () {
      UserPrefs.uidGetter = () => null;
      expect(UserPrefs.prefixed('my_key'), 'my_key');
    });

    test('UID あり: uid_UID_KEY 形式を返す', () {
      UserPrefs.uidGetter = () => 'user123';
      expect(UserPrefs.prefixed('my_key'), 'uid_user123_my_key');
    });
  });

  // ─────────────────────────────────────────
  // int
  // ─────────────────────────────────────────
  group('int', () {
    test('setInt → getInt で値が取れる', () async {
      UserPrefs.uidGetter = () => 'u1';
      final p = await SharedPreferences.getInstance();
      await UserPrefs.setInt(p, 'budget', 50000);
      expect(await UserPrefs.getInt(p, 'budget'), 50000);
    });

    test('キーが存在しない場合 null を返す', () async {
      UserPrefs.uidGetter = () => 'u1';
      final p = await SharedPreferences.getInstance();
      expect(await UserPrefs.getInt(p, 'nonexistent'), isNull);
    });

    test('旧キー → UID キーへマイグレーション', () async {
      UserPrefs.uidGetter = () => 'u1';
      final p = await SharedPreferences.getInstance();
      // 旧キーをセット
      await p.setInt('budget', 30000);

      final v = await UserPrefs.getInt(p, 'budget');
      expect(v, 30000);
      // 旧キーは削除され、UID キーに移行されている
      expect(p.containsKey('budget'), isFalse);
      expect(p.containsKey('uid_u1_budget'), isTrue);
    });
  });

  // ─────────────────────────────────────────
  // String
  // ─────────────────────────────────────────
  group('String', () {
    test('setString → getString で値が取れる', () async {
      UserPrefs.uidGetter = () => 'u1';
      final p = await SharedPreferences.getInstance();
      await UserPrefs.setString(p, 'name', 'テスト');
      expect(await UserPrefs.getString(p, 'name'), 'テスト');
    });

    test('キーが存在しない場合 null を返す', () async {
      UserPrefs.uidGetter = () => 'u1';
      final p = await SharedPreferences.getInstance();
      expect(await UserPrefs.getString(p, 'missing'), isNull);
    });

    test('旧キー → UID キーへマイグレーション', () async {
      UserPrefs.uidGetter = () => 'u1';
      final p = await SharedPreferences.getInstance();
      await p.setString('theme', 'dark');

      final v = await UserPrefs.getString(p, 'theme');
      expect(v, 'dark');
      expect(p.containsKey('theme'), isFalse);
      expect(p.containsKey('uid_u1_theme'), isTrue);
    });
  });

  // ─────────────────────────────────────────
  // bool
  // ─────────────────────────────────────────
  group('bool', () {
    test('setBool → getBool で値が取れる', () async {
      UserPrefs.uidGetter = () => 'u1';
      final p = await SharedPreferences.getInstance();
      await UserPrefs.setBool(p, 'notif', true);
      expect(await UserPrefs.getBool(p, 'notif'), isTrue);
    });

    test('キーが存在しない場合 null を返す', () async {
      UserPrefs.uidGetter = () => 'u1';
      final p = await SharedPreferences.getInstance();
      expect(await UserPrefs.getBool(p, 'missing'), isNull);
    });

    test('旧キー → UID キーへマイグレーション', () async {
      UserPrefs.uidGetter = () => 'u1';
      final p = await SharedPreferences.getInstance();
      await p.setBool('is_overseas', false);

      final v = await UserPrefs.getBool(p, 'is_overseas');
      expect(v, false);
      expect(p.containsKey('is_overseas'), isFalse);
      expect(p.containsKey('uid_u1_is_overseas'), isTrue);
    });
  });

  // ─────────────────────────────────────────
  // List<String>
  // ─────────────────────────────────────────
  group('StringList', () {
    test('setStringList → getStringList で値が取れる', () async {
      UserPrefs.uidGetter = () => 'u1';
      final p = await SharedPreferences.getInstance();
      await UserPrefs.setStringList(p, 'tags', ['a', 'b', 'c']);
      expect(await UserPrefs.getStringList(p, 'tags'), ['a', 'b', 'c']);
    });

    test('キーが存在しない場合 null を返す', () async {
      UserPrefs.uidGetter = () => 'u1';
      final p = await SharedPreferences.getInstance();
      expect(await UserPrefs.getStringList(p, 'missing'), isNull);
    });

    test('旧キー → UID キーへマイグレーション', () async {
      UserPrefs.uidGetter = () => 'u1';
      final p = await SharedPreferences.getInstance();
      await p.setStringList('items', ['x', 'y']);

      final v = await UserPrefs.getStringList(p, 'items');
      expect(v, ['x', 'y']);
      expect(p.containsKey('items'), isFalse);
      expect(p.containsKey('uid_u1_items'), isTrue);
    });
  });

  // ─────────────────────────────────────────
  // remove
  // ─────────────────────────────────────────
  group('remove', () {
    test('UID キーと旧キーの両方を削除する', () async {
      UserPrefs.uidGetter = () => 'u1';
      final p = await SharedPreferences.getInstance();
      await p.setString('uid_u1_foo', 'new');
      await p.setString('foo', 'old');

      await UserPrefs.remove(p, 'foo');
      expect(p.containsKey('uid_u1_foo'), isFalse);
      expect(p.containsKey('foo'), isFalse);
    });

    test('存在しないキーの remove はエラーを起こさない', () async {
      UserPrefs.uidGetter = () => 'u1';
      final p = await SharedPreferences.getInstance();
      await expectLater(UserPrefs.remove(p, 'nonexistent'), completes);
    });
  });

  // ─────────────────────────────────────────
  // UID なし (未ログイン) パス
  // ─────────────────────────────────────────
  group('UID なし', () {
    test('setInt → getInt が旧キー形式で機能する', () async {
      UserPrefs.uidGetter = () => null;
      final p = await SharedPreferences.getInstance();
      await UserPrefs.setInt(p, 'val', 99);
      expect(await UserPrefs.getInt(p, 'val'), 99);
      // UID なしのため raw キーに保存されている
      expect(p.containsKey('val'), isTrue);
    });
  });
}

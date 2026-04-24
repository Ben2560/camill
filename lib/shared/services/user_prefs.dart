import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase UID をプレフィックスとして SharedPreferences のキーを
/// ユーザーごとに分離するユーティリティ。
///
/// 旧キー（UID なし）が存在する場合は自動マイグレーションし、旧キーを削除する。
/// UID が取得できない場合（未ログイン等）は旧キーをそのまま使用する。
class UserPrefs {
  UserPrefs._();

  /// テスト用: UID 取得ロジックをオーバーライドする。
  /// null にセットすると Firebase デフォルトに戻る。
  @visibleForTesting
  static String? Function()? uidGetter;

  static String? get _uid {
    if (uidGetter != null) return uidGetter!();
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// 現在ログイン中のユーザーに対応するプレフィックス付きキーを返す。
  static String prefixed(String key) {
    final uid = _uid;
    return uid != null ? 'uid_${uid}_$key' : key;
  }

  // ── int ─────────────────────────────────────────────────────────────────

  static Future<int?> getInt(SharedPreferences p, String key) async {
    final uk = prefixed(key);
    if (p.containsKey(uk)) return p.getInt(uk);
    // 旧キーからマイグレーション
    if (p.containsKey(key)) {
      final v = p.getInt(key);
      if (v != null) await p.setInt(uk, v);
      await p.remove(key);
      return v;
    }
    return null;
  }

  static Future<void> setInt(SharedPreferences p, String key, int v) =>
      p.setInt(prefixed(key), v);

  // ── String ───────────────────────────────────────────────────────────────

  static Future<String?> getString(SharedPreferences p, String key) async {
    final uk = prefixed(key);
    if (p.containsKey(uk)) return p.getString(uk);
    if (p.containsKey(key)) {
      final v = p.getString(key);
      if (v != null) await p.setString(uk, v);
      await p.remove(key);
      return v;
    }
    return null;
  }

  static Future<void> setString(SharedPreferences p, String key, String v) =>
      p.setString(prefixed(key), v);

  // ── bool ─────────────────────────────────────────────────────────────────

  static Future<bool?> getBool(SharedPreferences p, String key) async {
    final uk = prefixed(key);
    if (p.containsKey(uk)) return p.getBool(uk);
    if (p.containsKey(key)) {
      final v = p.getBool(key);
      if (v != null) await p.setBool(uk, v);
      await p.remove(key);
      return v;
    }
    return null;
  }

  static Future<void> setBool(SharedPreferences p, String key, bool v) =>
      p.setBool(prefixed(key), v);

  // ── List<String> ─────────────────────────────────────────────────────────

  static Future<List<String>?> getStringList(
    SharedPreferences p,
    String key,
  ) async {
    final uk = prefixed(key);
    if (p.containsKey(uk)) return p.getStringList(uk);
    if (p.containsKey(key)) {
      final v = p.getStringList(key);
      if (v != null) await p.setStringList(uk, v);
      await p.remove(key);
      return v;
    }
    return null;
  }

  static Future<void> setStringList(
    SharedPreferences p,
    String key,
    List<String> v,
  ) => p.setStringList(prefixed(key), v);

  // ── remove ───────────────────────────────────────────────────────────────

  static Future<void> remove(SharedPreferences p, String key) async {
    await p.remove(prefixed(key));
    await p.remove(key); // 旧キーも念のため削除
  }
}

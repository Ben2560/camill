import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _summaryPrefix = 'cache_summary_';
  static const _ttlHours = 24;

  static Future<void> saveSummary(
    String yearMonth,
    Map<String, dynamic> json,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = {'data': json, 'saved_at': DateTime.now().toIso8601String()};
    await prefs.setString('$_summaryPrefix$yearMonth', jsonEncode(entry));
  }

  static Future<Map<String, dynamic>?> loadSummary(String yearMonth) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_summaryPrefix$yearMonth');
    if (raw == null) return null;
    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.parse(entry['saved_at'] as String);
      if (DateTime.now().difference(savedAt).inHours > _ttlHours) {
        await prefs.remove('$_summaryPrefix$yearMonth');
        return null;
      }
      return entry['data'] as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSummary(String yearMonth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_summaryPrefix$yearMonth');
  }
}

import 'package:flutter/material.dart';

class AppConstants {
  // FastAPI base URL (localhost for development)
  static const String apiBaseUrl = 'http://192.168.1.244:8000/v1';

  // Category labels (Japanese)
  static const Map<String, String> categoryLabels = {
    'food': '食費',
    'daily': '日用品',
    'hobby': '趣味',
    'transport': '交通費',
    'medical': '医療',
    'utility': '光熱費',
    'subscription': 'サブスク',
    'other': 'その他',
  };

  // Category colors (badge background: withAlpha(30), text/border: full color)
  static const Map<String, Color> categoryColors = {
    'food':         Color(0xFFFF8A65), // 食費   - オレンジ
    'daily':        Color(0xFF4DB6AC), // 日用品  - ティール
    'hobby':        Color(0xFF9575CD), // 趣味   - パープル
    'transport':    Color(0xFF4FC3F7), // 交通費  - ライトブルー
    'medical':      Color(0xFFE57373), // 医療   - レッド
    'utility':      Color(0xFFFFD54F), // 光熱費  - イエロー
    'subscription': Color(0xFF7986CB), // サブスク - インディゴ
    'other':        Color(0xFF90A4AE), // その他  - グレー
  };

  // Legal page URLs (update when pages are published)
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';

  // Payment method labels
  static const Map<String, String> paymentLabels = {
    'cash': '現金',
    'credit': 'クレカ',
    'ic': 'IC/電子マネー',
    'qr': 'QRコード',
    'other': 'その他',
  };
}
